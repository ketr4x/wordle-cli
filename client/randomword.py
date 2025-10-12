import random
import utils
import time
from collections import Counter

def settings():
    utils.clear_screen()
    length = 5 # TODO int(input("How long do you want your word? ") or 5)

    language = ""
    languages = list(map(str, utils.languages()))
    while language not in languages:
        language = (input(f"What language do you want your word? ({','.join(languages)}) ") or "en").strip().lower()

    tries = int(input("How many tries do you want to have? (default: 6) ") or 6)
    return length, language, tries

def format_unused_letters(letters):
    formatted_letters = ""
    for letter in sorted(letters):
        formatted_letters += letter
    return formatted_letters

def format_guess(guess, word):
    if not guess or len(guess) != len(word):
        return None

    output = []
    counts = Counter(word)
    status = [0]*len(guess)

    for i, char in enumerate(guess):
        if char == word[i]:
            status[i] = 2
            counts[char] -= 1
    for i, char in enumerate(guess):
        if status[i] == 0 and counts[char] > 0:
            status[i] = 1
            counts[char] -= 1

    for i, char in enumerate(guess):
        if status[i] == 2:
            output.append(f"\033[92m{char}\033[0m")
        elif status[i] == 1:
            output.append(f"\033[93m{char}\033[0m")
        else:
            output.append(f"\033[91m{char}\033[0m")
    return "".join(output)

def game(word, filtered, tries, language):
    utils.clear_screen()
    print("Starting the game!")
    time.sleep(1)
    utils.clear_screen()

    formatted_guesses = []
    letters = utils.letters(language)
    guesses = []
    game_status = 1

    while game_status == 1:
        if len(guesses) == tries - 1:
            game_status = 0

        utils.clear_screen()
        if formatted_guesses:
            print("Current guesses:")
            for i in formatted_guesses:
                print(i)

        print(f"\nRemaining guesses: {tries-len(guesses)}")
        print(f"Unused letters: {format_unused_letters(letters)}")

        guess = input(f"\nWrite your {utils.ordinal(len(guesses)+1)} guess: ").lower()
        if len(guess) == len(word) and guess in filtered:
            guesses.append(guess)
            if guess == word:
                print("You won!")
                game_status = 2
            else:
                for i, char in enumerate(guess):
                    if char in letters:
                        letters.remove(char)
            formatted_guesses.append(format_guess(guess, word))
    return game_status, guesses, formatted_guesses, letters

def game_random():
    length, language, tries = settings()
    filtered = utils.filtered(language, length)
    word = random.choice(filtered)
    game_status, guesses, formatted_guesses, letters = game(word, filtered, tries, language)

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
    # TODO: export to stats