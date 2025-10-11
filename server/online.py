import random
import utils

def generate_word(language):
    solutions = utils.solutions(language)
    filtered = [word.strip().lower() for word in solutions if len(word.strip()) == 5]
    if not filtered:
        raise ValueError(f"No words found for {language}")
    return random.choice(filtered), utils.wordlist(language)

