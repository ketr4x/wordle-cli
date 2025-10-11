from flask import Flask, render_template, request
from flask_sqlalchemy import SQLAlchemy
import os
from dotenv import load_dotenv
from online import generate_word

load_dotenv()
app = Flask(__name__)
app.config['SQLALCHEMY_DATABASE_URI'] = os.environ.get('DATABASE_URL')
db = SQLAlchemy(app)


class User(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(80), unique=True, nullable=False)
    auth = db.Column(db.String(80), unique=True, nullable=False)

class Game(db.Model):
    game_id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(80), unique=True, nullable=False)
    currentWord = db.Column(db.String(5), nullable=False)
    guesses = db.Column(db.JSON, nullable=False)

with app.app_context():
    db.create_all()


@app.route('/')
def homepage():
    return render_template('index.html')


@app.route('/user_check/<username>')
def user_check(username):
    user = User.query.filter_by(username=username).first()
    if user:
        return 'User found', 200
    else:
        return 'User not found', 404


def create_user(username, auth):
    user = User(username=username, auth=auth)
    db.session.add(user)
    db.session.commit()
    return user


@app.route('/add_user', methods=['POST'])
def add_user():
    username = request.form['username']
    auth = request.form['auth']
    create_user(username, auth)
    return 'User added'


@app.route('/play')
def play():
    return render_template('play.html')


@app.route('/leaderboard')
def leaderboard():
    return render_template('placeholder.html', title='Leaderboard', message='Leaderboard is coming soon!')


@app.route('/online/start')
def start_online():
    language = request.args.get('language')
    user = request.args.get('user')
    auth = request.args.get('auth')

    if not user or not auth:
        return 'Missing required parameters: user and auth', 400

    existing_user = User.query.filter_by(username=user).first()
    if not existing_user:
        create_user(user, auth)

    if auth != existing_user.auth:
        return 'Wrong auth', 400

    word = generate_word(language)


    return 'Started', 200


if __name__ == '__main__':
    app.run(debug=(os.environ.get('FLASK_DEBUG', 'False').lower() == 'true'))