import random
from collections import Counter
import utils

def generate_word(language):
    filtered = utils.filtered(language)
    return random.choice(filtered)

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
            output.append(2)
        elif status[i] == 1:
            output.append(1)
        else:
            output.append(0)
    return output

def check_guess(word, guess, language, guess_number, letters):
    tries = 6
    game_status = 1

    if guess_number == tries - 1:
        game_status = 0

    if len(guess) == len(word) and guess in utils.wordlist(language):
        if guess == word:
            game_status = 2
        else:
            for char in set(guess):
                if char in letters:
                    letters.remove(char)
    return game_status, letters, format_guess(guess, word)