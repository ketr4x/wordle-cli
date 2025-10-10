from randomword import *
import datetime

def get_word(language):
    random.seed(f"HackClub {datetime.date.today()}")
    solutions = utils.solutions(language)
    return random.choice(solutions)

def settings():
    utils.clear_screen()
    length = 5 # TODO int(input("How long do you want your word? ") or 5)

    language = ""
    languages = list(map(str, utils.languages()))
    while language not in languages:
        language = (input(f"What language do you want your word? ({','.join(languages)}) ") or "en").strip().lower()
    return length, language

def game_daily():
    length, language = settings()
    word = get_word(language)
    filtered = sorted(utils.wordlist(language))
    game_status, guesses = game(word, filtered, 6, language)

    utils.clear_screen()
    if game_status == 2:
        print(f"You won in {len(guesses)} guesses!")
    else:
        print(f"You lost!")
    print(f"The word was {word}")
    input("\nPress `Enter` to continue...")