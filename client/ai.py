from randomword import *
import http.client

# Courtesy of HackClub - do not abuse https://ai.hackclub.com/
def get_ai_word(language):
    conn = http.client.HTTPSConnection("ai.hackclub.com")
    payload = f'{{"messages":[{{"content":"Generate me a 5-letter wordle answer for this language: {language}","role":"user"}}]}}'
    headers = { 'Content-Type': "application/json" }
    conn.request("POST", "/chat/completions", payload, headers)
    res = conn.getresponse()
    data = res.read()
    return data.decode("utf-8")

def settings():
    utils.clear_screen()
    length = 5
    language = ""
    languages = list(map(str, utils.languages()))
    while language not in languages:
        language = (input(f"What language do you want your word? ({','.join(languages)}) ") or "en").strip().lower()
    return length, language

def game_ai():
    length, language = settings()
    word = get_ai_word(language)
    filtered = sorted(utils.wordlist(language))
    game_status, guesses, formatted_guesses, letters = game(word, 6, language)

    utils.clear_screen()
    if game_status == 2:
        print(f"You won in {len(guesses)} guesses!")
    else:
        print(f"You lost!")
    print(f"Your guesses were:")
    for i in formatted_guesses:
        print(i)
    print(f"The word was {word}")
    print(f"You had {len(letters)} letters remaining")
    input("\nPress `Enter` to continue...")