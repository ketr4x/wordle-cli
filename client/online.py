import utils
import requests
import time
from statistics import stats
from configuration import configuration
from leaderboard import leaderboard
from account import account

def connection():
    server_url = utils.read_config('server_url')
    if not server_url:
        if server_check() != 1:
            return
        server_url = utils.read_config('server_url')
    user, auth = auth_check()
    create_user(user, auth, server_url)
    while True:
        server_status = requests.get(f"{server_url}/server_check")
        account_status = requests.get(f"{server_url}/online/auth_check?user={utils.read_config('username')}&auth={utils.read_config('password')}")
        available_languages = requests.get(f"{server_url}/online/languages")

        language_status = {}

        if available_languages.status_code == 200:
            languages = available_languages.text.split()
            for language in languages:
                language_status[language] = utils.language_check(language)
            for language, status in language_status.items():
                if status == "Local language file invalid":
                    language_status[language] = utils.language_download(language)

        utils.clear_screen()
        print("Connection status:")
        print(f"{"Active" if server_status.status_code == 200 else "Inactive. Check your configuration and connection"}")
        print("Account status:")
        print(f"{"Online" if account_status.status_code == 200 else "Invalid password" if account_status.status_code == 403 else "Invalid username" if account_status.status_code == 401 else "Server offline"}")
        print("Language status:")
        for language, status in language_status.items():
            print(f"{language} - {status}")

        choice = input("Press `Enter` to refresh, A for creating the account, C for changing the details or Q to quit: ").lower()
        if choice == "q":
            return
        if choice == "c":
            if account_status.status_code == 200:
                account()
            else:
                configuration()
        if choice == "a":
            user, auth = auth_check()
            create_user(user, auth, server_url)

# Translates the data received from the server for strings with the formatted guesses
def guess_decoder(guesses, formatted_guesses):
    output = []
    for j, guess in enumerate(guesses):
        guess_output = []
        for i, char in enumerate(guess):
            if formatted_guesses[j][i] == 2:
                guess_output.append(f"\033[92m{char}\033[0m")
            elif formatted_guesses[j][i] == 1:
                guess_output.append(f"\033[93m{char}\033[0m")
            else:
                guess_output.append(f"\033[91m{char}\033[0m")
        output.append("".join(guess_output))
    return output

def game(user, auth, language):
    response = requests.get(f"{utils.read_config('server_url')}/online/start?user={user}&auth={auth}&language={language}")
    if response.status_code != 200:
        print("Invalid details. Please try again in a minute.")
        if response.status_code == 400:
            print("Unallowed username")
        if response.status_code == 403:
            print("User blacklisted")
        input("Press `Enter` to continue...")
        return None, None, None, None, 1

    utils.clear_screen()
    print("Starting the game!")
    time.sleep(1)
    utils.clear_screen()

    game_time = 0
    guess_number = 0
    decoded_guesses = []
    formatted_guesses = []
    letters = utils.letters(language, True)
    game_status = 1

    while game_status == 1:
        utils.clear_screen()
        if decoded_guesses:
            print("Current guesses:")
            for i in decoded_guesses:
                print(i)
            print()
    
        print(f"Remaining guesses: {6-guess_number}")
        print(f"Unused letters: {utils.format_unused_letters(letters)}")

        guess = input(f"\nWrite your {utils.ordinal(guess_number+1)} guess: ").lower()
        if len(guess) == 5 and guess in utils.wordlist(language, True):
            response = requests.get(f"{utils.read_config('server_url')}/online/guess?user={user}&auth={auth}&guess={guess}")
            if response.status_code == 200:
                decoded = utils.json_decode(response.text)
                letters = decoded["letters"]
                guesses = decoded["guesses"]
                formatted_guesses = decoded["formatted_guesses"]
                guess_number = decoded["guess_number"]
                decoded_guesses = guess_decoder(guesses, formatted_guesses)
                game_time = decoded["time"]
                game_status = decoded["game_status"]
            else:
                print(f"Error: {response.text}")
                time.sleep(1)
                if guess_number >= 6:
                    game_status = 0

    return letters, formatted_guesses, guess_number, decoded_guesses, game_status, game_time

def create_user(user, auth, server):
    response = requests.get(f"{server}/online/auth_check?user={user}&auth={auth}")
    while response.status_code != 200:
        utils.clear_screen()
        if response.status_code == 401:
            inp = input("Account does not exist. Do you want to create one? (Y/N): ").strip().lower()
            if inp == "y":
                create = requests.get(f"{server}/online/create_user?user={user}&auth={auth}")
                if create.status_code == 200:
                    print("User created successfully!")
                if create.status_code == 400:
                    print("Invalid username. Try another one.")
                if create.status_code == 403:
                    print("Username blacklisted.")
                input("Press `Enter` to continue...")
            else:
                return None
        elif response.status_code == 403:
            print("Wrong username or password. \nPlease try again.")
            user, auth = None, None
            while not user or not auth:
                while not user:
                    user = input("Please enter your username: ")
                    if not user:
                        print("Please specify your username")
                while not auth:
                    auth = input("Please enter your password: ")
                    if not auth:
                        print("Please specify your password")
            print("Checking details...")
        else:
            print("An error has occurred. Please try again in a few minutes.")
            input("Press `Enter` to continue...")
            return 1
        response = requests.get(f"{server}/online/auth_check?user={user}&auth={auth}")

    utils.write_config("username", user)
    utils.write_config("password", auth)
    return response

def auth_check():
    user = utils.read_config("username")
    auth = utils.read_config("password")

    while not user or not auth:
        while not user:
            user = input("Please enter your username: ")
            if not user:
                print("Please specify your username")
        while not auth:
            auth = input("Please enter your password: ")
            if not auth:
                print("Please specify your password")
    return user, auth

def version_check():
    server = utils.read_config("server_url")
    server_version = requests.get(f"{server}/online/version").text
    loaded = utils.json_decode(open("../data.json", "r", encoding="utf-8").read())
    if server_version != loaded["version"]:
        print("Version mismatch. Update your client or notify the server owner.")
        input("Press `Enter` to continue...")
        return "mismatch"
    return None

def server_check():
    server = ""
    while not server:
        server = input("Please enter your full server address (i.e., https://wordle.ketrax.ovh): ").strip()
        try:
            if server and not server.startswith(('http://', 'https://')):
                if requests.get(f"https://{server}/server_check").status_code == 200:
                    server = 'https://' + server
                else:
                    server = 'http://' + server
        except requests.exceptions.RequestException:
            server = None

        try:
            response = requests.get(f"{server}/server_check", timeout=5)
            if response.text != "Server is running":
                print(f"Server did not respond correctly. Please try again.")
                server = None
        except (requests.exceptions.ConnectionError,
                requests.exceptions.MissingSchema,
                requests.exceptions.Timeout,
                requests.exceptions.RequestException) as e:
            print(f"Could not connect to server: {e}")
            server = None

        if server:
            utils.write_config("server_url", server)

    try:
        response = requests.get(f"{server}/server_check", timeout=5)
        if response.text != "Server is running":
            print(f"The server ({server}) is not running. Please try again in a few minutes or change the address in configuration")
            input("Press `Enter` to continue...")
            return None
    except requests.exceptions.RequestException as e:
        print(f"Cannot connect to server ({server}): {e}")
        input("Press `Enter` to continue...")
        return None
    return 1

def game_online():
    server = utils.read_config("server_url")

    utils.clear_screen()
    print("Welcome to ranked!\n")

    if server_check() != 1:
        return None

    if version_check() == "mismatch":
        return None

    user, auth = auth_check()
    print("Checking details...")

    response = create_user(user, auth, server)

    language = utils.read_config("language")
    languages_response = requests.get(f"{server}/online/languages")
    languages = [lang.strip() for lang in languages_response.text.strip().split(',')] if languages_response.status_code == 200 else []
    while language not in languages:
        language = input(f"Choose the language ({','.join(languages)}): ").strip().lower()
    utils.write_config("language", language)

    if languages_response.status_code == 200:
        language_status = utils.language_check(language)
        if language_status == "Local language file invalid":
            language_status = utils.language_download(language)
        if language_status != "Local language file correct":
            connection()
            return None

    while True:
        statistics = requests.get(f"{utils.read_config('server_url')}/online/stats?user={user}&auth={auth}")
        if response.status_code != 200:
            elo = None
            print("Cannot get statistics")
        else:
            elo = statistics.json()["points"]

        utils.clear_screen()
        print(f"Welcome to ranked, {user}!\n")
        print(f"Your ELO is {elo}\n")
        print("P. Play\nL. Leaderboard\nS. Statistics\nC. Configuration\nX. Connection\nQ. Quit to lobby")
        option = input("\nChoose the option you want...: ").upper()
        if option == 'P':
            result = game(user, auth, language)
            if result[0] is not None:
                letters, formatted_guesses, guess_number, decoded_guesses, game_status, game_time = result
                utils.clear_screen()
                if game_status == 2:
                    print(f"Congratulations, {user}! You won in {guess_number} guesses!")
                else:
                    print("You lost! Better luck next time!")
                print(f"Your time was {game_time} seconds")
                print(f"Your guesses were:")
                for i in decoded_guesses:
                    print(i)
                print(f"The word was: {requests.get(f"{server}/online/word?user={user}&auth={auth}").text}")
                print(f"You had {len(letters)} letters remaining")
                input("Press `Enter` to continue...")
        elif option == 'L':
            leaderboard()
        elif option == 'S':
            stats()
        elif option == 'C':
            configuration()
            break
        elif option == 'X':
            connection()
        elif option == 'Q':
            break