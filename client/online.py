import utils
import requests
import time
from statistics import stats
from configuration import configuration

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

def format_unused_letters(letters):
    formatted_letters = ""
    for letter in sorted(letters):
        formatted_letters += letter
    return formatted_letters


def game(user, auth, language): #formatted_guesses, game_status, guess_number, guesses
    response = requests.get(f"{utils.read_config('server_url')}/online/start?user={user}&auth={auth}&language={language}")
    if response.status_code != 200:
        print("Invalid details. Please try again in a minute.")
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
    letters = utils.letters(language)
    guesses = []
    game_status = 1

    while game_status == 1:
        utils.clear_screen()
        if decoded_guesses:
            print("Current guesses:")
            for i in decoded_guesses:
                print(i)
            print()
    
        print(f"Remaining guesses: {6-guess_number}")
        print(f"Unused letters: {format_unused_letters(letters)}")

        guess = input(f"\nWrite your {utils.ordinal(guess_number+1)} guess: ").lower()
        if len(guess) == 5 and guess in utils.filtered(language):
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

def game_online():
    user = utils.read_config("username")
    auth = utils.read_config("password")
    server = utils.read_config("server_url")

    utils.clear_screen()
    print("Welcome to ranked!\n")

    while not server:
        server = input("Please enter your full server address (i.e., http://ketrax.ovh/dev/wordle): ").strip()

        if server and not server.startswith(('http://', 'https://')):
            server = 'http://' + server

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

    while not user or not auth:
        user = input("Please enter your username: ")
        if not user:
            print("Please specify your username")
        auth = input("Please enter your password: ")
        if not auth:
            print("Please specify your password")
    print("Checking details...")

    response = requests.get(f"{server}/online/auth_check?user={user}&auth={auth}")
    while response.status_code != 200:
        utils.clear_screen()
        if response.status_code == 401:
            inp = input("Account does not exist. Do you want to create one? (Y/N): ").strip().lower()
            if inp == "y":
                create = requests.get(f"{server}/online/create_user?user={user}&auth={auth}")
                if create.status_code == 200:
                    print("User created successfully!")
        elif response.status_code == 403:
            print("Wrong username or password. \nPlease try again.")
            user, auth = None, None
            while not user or not auth:
                user = input("Please enter your username: ")
                if not user:
                    print("Please specify your username")
                auth = input("Please enter your password: ")
                if not auth:
                    print("Please specify your password")
            print("Checking details...")
        else:
            print("An error occured. Please try again in a few minutes.")
            input("Press `Enter` to continue...")
            return 1
        response = requests.get(f"{server}/online/auth_check?user={user}&auth={auth}")

    utils.write_config("username", user)
    utils.write_config("password", auth)

    language = utils.read_config("language")
    languages_response = requests.get(f"{server}/online/languages")
    languages = [lang.strip() for lang in languages_response.text.strip().split(',')] if languages_response.status_code == 200 else []
    while language not in languages:
        language = input(f"Choose the language ({','.join(languages)}): ").strip().lower()
    utils.write_config("language", language)

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
        print("P. Play \nL. Leaderboard \nS. Statistics \nC. Configuration \nQ. Quit to lobby")
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
            print("Not implemented yet")
            input("Press `Enter` to continue...")
        elif option == 'S':
            stats()
        elif option == 'C':
            configuration()
        elif option == 'Q':
            break