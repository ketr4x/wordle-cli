import os
import json

def read_config(param):
    with open('server/config.json') as config_file:
        config = json.load(config_file)
    if param in config:
        return config[param]
    else:
        return None

# Get a list of the available languages
def languages():
    return sorted(set(
        filename.removesuffix('.json')
        for filename in os.listdir('data')
        if os.path.isfile(os.path.join('data', filename))
    ))

def wordlist(language):
    with open(f'data/{language}.json') as f:
        return json.load(f)["wordlist"]

def solutions(language):
    with open(f'data/{language}.json') as f:
        return json.load(f)["solutions"]

def letters(language):
    with open(f'data/{language}.json') as f:
        return json.load(f)["letters"]

# Get words with length of 5
def filtered(language):
    filtered_words = [word.strip().lower() for word in solutions(language) if len(word.strip()) == 5]
    if not filtered_words:
        raise ValueError(f"No words found for {language} with length 5")
    return filtered_words