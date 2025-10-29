# Wordle CLI
[![Version](https://img.shields.io/github/v/release/ketr4x/wordle-cli?sort=semver&label=Version)](https://github.com/ketr4x/wordle-cli/releases)
[![Commits](https://img.shields.io/github/commits-since/ketr4x/wordle-cli/latest?label=Commits%20since%20release)](https://github.com/ketr4x/wordle-cli/commits/master/)
![Languages](https://img.shields.io/github/directory-file-count/ketr4x/wordle-cli/data?label=Languages)
![Hackatime Badge](https://hackatime-badge.hackclub.com/U08RQEP53HA/wordle-cli?label=Project%20time)
## Features
- Custom solo game
- Daily game
- Online (ranked) game
- Multi-language support
- File synchronization
- Statistics
- Leaderboards
- A Flutter GUI and a Python CLI
## Installation
### Python CLI
#### Cloning the repository
- Click the Code button
- Download .zip
- Unpack the file
- Install python and pip
- `cd client`
- `pip -m requirements.txt`
- `python3 main.py`
#### Downloading a binary
- https://github.com/ketr4x/wordle-cli/releases/tag/Python
- Download the latest release for your platform:
  - `.exe` for Windows GUI build
- Run it
### Flutter version 
[![Flutter](https://github.com/ketr4x/wordle-cli/actions/workflows/flutter.yml/badge.svg)](https://github.com/ketr4x/wordle-cli/actions/workflows/flutter.yml)
#### App
- https://github.com/ketr4x/wordle-cli/releases/tag/Flutter
- Download the latest release for your platform: 
  - `.apk` for Android
  - `build_web_*.zip` for local browser play
  - `.exe` for Windows GUI build
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
- Add a `.env` file in server/ with the following contents:
  - `DATABASE_URL="sqlite:///wordle.db"`
  - `FLASK_DEBUG=True`
- `pip -m requirements.txt`
- `heroku local --port 5006 -f Procfile.windows` or `flask --app server/app.py run`
## Planned updates
- [**Flutter**] timer fix
- [**Flutter**] language pack download
- [**Flutter**] (?) ai mode
- [**Website**] website redesign
- Python releases
- Icon
## Contributing
### Language data
If you want to provide the wordlist, make a lang.json file in data/ (lang being the language code).
Template: `{"solutions": [(list the wordle answers)], "wordlist": [(list all possible words)], "letters": [(list the letters here)]}`
### Other contributions
You can make a pull request, and I will happily merge it.
## License
Copyright ketr4x, 2025. Licensed under BSD-3-Clause License.


[![This project is part of Moonshot, a 4-day hackathon in Florida visiting Kennedy Space Center and Universal Studios\!](https://hc-cdn.hel1.your-objectstorage.com/s/v3/35ad2be8c916670f3e1ac63c1df04d76a4b337d1_moonshot.png)](https://moonshot.hack.club/1016)
#### This project was made for the [Moonshot](https://moonshot.hack.club/1016) hackathon organized by [HackClub](https://hackclub.com).