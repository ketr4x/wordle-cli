# Imports
import hashlib
from flask import Flask, render_template, request, send_from_directory
from flask_sqlalchemy import SQLAlchemy
import os
from dotenv import load_dotenv
from flask import jsonify
try:
    from . import utils, online
except Exception:
    import utils, online
from werkzeug.security import generate_password_hash, check_password_hash
import datetime
from sqlalchemy.ext.mutable import MutableDict
import json

# Initialization
load_dotenv()
app = Flask(__name__)
db_url = os.environ.get('DATABASE_URL')
if db_url and db_url.startswith('postgres://'):
    db_url = db_url.replace('postgres://', 'postgresql://', 1)
app.config['SQLALCHEMY_DATABASE_URI'] = db_url
db = SQLAlchemy(app)

# User DB
class User(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(80), unique=True, nullable=False)
    auth = db.Column(db.String(256), nullable=False)

# Game DB
class Game(db.Model):
    game_id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(80), nullable=False)
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
    username = db.Column(db.String(80), nullable=False)
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
def auth_check():
    user = request.args.get('user')
    auth = str(request.args.get('auth'))
    existing_user = User.query.filter_by(username=user).first()
    if existing_user:
        if check_password_hash(existing_user.auth, auth):
            return "Authenticated", 200
        else:
            return "Invalid auth", 403
    return 'Invalid details', 401

# User existence check
@app.route('/online/user_check/<username>')
def user_check(username):
    user = User.query.filter_by(username=username).first()
    if user:
        return 'User found', 200
    else:
        return 'User not found', 404

# Backend leaderboard endpoint
@app.route('/online/leaderboard')
def get_leaderboard():
    state = request.args.get('state')
    user = request.args.get('user')
    auth = str(request.args.get('auth'))

    if not state or not user or not auth:
        return 'Missing required parameters: state, user and auth', 400
    existing_user = User.query.filter_by(username=user).first()
    if not existing_user:
        return 'User not found', 401
    if not check_password_hash(existing_user.auth, auth):
        return 'Wrong auth', 403

    if state == "basic":
        top_points = Stats.query.filter(Stats.matches > 0).order_by(Stats.points.desc()).limit(10).all()
        top_matches = Stats.query.filter(Stats.matches > 0).order_by(Stats.matches.desc()).limit(10).all()
        top_avg_time = Stats.query.filter(Stats.avg_time > 0, Stats.matches > 0).order_by(Stats.avg_time.asc()).limit(10).all()
        top_winrate = Stats.query.filter(Stats.matches > 0).all()
        top_winrate = sorted(top_winrate, key=lambda s: s.wins / s.matches if s.matches > 0 else 0, reverse=True)[:10]

        user_stats = Stats.query.filter_by(username=user).first()
        points_position = Stats.query.filter(Stats.points > user_stats.points, Stats.matches > 0).count() + 1
        matches_position = Stats.query.filter(Stats.matches > user_stats.matches, Stats.matches > 0).count() + 1
        avg_time_position = Stats.query.filter(
            Stats.avg_time > 0,
            Stats.avg_time < user_stats.avg_time,
            Stats.matches > 0
        ).count() + 1 if user_stats.avg_time > 0 else None

        user_winrate = user_stats.wins / user_stats.matches if user_stats.matches > 0 else 0
        winrate_position = Stats.query.filter(Stats.matches > 0).all()
        winrate_position = sum(1 for s in winrate_position if (s.wins / s.matches) > user_winrate) + 1

        return jsonify({
            'top_points': [{'username': s.username, 'points': s.points} for s in top_points],
            'top_matches': [{'username': s.username, 'matches': s.matches} for s in top_matches],
            'top_avg_time': [{'username': s.username, 'avg_time': s.avg_time} for s in top_avg_time],
            'top_winrate': [{'username': s.username, 'winrate': s.wins / s.matches if s.matches > 0 else 0} for s in top_winrate],
            'user_position': {
                'points': points_position,
                'matches': matches_position,
                'avg_time': avg_time_position,
                'winrate': winrate_position
            }
        })

    return "Wrong state", 404

# Backend stats endpoint
@app.route('/online/stats')
def get_stats():
    user = request.args.get('user')
    auth = str(request.args.get('auth'))

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
def create_user():
    user = str(request.args.get('user'))
    auth = str(request.args.get('auth'))

    if not user or not auth:
        return "Data cannot be null", 400

    fn_create_user(user, auth)
    return "User created", 200

# User creation function
def fn_create_user(user, auth):
    user_table = User(username=user, auth=generate_password_hash(auth))
    db.session.add(user_table)
    stats = Stats(username=user, points=utils.read_config("base_elo"), matches=0, wins=0, avg_time=0, word_freq={}, registered_on=datetime.datetime.now())
    db.session.add(stats)
    db.session.commit()

@app.route('/play', defaults={'path': ''})
@app.route('/play/<path:path>')
def play(path):
    flutter_build_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'flutter', 'build', 'web'))
    if not os.path.isdir(flutter_build_dir):
        flutter_build_dir = os.path.abspath(os.path.join(str(app.static_folder), 'play'))

    requested = path or 'index.html'
    target_path = os.path.abspath(os.path.join(flutter_build_dir, requested))
    base_path = os.path.abspath(flutter_build_dir)

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
def start_online():
    user = request.args.get('user')
    auth = str(request.args.get('auth'))
    language = request.args.get('language')

    if not user or not auth:
        return 'Missing required parameters: user and auth', 400

    existing_user = User.query.filter_by(username=user).first()
    if not existing_user:
        fn_create_user(user, auth)
    elif not check_password_hash(existing_user.auth, auth):
        return 'Wrong auth', 400

    if language not in utils.languages():
        return 'Language invalid', 400

    word = online.generate_word(language)
    game = Game(username=user, word=word, language=language, time=0, status=1, guesses=[], formatted_guesses=[], guess_number=0, letters=utils.letters(language), start_time=datetime.datetime.now())
    db.session.add(game)
    db.session.commit()

    return 'Started', 200

# Take a guess endpoint
@app.route('/online/guess')
def guess_online():
    user = str(request.args.get('user'))
    auth = str(request.args.get('auth'))
    guess = str(request.args.get('guess'))

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
        stats = Stats.query.filter_by(username=user).first()
        stats.points = update_elo(stats.points, game.status == 2)
        stats.matches += 1
        if game.status == 2:
            stats.wins += 1
            prev_avg = stats.avg_time or 0.0
            prev_wins = max(stats.wins -1, 0)
            stats.avg_time = (prev_avg * prev_wins + game.time) / stats.wins

        if not isinstance(stats.word_freq, dict):
            stats.word_freq = {}
        for each_guess in game.guesses:
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
def get_word():
    user = str(request.args.get('user'))
    auth = str(request.args.get('auth'))

    if not user or not auth:
        return 'Missing required parameters: user, auth and guess', 401

    game = Game.query.filter_by(username=user).order_by(Game.game_id.desc()).first()
    existing_user = User.query.filter_by(username=user).first()
    if not existing_user:
        return 'User not found', 401
    if not check_password_hash(existing_user.auth, auth):
        return 'Wrong auth', 403

    if game.status != 1:
        return game.word
    return "Game has not ended", 403

if __name__ == '__main__':
    app.run(debug=(os.environ.get('FLASK_DEBUG', 'False').lower() == 'true'))