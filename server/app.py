# Imports
import hashlib
from flask import Flask, render_template, request, send_from_directory
from flask_sqlalchemy import SQLAlchemy
import os
from dotenv import load_dotenv
from flask import jsonify
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address
from sqlalchemy.exc import IntegrityError
try:
    from . import utils, online
except Exception:
    import utils, online
from werkzeug.security import generate_password_hash, check_password_hash
import datetime
from sqlalchemy.ext.mutable import MutableDict
import json
import logging

# Initialization
logging.basicConfig(level=logging.INFO)
load_dotenv()
app = Flask(__name__)
db_url = os.environ.get('DATABASE_URL')
if db_url and db_url.startswith('postgres://'):
    db_url = db_url.replace('postgres://', 'postgresql://', 1)
app.config['SQLALCHEMY_DATABASE_URI'] = db_url
db = SQLAlchemy(app)
limiter = Limiter(
    key_func=get_remote_address,
    app=app,
    default_limits=[],
    storage_uri=os.environ.get("RATELIMIT_STORAGE_URI", "memory://")
)

# User DB
class User(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(80), index=True, unique=True, nullable=False)
    auth = db.Column(db.String(256), nullable=False)

# Game DB
class Game(db.Model):
    game_id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(80), index=True, nullable=False)
    language = db.Column(db.String(80), nullable=False)
    start_time = db.Column(db.DateTime, nullable=False)
    word = db.Column(db.String(5), nullable=True)
    guesses = db.Column(db.JSON, nullable=True)
    formatted_guesses = db.Column(db.JSON, nullable=True)
    letters = db.Column(db.JSON, nullable=True)
    guess_number = db.Column(db.Integer, nullable=True)
    time = db.Column(db.Float, nullable=True)
    status = db.Column(db.Integer, nullable=True)

# Stats DB
class Stats(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(80), index=True, nullable=False)
    points = db.Column(db.Integer, nullable=True)
    matches = db.Column(db.Integer, nullable=True)
    wins = db.Column(db.Integer, nullable=True)
    avg_time = db.Column(db.Float, nullable=True)
    word_freq = db.Column(MutableDict.as_mutable(db.JSON), nullable=True)
    registered_on = db.Column(db.DateTime, nullable=False)

# DB Creation
with app.app_context():
    db.create_all()

# TODO: Landing page
@app.route('/')
def homepage():
    return render_template('index.html')

# Server status check
@app.route('/server_check')
def server_check():
    return "Server is running", 200

# User auth check
@app.route('/online/auth_check')
@limiter.limit(utils.read_config('rate_limit_auth_per_ip'), key_func=get_remote_address)
def auth_check():
    user = (request.args.get('user') or '').strip()
    auth = (request.args.get('auth') or '').strip()

    if not user or not auth:
        return 'Missing required parameters: user and auth', 400

    existing_user = User.query.filter_by(username=user).first()
    if existing_user:
        if check_password_hash(existing_user.auth, auth):
            return "Authenticated", 200
        else:
            return "Invalid auth", 403
    return 'Invalid details', 401

# User existence check
@app.route('/online/user_check/<username>')
@limiter.limit(utils.read_config('rate_limit_check_per_ip'), key_func=get_remote_address)
def user_check(username):
    username = (username or '').strip()
    user = User.query.filter_by(username=username).first()
    if user:
        return 'User found', 200
    else:
        return 'User not found', 404

# Backend leaderboard endpoint
@app.route('/online/leaderboard')
@limiter.limit(utils.read_config('rate_limit_leaderboard_per_ip'), key_func=get_remote_address)
def get_leaderboard():
    state = request.args.get('state')
    if not state:
        return 'Missing required parameter: state', 400

    top_points = Stats.query.filter(Stats.matches > 0).order_by(Stats.points.desc()).limit(10).all()
    top_matches = Stats.query.filter(Stats.matches > 0).order_by(Stats.matches.desc()).limit(10).all()
    top_avg_time = Stats.query.filter(Stats.avg_time > 0, Stats.matches >= 10).order_by(Stats.avg_time.asc()).limit(10).all()
    top_winrate = Stats.query.filter(Stats.matches >= 10).all()
    top_winrate = sorted(top_winrate, key=lambda s: s.wins / s.matches if s.matches >= 10 else 0, reverse=True)[:10]
    top_wins = Stats.query.filter(Stats.wins > 0).order_by(Stats.wins.desc()).limit(10).all()

    if state == "basic" or state == "user":
        user = (request.args.get('user') or '').strip()
        auth = (request.args.get('auth') or '').strip()

        if not user or not auth:
            return 'Missing required parameters: user and auth', 400

        existing_user = User.query.filter_by(username=user).first()
        if not existing_user:
            return 'User not found', 401

        if not check_password_hash(existing_user.auth, auth):
            return 'Wrong auth', 403

        user_stats = Stats.query.filter_by(username=user).first()
        points_position = None if Stats.query.filter(Stats.points > user_stats.points, Stats.matches > 0).count() == 0 else Stats.query.filter(Stats.points > user_stats.points, Stats.matches > 0).count() + 1
        matches_position = None if Stats.query.filter(Stats.matches > user_stats.matches, Stats.matches > 0).count() == 0 else Stats.query.filter(Stats.matches > user_stats.matches, Stats.matches > 0).count() + 1
        wins_position = None if Stats.query.filter(Stats.wins > user_stats.wins, Stats.wins > 0).count() == 0 else Stats.query.filter(Stats.wins > user_stats.wins, Stats.matches > 0).count() + 1
        avg_time_position = Stats.query.filter(
            Stats.avg_time > 0,
            Stats.avg_time < user_stats.avg_time,
            Stats.matches >= 10
        ).count() + 1 if user_stats.avg_time > 0 and user_stats.matches >= 10 else None

        user_winrate = user_stats.wins / user_stats.matches if user_stats.matches > 0 else 0
        winrate_position = Stats.query.filter(Stats.matches >= 10).all()
        winrate_position =  None if sum(1 for s in winrate_position if (s.wins / s.matches) > user_winrate) == 0 else sum(1 for s in winrate_position if (s.wins / s.matches) > user_winrate) + 1

        if state == "basic":
            return jsonify({
                'top_points': [{'username': s.username, 'points': s.points} for s in top_points],
                'top_matches': [{'username': s.username, 'matches': s.matches} for s in top_matches],
                'top_avg_time': [{'username': s.username, 'avg_time': s.avg_time} for s in top_avg_time],
                'top_winrate': [{'username': s.username, 'winrate': s.wins / s.matches if s.matches > 0 else 0} for s in top_winrate],
                'top_wins': [{'username': s.username, 'wins': s.wins} for s in top_wins],
                'user_position': {
                    'points': points_position,
                    'matches': matches_position,
                    'avg_time': avg_time_position,
                    'winrate': winrate_position,
                    'wins': wins_position
                }
            })
        elif state == "user":
            return jsonify({
                'user_position': {
                    'points': points_position,
                    'matches': matches_position,
                    'avg_time': avg_time_position,
                    'winrate': winrate_position,
                    'wins': wins_position
                }
            })

    elif state == 'global':
        return jsonify({
            'top_points': [{'username': s.username, 'points': s.points} for s in top_points],
            'top_matches': [{'username': s.username, 'matches': s.matches} for s in top_matches],
            'top_avg_time': [{'username': s.username, 'avg_time': s.avg_time} for s in top_avg_time],
            'top_winrate': [{'username': s.username, 'winrate': s.wins / s.matches if s.matches > 0 else 0} for s in top_winrate],
            'top_wins': [{'username': s.username, 'wins': s.wins} for s in top_wins]
        })

    return "Wrong state", 404

# Backend stats endpoint
@app.route('/online/stats')
@limiter.limit(utils.read_config('rate_limit_stats_per_ip'), key_func=get_remote_address)
def get_stats():
    user = (request.args.get('user') or '').strip()
    auth = (request.args.get('auth') or '').strip()

    if not user or not auth:
        return 'Missing required parameters: user and auth', 400

    existing_user = User.query.filter_by(username=user).first()
    if not existing_user:
        return 'User not found', 401

    if not check_password_hash(existing_user.auth, auth):
        return 'Wrong auth', 403

    stats = Stats.query.filter_by(username=user).first()
    if not stats:
        return 'Stats not found', 404

    return jsonify({
        'username': stats.username,
        'points': stats.points,
        'matches': stats.matches,
        'wins': stats.wins,
        'avg_time': stats.avg_time,
        'word_freq': stats.word_freq,
        'registered_on': stats.registered_on
    })

@app.route('/online/version')
def get_version():
    with open("data.json", "r", encoding="utf-8") as f:
        loaded = json.load(f)
    return loaded["version"]

# ELO calculation system
# You can customize it in config.json
def update_elo(current_elo, won):
    system_elo = utils.read_config("base_elo")
    win_bonus = utils.read_config("win_bonus")
    k_win = utils.read_config("k_win")
    k_loss = utils.read_config("k_loss")
    expected_score = 1 / (1 + 10 ** ((system_elo - current_elo) / 400))
    actual_score = 1 if won else 0
    k = k_win if won else k_loss
    new_elo = int(current_elo + k * (actual_score - expected_score))
    if won:
        new_elo += win_bonus
    return max(new_elo, 0)

# User creation endpoint
@app.route('/online/create_user')
@limiter.limit(utils.read_config('rate_limit_create_per_ip'), key_func=get_remote_address)
def create_user():
    user = (request.args.get('user') or '').strip()
    auth = (request.args.get('auth') or '').strip()

    if not user or not auth:
        return "Data cannot be null", 400

    user_create = fn_create_user(user, auth)
    if user_create == 1:
        return "Unallowed username", 400
    elif user_create == 2:
        return "User already exists", 400
    elif user_create == 3:
        return "User blacklisted", 403
    elif user_create == -1:
        return "Failed to create user", 500
    return "User created", 200

# User creation function
def fn_create_user(user, auth):
    try:
        with open('server/filter.json', 'r', encoding='utf-8') as f:
            filter_data = json.load(f).get('data', [])
    except (FileNotFoundError, json.JSONDecodeError):
        filter_data = []
    if user in filter_data:
        return 1

    if User.query.filter_by(username=user).first():
        return 2

    try:
        with open('server/blocklist.json', 'r', encoding='utf-8') as f:
            blocklist_data = json.load(f).get('usernames', [])
    except (FileNotFoundError, json.JSONDecodeError):
        blocklist_data = []
    if user in blocklist_data:
        return 3

    user_table = User(username=user, auth=generate_password_hash(auth))
    stats = Stats(username=user, points=utils.read_config("base_elo"), matches=0, wins=0, avg_time=0, word_freq={}, registered_on=datetime.datetime.now())
    try:
        db.session.add(user_table)
        db.session.add(stats)
        db.session.commit()
    except IntegrityError:
        db.session.rollback()
        return -1
    return 0

@app.route('/online/delete_account')
@limiter.limit(utils.read_config('rate_limit_delete_user_per_ip'), key_func=get_remote_address)
def change_data():
    user = (request.args.get('user') or '').strip()
    auth = (request.args.get('auth') or '').strip()

    if not user or not auth:
        return 'Missing required parameters: user and auth', 400

    existing_user = User.query.filter_by(username=user).first()
    if not existing_user:
        return 'User not found', 401

    if not check_password_hash(existing_user.auth, auth):
        return 'Wrong auth', 403

    db.session.begin_nested()
    try:
        User.query.filter_by(username=user).delete(synchronize_session='auto')
        Game.query.filter_by(username=user).delete(synchronize_session='auto')
        Stats.query.filter_by(username=user).delete(synchronize_session='auto')
        db.session.commit()
    except IntegrityError:
        db.session.rollback()
        return "Failed to delete the account", 400
    return "Deleted the account successfully", 200

@app.route('/online/change_data/<option>')
@limiter.limit(utils.read_config('rate_limit_change_data_per_ip'), key_func=get_remote_address)
def change_data(option):
    user = (request.args.get('user') or '').strip()
    auth = (request.args.get('auth') or '').strip()

    if not user or not auth:
        return 'Missing required parameters: user and auth', 400

    existing_user = User.query.filter_by(username=user).first()
    if not existing_user:
        return 'User not found', 401

    if not check_password_hash(existing_user.auth, auth):
        return 'Wrong auth', 403

    if option == 'user':
        new_user = (request.args.get('new_user') or '').strip()
        if not new_user:
            return 'Missing required parameters: new_user', 400

        if new_user == user:
            return 'New username cannot be the same', 400
        if User.query.filter_by(username=new_user).count() != 0:
            return 'Username already exists', 400

        try:
            with open('server/filter.json', 'r', encoding='utf-8') as f:
                filter_data = json.load(f).get('data', [])
        except (FileNotFoundError, json.JSONDecodeError):
            filter_data = []
        if new_user in filter_data:
            return "Unallowed username", 400

        try:
            with open('server/blocklist.json', 'r', encoding='utf-8') as f:
                blocklist_data = json.load(f).get('usernames', [])
        except (FileNotFoundError, json.JSONDecodeError):
            blocklist_data = []
        if new_user in blocklist_data:
            return "User blacklisted", 403

        db.session.begin_nested()
        try:
            Game.query.filter_by(username=user).update({'username': new_user}, synchronize_session='auto')
            Stats.query.filter_by(username=user).update({'username': new_user}, synchronize_session='auto')
            existing_user.username = new_user
            db.session.commit()
        except IntegrityError:
            db.session.rollback()
            return "Failed to change the username", 400
        return "Changed the username successfully", 200

    if option == 'auth':
        new_auth = (request.args.get('new_auth') or '').strip()
        if not new_auth:
            return "Missing required parameters: new_auth", 400

        if new_auth == auth:
            return "New password cannot be the same", 400

        try:
            existing_user.auth = generate_password_hash(new_auth)
            db.session.commit()
        except IntegrityError:
            db.session.rollback()
            return "Failed to change the password", 400
        return "Changed the password successfully", 200

    return "Invalid option", 404

@app.route('/play', defaults={'path': ''})
@app.route('/play/<path:path>')
def play(path):
    flutter_build_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'flutter', 'build', 'web'))
    if not os.path.isdir(flutter_build_dir):
        flutter_build_dir = os.path.abspath(os.path.join(str(app.static_folder), 'play'))

    requested = path or 'index.html'
    target_path = os.path.realpath(os.path.join(flutter_build_dir, requested))
    base_path = os.path.realpath(flutter_build_dir)

    if not (target_path == base_path or target_path.startswith(base_path + os.sep)):
        return 'Invalid path', 400
    if os.path.exists(target_path) and os.path.isfile(target_path):
        return send_from_directory(flutter_build_dir, requested)
    return send_from_directory(flutter_build_dir, 'index.html')

# TODO: Add a working leaderboard page
@app.route('/leaderboard')
def leaderboard():
    return render_template('placeholder.html', title='Leaderboard', message='Leaderboard is coming soon!')

# Language availability check endpoint
@app.route('/online/languages')
def languages():
    return ','.join(utils.languages())

@app.route('/online/languages/checksum')
def languages_checksum():
    language = request.args.get('language')

    if not language or language not in utils.languages():
        return 'Language invalid', 400

    sha256 = hashlib.sha256()
    with open(f'data/{language}.json', "rb") as f:
        for chunk in iter(lambda: f.read(4096), b""):
            sha256.update(chunk)
    return sha256.hexdigest()

@app.route('/online/languages/download')
def languages_download():
    language = request.args.get('language')

    if not language or language not in utils.languages():
        return 'Language invalid', 400

    return open(f'data/{language}.json')

# Game start endpoint
@app.route('/online/start')
@limiter.limit(utils.read_config('rate_limit_start_per_ip'), key_func=get_remote_address)
def start_online():
    user = (request.args.get('user') or '').strip()
    auth = (request.args.get('auth') or '').strip()
    language = (request.args.get('language') or '').strip()

    if not user or not auth:
        return 'Missing required parameters: user and auth', 400

    existing_user = User.query.filter_by(username=user).first()
    if not existing_user:
        user_create = fn_create_user(user, auth)
        if user_create == 1:
            return "Unallowed username", 400
        elif user_create == 3:
            return "User blacklisted", 403
    elif not check_password_hash(existing_user.auth, auth):
        return 'Wrong auth', 400

    if not language or language not in utils.languages():
        return 'Language invalid', 400

    word = online.generate_word(language)
    game = Game(username=user, word=word, language=language, time=0, status=1, guesses=[], formatted_guesses=[], guess_number=0, letters=utils.letters(language), start_time=datetime.datetime.now())
    db.session.add(game)
    db.session.commit()

    return 'Started', 200

# Take a guess endpoint
@app.route('/online/guess')
@limiter.limit(utils.read_config('rate_limit_guess_per_ip'), key_func=get_remote_address)
def guess_online():
    user = (request.args.get('user') or '').strip()
    auth = (request.args.get('auth') or '').strip()
    guess = (request.args.get('guess') or '').strip()

    if not user or not auth or not guess:
        return 'Missing required parameters: user, auth and guess', 401

    existing_user = User.query.filter_by(username=user).first()
    if not existing_user:
        return 'User not found', 401

    if not check_password_hash(existing_user.auth, auth):
        return 'Wrong auth', 403

    game = Game.query.filter_by(username=user).order_by(Game.game_id.desc()).first()

    if not game:
        return "The game doesn't exist", 404

    if game.guess_number >= 6 or game.word in game.guesses or game.status != 1:
        return 'Game ended', 400

    if len(guess) != 5 or guess not in utils.wordlist(language=game.language):
        return "Guess invalid", 400

    game_status, letters, formatted_guess = online.check_guess(game.word, guess, game.language, game.guess_number, game.letters.copy())
    game.time = (datetime.datetime.now() - game.start_time).total_seconds()
    updated_guesses = game.guesses + [guess]
    updated_formatted_guesses = game.formatted_guesses + [formatted_guess]
    game.letters = letters
    game.guesses = updated_guesses
    game.formatted_guesses = updated_formatted_guesses
    game.status = game_status
    game.guess_number = game.guess_number + 1
    db.session.commit()

    if game.guess_number >= 6 or game.word in game.guesses or game.status != 1:
        stats = Stats.query.filter_by(username=user).with_for_update().first()
        stats.points = update_elo(stats.points, game.status == 2)
        stats.matches += 1
        if game.status == 2:
            stats.wins += 1
            prev_avg = stats.avg_time or 0.0
            prev_wins = max(stats.wins - 1, 0)
            stats.avg_time = (prev_avg * prev_wins + game.time) / stats.wins

        if not isinstance(stats.word_freq, dict):
            stats.word_freq = {}
        for each_guess in game.guesses:
            if isinstance(each_guess, str) and len(each_guess) <= 5:
                stats.word_freq[each_guess] = stats.word_freq.get(each_guess, 0) + 1
        db.session.commit()

    return jsonify({
            'game_status': game_status,
            'letters': letters,
            'guesses': updated_guesses,
            'formatted_guesses': updated_formatted_guesses,
            'guess_number': game.guess_number,
            'time': game.time,
        })

# Check what was the word after the game has ended
@app.route('/online/word')
@limiter.limit(utils.read_config('rate_limit_word_per_ip'), key_func=get_remote_address)
def get_word():
    user = (request.args.get('user') or '').strip()
    auth = (request.args.get('auth') or '').strip()

    if not user or not auth:
        return 'Missing required parameters: user, auth and guess', 401

    game = Game.query.filter_by(username=user).order_by(Game.game_id.desc()).first()
    existing_user = User.query.filter_by(username=user).first()
    if not existing_user:
        return 'User not found', 401
    if not check_password_hash(existing_user.auth, auth):
        return 'Wrong auth', 403
    if not game:
        return "Game doesn't exist", 404
    if game.status != 1:
        return game.word
    return "Game has not ended", 403

if __name__ == '__main__':
    app.run(debug=(os.environ.get('FLASK_DEBUG', 'False').lower() == 'true'))