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
- Select the `Python` tag
- Download the latest release for your platform
- Run it
### Flutter version 
[![Flutter](https://github.com/ketr4x/wordle-cli/actions/workflows/flutter.yml/badge.svg)](https://github.com/ketr4x/wordle-cli/actions/workflows/flutter.yml)
[![Version](https://img.shields.io/github/v/release/ketr4x/wordle-cli?label=version)](https://github.com/ketr4x/wordle-cli/releases)
#### App
- https://github.com/ketr4x/wordle-cli/releases/tag/Flutter
- Download the latest [Flutter] release for your platform: 
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
- `pip -m requirements.txt`
- `heroku local --port 5006 -f Procfile.windows` or `flask --app server/app.py run`
## Planned updates
- [**Flutter**] timer fix
- [**Flutter**] language pack download
- [**Flutter**] ai mode
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
#### This project was made for the [Moonshot](https://moonshot.hack.club/1016) hackathon organized by HackClub. ![Hackatime Badge](https://hackatime-badge.hackclub.com/U08RQEP53HA/wordle-cli)