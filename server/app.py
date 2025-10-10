from flask import Flask, render_template

app = Flask(__name__)


@app.route('/')
def homepage():
    return render_template('index.html')


@app.route('/play')
def play():
    return render_template('play.html')


@app.route('/leaderboard')
def leaderboard():
    return render_template('placeholder.html', title='Leaderboard', message='Leaderboard is coming soon!')


if __name__ == '__main__':
    app.run(debug=True)