import os

def wordlist(language):
    if language == 'en':
        return open('data/wordlist/en.txt').read().splitlines()
    return None

def letters(language):
    if language == 'en':
        return open('data/letters/en.txt').read().split()
    return None

def clear_screen():
    os.system('cls' if os.name == 'nt' else 'clear')