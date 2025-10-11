import json
import os

def ordinal(n):
    if 10 <= n % 100 <= 20:
        suffix = 'th'
    else:
        suffix = {1: 'st', 2: 'nd', 3: 'rd'}.get(n % 10, 'th')
    return f"{n}{suffix}"

def json_decode(param):
    return json.loads(param)

def read_config(param):
    with open('user/config.json') as config_file:
        config = json.load(config_file)
    return config[param]

def write_config(param, value):
    with open('user/config.json') as config_file:
        config = json.load(config_file)
    config[param] = value
    with open('user/config.json', 'w') as config_file:
        json.dump(config, config_file)

def get_language_name(symbol):
    LANGUAGE_NAMES = {
        "en": "English",
        "fr": "French",
        "de": "German",
    }

    return LANGUAGE_NAMES[symbol]

def languages():
    letters = set(os.listdir('../data/letters'))
    solutions = set(os.listdir('../data/solutions'))
    wordlist = set(os.listdir('../data/wordlist'))
    return sorted(letters & solutions & wordlist)

def wordlist(language="en"):
    return open(f'../data/wordlist/{language}').read().lower().split()

def solutions(language="en"):
    return open(f'../data/solutions/{language}').read().lower().split()

def letters(language="en"):
    return open(f'../data/letters/{language}').read().lower().split()

def filtered(language, length=5):
    filtered_words = [word.strip().lower() for word in wordlist(language) if len(word.strip()) == length]
    if not filtered_words:
        raise ValueError(f"No words found for {language} with length 5")
    return filtered_words

def clear_screen():
    os.system('cls' if os.name == 'nt' else 'clear')