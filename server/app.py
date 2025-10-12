from flask import Flask, render_template, request
from flask_sqlalchemy import SQLAlchemy
import os
from dotenv import load_dotenv
from flask import jsonify
import utils
from online import generate_word, check_guess
from werkzeug.security import generate_password_hash, check_password_hash

load_dotenv()
app = Flask(__name__)
app.config['SQLALCHEMY_DATABASE_URI'] = os.environ.get('DATABASE_URL')
db = SQLAlchemy(app)

class User(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(80), unique=True, nullable=False)
    auth = db.Column(db.String(80), nullable=False)

class Game(db.Model):
    game_id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(80), nullable=False)
    language = db.Column(db.String(80), nullable=False)
    word = db.Column(db.String(5), nullable=True)
    guesses = db.Column(db.JSON, nullable=True)
    formatted_guesses = db.Column(db.JSON, nullable=True)
    letters = db.Column(db.JSON, nullable=True)
    guess_number = db.Column(db.Integer, nullable=True)
    status = db.Column(db.Integer, nullable=True)

with app.app_context():
    db.create_all()


@app.route('/')
def homepage():
    return render_template('index.html')

@app.route('/server_check')
def server_check():
    return "Server is running", 200

@app.route('/online/auth_check')
def auth_check():
    user = request.args.get('user')
    auth = request.args.get('auth')
    existing_user = User.query.filter_by(username=user).first()
    if existing_user:
        if check_password_hash(existing_user.auth, auth):
            return "Authenticated", 200
        else:
            return "Invalid auth", 403
    return 'Invalid details', 401

@app.route('/online/user_check/<username>')
def user_check(username):
    user = User.query.filter_by(username=username).first()
    if user:
        return 'User found', 200
    else:
        return 'User not found', 404

@app.route('/online/create_user')
def create_user():
    user = request.args.get('user')
    auth = request.args.get('auth')

    if not user or not auth:
        return "Data cannot be null", 400

    user = User(username=user, auth=generate_password_hash(auth))
    db.session.add(user)
    db.session.commit()
    return "User created", 200

def fn_create_user(user, auth):
    user_table = User(username=user, auth=generate_password_hash(auth))
    db.session.add(user_table)
    db.session.commit()

@app.route('/play')
def play():
    return render_template('play.html')


@app.route('/online/leaderboard')
def leaderboard():
    return render_template('placeholder.html', title='Leaderboard', message='Leaderboard is coming soon!')

@app.route('/online/languages')
def languages():
    return ','.join(utils.languages())

@app.route('/online/start')
def start_online():
    user = request.args.get('user')
    auth = request.args.get('auth')
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

    word = generate_word(language)
    game = Game(username=user, word=word, language=language, status=1, guesses=[], formatted_guesses=[], guess_number=0, letters=utils.letters(language))
    db.session.add(game)
    db.session.commit()

    return 'Started', 200

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

    if game.guess_number >= 6:
        return 'Game ended', 400

    if len(guess) != 5 or guess not in utils.wordlist(language=game.language):
        return "Guess invalid", 400

    game_status, letters, formatted_guess = check_guess(game.word, guess, game.language, game.guess_number, game.letters.copy())

    updated_guesses = game.guesses + [guess]
    updated_formatted_guesses = game.formatted_guesses + [formatted_guess]
    game.letters = letters
    game.guesses = updated_guesses
    game.formatted_guesses = updated_formatted_guesses
    game.status = game_status
    game.guess_number = game.guess_number + 1
    db.session.commit()

    return jsonify({
        'game_status': game_status,
        'letters': letters,
        'guesses': updated_guesses,
        'formatted_guesses': updated_formatted_guesses,
        'guess_number': game.guess_number
    })

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