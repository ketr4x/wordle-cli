import utils
import requests
import time

def guess_decoder(guesses, formatted_guesses):
    output = []
    for j, guess in enumerate(guesses):
        enum_formatted_guesses = enumerate(formatted_guesses[j])
        for i, char in enumerate(guess[j]):
            if enum_formatted_guesses[i] == 2:
                output[j].append(f"\033[92m{char}\033[0m")
            elif enum_formatted_guesses[i] == 1:
                output[j].append(f"\033[93m{char}\033[0m")
            else:
                output[j].append(f"\033[91m{char}\033[0m")
    return "".join(output)

def format_unused_letters(letters):
    formatted_letters = ""
    for letter in sorted(letters):
        formatted_letters += letter
    return formatted_letters


def game(user, auth, language): #formatted_guesses, game_status, guess_number, guesses, letters
    response = requests.get(f"{utils.read_config("server_url")}/online/start?user={user}&auth={auth}&language={language}")
    if response.status_code != 200:
        print("Invalid details. Please try again in a minute.")
        input("Press `Enter` to continue...")
        return 1

    utils.clear_screen()
    print("Starting the game!")
    time.sleep(1)
    utils.clear_screen()

    guess_number = 0
    formatted_guesses = []
    letters = utils.letters(language)
    guesses = []
    game_status = 1
    
    while game_status ==1:
        utils.clear_screen()
        if formatted_guesses:
            print("Current guesses:")
            for i in formatted_guesses:
                print(i)
            
        print(f"\n Remaining guesses: {6-guess_number}")
        print(f"Unused letters: {format_unused_letters(letters)}")
        
        guess = input(f"\nWrite your {utils.ordinal(guess_number+1)} guess: ").lower()
        if len(guess) == 5 and guess in utils.filtered(language):
            response = requests.get(f"{utils.read_config("server_url")}/online/guess?user={user}&auth={auth}&guess={guess}")
            decoded = utils.json_decode(response)
            game_status = decoded["game_status"]
            letters = decoded["letters"]
            guesses = decoded["guesses"]
            formatted_guesses = decoded["formatted_guesses"]
            guess_number = decoded["guess_number"]



def game_online():
    user = utils.read_config("username")
    auth = utils.read_config("password")

    utils.clear_screen()
    print("Welcome to ranked!\n")
    if not user or not auth:
        user = input("Please enter your username: ")
        auth = input("Please enter your password: ")
    print("Checking details...")

    response = requests.get(f"{utils.read_config("server_url")}/online/auth_check?user={user}&auth={auth}")
    while response.status_code != 200:
        utils.clear_screen()
        print("Wrong username or password. \nPlease try again.")
        user = input("Please enter your username: ")
        auth = input("Please enter your password: ")
        print("Checking details...")
        response = requests.get(f"{utils.read_config("server_url")}/online/auth_check?user={user}&auth={auth}")


    language = utils.read_config("language")
    languages = list(str(requests.get(f"{utils.read_config("server_url")}/online/languages")))
    while language not in languages:
        language = (input(f"Choose the language ({','.join(languages)}): ")).strip().lower()

    while True:
        utils.clear_screen()
        print(f"Welcome to ranked, {user}!\n")
        print(f"Your ELO is {None}\n") # TODO: add elo system
        print("P. Play \nL. Leaderboard \nS. Statistics \nC. Configuration \nQ. Quit to lobby")
        option = input("\nChoose the option you want...: ").upper()
        if option == 'P':
            game(user, auth, language)
        elif option == 'L':
            print("Not implemented yet")
        elif option == 'S':
            print("Not implemented yet")
        elif option == 'C':
            print("Not implemented yet")
        elif option == 'Q':
            exit()