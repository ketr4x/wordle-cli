import random
import utils
import time

def settings():
    utils.clear_screen()
    length = int(input("How long do you want your word? "))
    language = str(input("What language do you want your word? "))
    tries = int(input("How many tries do you want to have? "))
    return length, language, tries

def random_word(length, language):
    words = utils.wordlist(language)
    filtered = [word.strip() for word in words if len(word.strip()) == int(length)]
    if not filtered:
        raise ValueError(f"No words found for {language} with length {length}")
    return random.choice(filtered), filtered

def game(word, filtered, tries, language):
    utils.clear_screen()
    # TODO: WORDLE ASCII ART
    print("Starting the game!")
    time.sleep(1)
    utils.clear_screen()

    letterpositions = {}
    letters = utils.letters(language)
    guesses = []

    game_status = 1
    while game_status == 1:
        if len(guesses) == tries:
            print("You lost!")
            game_status = 0

        utils.clear_screen()
        print("Current guesses:")
        for i in guesses:
            print(i)
        print(f"Remaining guesses: {tries-len(guesses)}\n")
        print(f"Remaining letters: {letters}")
        print(f"Known letters: {letterpositions}")

        guess = input(f"Write your {len(guesses)+1} guess:")
        if len(guess) == len(word) and guess in filtered:
            guesses.append(guess)
            if guess == word:
                print("You won!")
                game_status = 2
            else:
                for i in range(len(guess)):
                    if guess[i] == word[i]:
                        letterpositions.append([guess[i], i])
                        print(f"Letter {guess[i]} is on position {i+1}")
                    elif guess[i] in word:
                        letterpositions.merge([guess[i], f"Not {i+1}"])
                        print(f"Letter {guess[i]} is not on position {i+1}")
                    if guess[i] in letters:
                        letters.remove(guess[i])

def game1():
    length, language, tries = settings()
    word, filtered = random_word(length, language)
    game(word, filtered, tries, language)