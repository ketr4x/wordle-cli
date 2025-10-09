import random
import utils
import time

def settings():
    utils.clear_screen()
    length = 5 # TODO: Add more words... int(input("How long do you want your word? "))
    language = str(input("What language do you want your word? "))
    tries = int(input("How many tries do you want to have? "))
    return length, language, tries

def random_word(length, language):
    words = utils.wordlist(language)
    filtered = [word.strip().lower() for word in words if len(word.strip()) == int(length)]
    if not filtered:
        raise ValueError(f"No words found for {language} with length {length}")
    return random.choice(filtered), filtered

def format_known_letters(letterpositions):
    if not letterpositions:
        return "None"

    result = []
    for letter, positions in sorted(letterpositions.items()):
        if positions['pos']:
            for pos in sorted(positions['pos']):
                result.append(f"{pos + 1} - {letter.upper()}")

        if positions['not']:
            for pos in sorted(positions['not']):
                result.append(f"{pos + 1} - Not {letter.upper()}")

    return ", ".join(sorted(result)) if sorted(result) else "None"

def format_unused_letters(letters):
    formatted_letters = ""
    for letter in sorted(letters):
        formatted_letters += letter
    return formatted_letters


def game(word, filtered, tries, language):
    utils.clear_screen()
    print("Starting the game!")
    time.sleep(1)
    utils.clear_screen()

    letterpositions = {}
    letters = utils.letters(language)
    guesses = []

    game_status = 1
    while game_status == 1:
        if len(guesses) == tries - 1:
            game_status = 0

        utils.clear_screen()
        print("Current guesses:")
        for i in guesses:
            print(i)
        print(f"Remaining guesses: {tries-len(guesses)} \n")
        unused_letters = format_unused_letters(letters)
        print(f"Unused letters: {unused_letters}")
        formatted_letters = format_known_letters(letterpositions)
        print(f"Known letters: {formatted_letters}")


        guess = input(f"Write your {len(guesses)+1} guess:")
        if len(guess) == len(word) and guess in filtered:
            guesses.append(guess)
            if guess == word:
                print("You won!")
                game_status = 2
            else:
                for i, ch in enumerate(guess):
                    if ch == word[i]:
                        info = letterpositions.setdefault(ch, {'pos': set(), 'not': set()})
                        info['pos'].add(i)
                        info['not'].discard(i)
                        print(f"Letter {ch} is on position {i}")
                    elif ch in word:
                        info = letterpositions.setdefault(ch, {'pos': set(), 'not': set()})
                        info['not'].add(i)
                        print(f"Letter {ch} is not on position {i}")
                    if ch in letters:
                        letters.remove(ch)
    return game_status, guesses

def game_random():
    length, language, tries = settings()
    word, filtered = random_word(length, language)
    game_status, guesses = game(word, filtered, tries, language)

    utils.clear_screen()
    if game_status == 2:
        print(f"You won in {guesses} guesses!")
    else:
        print(f"You lost!")
    print(f"The word was {word}")
    time.sleep(1)
    # TODO: export to stats