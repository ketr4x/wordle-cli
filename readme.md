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
- Download the ZIP
- Extract the archive
- Install Python and pip
- `cd client`
- `python -m pip install -r requirements.txt`
- `python main.py`

#### Downloading a binary
- https://github.com/ketr4x/wordle-cli/releases/tag/Python
- Download the latest release for your platform:
  - `.exe` for Windows CLI build
- Run it

### Flutter version 
[![Flutter](https://github.com/ketr4x/wordle-cli/actions/workflows/flutter.yml/badge.svg)](https://github.com/ketr4x/wordle-cli/actions/workflows/flutter.yml)
#### App
- https://github.com/ketr4x/wordle-cli/releases/tag/Flutter
- Download the latest release for your platform: 
  - `.apk` for Android
  - `build_web_*.zip` for local browser play
  - `.exe` for the Windows GUI build
- Install it
- Set up your account and server (below)

#### Website
- Go to https://wordle.ketrax.ovh/

### Server
#### `https://wordle.ketrax.ovh/`

#### Custom installation
- Clone the repository
- Install Python and pip
- (Optional) Install the Heroku CLI if you want to host the server publicly
- Add a `.env` file in `server/` with the following contents:
  - `DATABASE_URL="sqlite:///wordle.db"`
  - `FLASK_DEBUG=True`
- `python -m pip install -r requirements.txt`
- Run locally with:
  - `heroku local --port 5006 -f Procfile.windows` or 
  - `flask --app server/app.py run`

## Configuration
### Python CLI
Open `client/config.json` or use the configuration editor
- `server_url` — server URL
- `username` — username
- `password` — password
- `language` — wordle language
- `ai_url` — AI API URL (default: `https://ai.hackclub.com/proxy/v1`)
- `ai_api_key` — API key for the AI game mode
- `ai_model` (optional) — specify an LLM, i.e. `google/gemini-2.5-flash`

### Flutter version
Click the gear icon in the app or on the website
- Username — your ranked username
- Password — your ranked password
- Server URL — server URL for ranked
- Wordle language — language of the words
- Ranked language — language of the words in ranked

### Server
- `base_elo` — ELO that the users start with (default: `1000`)
- `win_bonus` — win ELO bonus (default: `10`)
- `k_win` — win ELO multiplier (default: `48`)
- `k_loss` — loss ELO multiplier (default: `28`)
- `rate_limit_auth_per_ip` - rate at which clients can check auth (default: `20/minute`)
- `rate_limit_check_per_ip` - rate at which clients can check accounts (default: `20/minute`)
- `rate_limit_leaderboard_per_ip` - rate at which clients can refresh the leaderboard (default: `10/minute`)
- `rate_limit_stats_per_ip` - rate at which clients can refresh statistics (default: `10/minute`)
- `rate_limit_create_per_ip` - rate at which clients can create accounts (default: `10/hour`)
- `rate_limit_change_data_per_ip` - rate at which clients can change account data (default: `5/minute`)
- `rate_limit_delete_user_per_ip` - rate at which clients can delete accounts (default: `5/minute`)
- `rate_limit_start_per_ip` - rate at which clients can start new games (default: `5/minute`)
- `rate_limit_guess_per_ip` - rate at which clients can make guesses (default: `60/minute`)
- `rate_limit_word_per_ip` - rate at which clients can request the answer (default: `5/minute`)

## Planned updates
- [**Flutter**] timer fix
- [**Flutter**] add create account popup when it isn't set
- [**Flutter**] fix loading the offline languages rootBundle list (settings.dart, connectivity.dart)
- [**Flutter**] autoupdate all popups
- [**Website**] website redesign
- [**Flutter**] android: fix checking local lang from assets
- [**Flutter**] web: fix connection on debug builds
- [**Flutter**] web: fix local language download (connectivity.dart)
- [**Python**] local language download
- [**Flutter**] implement ratelimiter
- [**Python**] implement ratelimiter
- Fix release info
- Locales
- Submit package to PyPi
- Python, Windows releases
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