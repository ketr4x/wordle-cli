from randomword import *
import datetime

# Generates a random word from solutions based on a seed
def get_word(language):
    random.seed(f"HackClub {datetime.date.today()}")
    solutions = utils.solutions(language)
    return random.choice(solutions)

def settings():
    utils.clear_screen()
    length = 5
    language = ""
    languages = list(map(str, utils.languages()))
    while language not in languages:
        language = (input(f"What language do you want your word? ({','.join(languages)}) ") or "en").strip().lower()
    return length, language

def game_daily():
    length, language = settings()
    word = get_word(language)
    filtered = utils.filtered(language)
    game_status, guesses, formatted_guesses, letters = game(word, 6, language)

    utils.clear_screen()
    if game_status == 2:
        print(f"You won in {len(guesses)} guesses!")
    else:
        print(f"You lost!")
    print(f"Your guesses were:")
    for i in formatted_guesses:
        print(i)
    print(f"The word was {word}")
    print(f"You had {len(letters)} letters remaining")
    input("\nPress `Enter` to continue...")