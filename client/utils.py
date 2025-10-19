import json
import os
import hashlib
import requests

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
    return sorted(set(
        filename.removesuffix('.json')
        for filename in os.listdir('../data')
        if os.path.isfile(os.path.join('../data', filename))
    ))

def wordlist(language, online=False):
    return json.load(open(f'../data/{"" if not online else "online/"}{language}.json'))["wordlist"]

def solutions(language, online=False):
    return json.load(open(f'../data/{"" if not online else "online/"}{language}.json'))["solutions"]

def letters(language, online=False):
    return json.load(open(f'../data/{"" if not online else "online/"}{language}.json'))["letters"]

# Sorts the remaining letters
def format_unused_letters(letters):
    formatted_letters = ""
    for letter in sorted(letters):
        formatted_letters += letter
    return formatted_letters

def filtered(language, length=5, online=False):
    filtered_words = [word.strip().lower() for word in solutions(language, online) if len(word.strip()) == length]
    if not filtered_words:
        raise ValueError(f"No words found for {language} with length 5")
    return filtered_words

def language_check(language):
    request = requests.get(f"{read_config('server_url')}/online/languages/checksum?language={language}")
    if request.status_code != 200:
        if request.status_code == 400:
            return "Language invalid"
        else:
            return "Error"

    file_path = f'../data/online/{language}.json'
    if not os.path.isfile(file_path):
        download_status = language_download(language)
        if download_status != "Local language file correct":
            return download_status

    sha256 = hashlib.sha256()
    with open(file_path, "rb") as f:
        for chunk in iter(lambda: f.read(4096), b""):
            sha256.update(chunk)
    if sha256.hexdigest() == request.text:
        return "Local language file correct"
    return "Local language file invalid"

def language_download(language):
    download = requests.get(f"{read_config('server_url')}/online/languages/download?language={language}")
    if download.status_code != 200:
        if download.status_code == 400:
            return "Language invalid"
        else:
            return "Download error"
    with open(f'../data/online/{language}.json', 'w', encoding='utf-8') as out:
        json.dump(json.loads(download.text), out, ensure_ascii=False, indent=2)
    return "Local language file correct"

def clear_screen():
    os.system('cls' if os.name == 'nt' else 'clear')

def read_data(param):
    data = open('../data.json').read()
    return json.loads(data)[param]