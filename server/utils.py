import os
import json

def get_language_name(symbol):
    LANGUAGE_NAMES = {
        "en": "English",
        "fr": "French",
        "de": "German",
    }

    return LANGUAGE_NAMES[symbol]

def read_config(param):
    with open('config.json') as config_file:
        config = json.load(config_file)
    if param in config:
        return config[param]
    else:
        return None

# Get list of the available languages
def languages():
    letters = set(os.listdir('../data/letters'))
    solutions = set(os.listdir('../data/solutions'))
    wordlist = set(os.listdir('../data/wordlist'))
    return sorted(letters & solutions & wordlist)

def wordlist(language):
    return open(f'../data/wordlist/{language}').read().lower().split()

def solutions(language):
    return open(f'../data/solutions/{language}').read().lower().split()

# Get the letters for a specified language
def letters(language):
    return open(f'../data/letters/{language}').read().lower().split()

# Get words with length of 5
def filtered(language):
    filtered_words = [word.strip().lower() for word in solutions(language) if len(word.strip()) == 5]
    if not filtered_words:
        raise ValueError(f"No words found for {language} with length 5")
    return filtered_words