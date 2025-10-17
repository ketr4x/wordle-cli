# Wordle CLI
## Features
- Custom solo game
- Daily game
- Online (ranked) game
- Multi-language support
- File synchronization
- Statistics
- Leaderboards
- A flutter version for all platforms

## Installation
### Python CLI
#### Cloning the repository
- Click the Code button
- Download zip
- Unpack the file
- Install python and pip
- Go to client/
- `pip -m requirements.txt`
- `python3 main.py`
### Flutter version
#### App
- Click releases
- Download the latest file for your OS
- Install it
- Set up your account and server (below)
#### Website
- Go to https://wordle.ketrax.ovh/ or https://afternoon-waters-00138-898a825f9a47.herokuapp.com/
### Server
#### `https://wordle.ketrax.ovh/` or `https://afternoon-waters-00138-898a825f9a47.herokuapp.com/`
#### Custom installation
- Clone the repository
- Install python and pip
- Install heroku cli (optional)
- `pip -m requirements.txt`
- `heroku local --port 5006 -f Procfile.windows` or `flask --app server/app.py run`
## Planned updates
- [**Flutter**] timer fix
- [**Flutter**] features ported from python (online)
- Release
## Contributing
### Language data
If you want to provide the wordlist, make a lang.json file (lang being the language code).
Template: `{"solutions": [(list the wordle answers)], "wordlist": [(list all possible words)], "letters": [(list the letters here)]}`
### Other contributions
You can make a pull request, and I will happily merge it.
## License
Copyright ketr4x, 2025. Licensed under BSD-3-Clause License.

This project was made for the [Moonshot](https://moonshot.hack.club/1016) hackathon organized by HackClub.
![Hackatime Badge](https://hackatime-badge.hackclub.com/U08RQEP53HA/wordle-cli)