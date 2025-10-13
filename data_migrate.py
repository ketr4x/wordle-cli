import json
import os

def read_words(path):
    with open(path, 'r', encoding='utf-8') as f:
        return [line.strip() for line in f if line.strip()]

def read_letters(path):
    with open(path, 'r', encoding='utf-8') as f:
        return f.read().strip()

def data(lang):
    return {
        "solutions": read_words(f'data/solutions/{lang}'),
        "wordlist": read_words(f'data/wordlist/{lang}'),
        "letters": list(read_letters(f'data/letters/{lang}').split())
    }

def languages():
    letters = set(os.listdir('data/letters'))
    solutions = set(os.listdir('data/solutions'))
    wordlist = set(os.listdir('data/wordlist'))
    return sorted(letters & solutions & wordlist)

for lang in languages():
    with open(f'flutter/assets/{lang}.json', 'w', encoding='utf-8') as out:
        json.dump(data(lang), out, ensure_ascii=False, indent=2)