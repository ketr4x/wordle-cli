import json
import os

def read_file(path):
    with open(path, 'r', encoding='utf-8') as f:
        return json.load(f)

def languages():
    return sorted(set(filename.removesuffix('.json') for filename in os.listdir('data')))

for lang in languages():
    with open(f'flutter/assets/{lang}.json', 'w', encoding='utf-8') as out:
        json.dump(read_file(lang), out, ensure_ascii=False, indent=2)