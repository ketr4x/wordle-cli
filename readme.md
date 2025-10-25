# Wordle CLI
## Features
- Custom solo game
- Daily game
- Online (ranked) game
- Multi-language support
- File synchronization
- Statistics
- Leaderboards
- A Flutter version for all platforms

## Installation
### Python CLI
#### Cloning the repository
- Click the Code button
- Download zip
- Unpack the file
- Install python and pip
- `cd client`
- `pip -m requirements.txt`
- `python3 main.py`
#### Downloading a binary
- Go to releases
- Select the `python` tag
- Download the latest release for your platform
- Run it
### Flutter version [![Flutter](https://github.com/ketr4x/wordle-cli/actions/workflows/flutter.yml/badge.svg)](https://github.com/ketr4x/wordle-cli/actions/workflows/flutter.yml)
#### App
- Go to releases
- Select the `Flutter` tag
- Download the latest release for your platform
- Install it
- Set up your account and server (below)
#### Website
- Go to https://wordle.ketrax.ovh/
### Server
#### `https://wordle.ketrax.ovh/`
#### Custom installation
- Clone the repository
- Install python and pip
- Install heroku cli (optional)
- `pip -m requirements.txt`
- `heroku local --port 5006 -f Procfile.windows` or `flask --app server/app.py run`
## Planned updates
- [**Flutter**] timer fix
- [**Flutter**] language pack download
- [**Flutter**] (_online_) quick answer check
- [**Flutter**] ai mode
- [**Website**] website implementation
- Python releases
## Contributing
### Language data
If you want to provide the wordlist, make a lang.json file in data/ (lang being the language code).
Template: `{"solutions": [(list the wordle answers)], "wordlist": [(list all possible words)], "letters": [(list the letters here)]}`
### Other contributions
You can make a pull request, and I will happily merge it.
## License
Copyright ketr4x, 2025. Licensed under BSD-3-Clause License.

This project was made for the [Moonshot](https://moonshot.hack.club/1016) hackathon organized by HackClub.
![Hackatime Badge](https://hackatime-badge.hackclub.com/U08RQEP53HA/wordle-cli)