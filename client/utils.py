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
    with open('config.json') as config_file:
        config = json.load(config_file)
    if param in config:
        return config[param]
    else:
        return None

def write_config(param, value):
    with open('config.json') as config_file:
        config = json.load(config_file)
    config[param] = value
    with open('config.json', 'w') as config_file:
        json.dump(config, config_file)

def languages():
    return sorted(set(filename.removesuffix('.json') for filename in os.listdir('../data')))

def wordlist(language):
    return json.load(open(f'../data/{language}.json'))["wordlist"]

def solutions(language):
    return json.load(open(f'../data/{language}.json'))["solutions"]

def letters(language):
    return json.load(open(f'../data/{language}.json'))["letters"]

# Sorts the remaining letters
def format_unused_letters(letters):
    formatted_letters = ""
    for letter in sorted(letters):
        formatted_letters += letter
    return formatted_letters



def filtered(language, length=5):
    filtered_words = [word.strip().lower() for word in wordlist(language) if len(word.strip()) == length]
    if not filtered_words:
        raise ValueError(f"No words found for {language} with length 5")
    return filtered_words

def clear_screen():
    os.system('cls' if os.name == 'nt' else 'clear')