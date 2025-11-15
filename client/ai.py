import json
from randomword import *
from openai import OpenAI
import utils
import requests

# Courtesy of HackClub - do not abuse https://ai.hackclub.com/
def start_ai_client(language):
    if not utils.read_config("ai_model"):
        models_raw = requests.get(
            url="https://ai.hackclub.com/proxy/v1/models",
            headers={"Authorization": f"Bearer {utils.read_config("ai_api_key")}"}
        ).json()["data"]
        models = []
        for model in models_raw:
            models.append(model["id"])
        models.remove("google/gemini-2.5-flash-image")
    else:
        models = []

    client = OpenAI(
        api_key=utils.read_config("ai_api_key"),
        base_url="https://ai.hackclub.com/proxy/v1"
    )
    response = client.chat.completions.create(
        model=(random.choice(models) if models else "google/gemini-2.5-flash"),
        messages=[
            {"role": "system", "content": "You are a wordle game provider."},
            {
                "role": "user",
                "content": f"Provide a single 5-character {language} word suitable as an answer for a Wordle-style game. Provide a full letter list for {language} language like a,b,c etc. Reply with only the {language} word in lowercase and a list ['letter1', 'letter2', etc] with no additional text. The format should be: a json word:word, letters:letters. Do not use tags like ```json."
            }
        ]
    )
    return json.loads(str(response.choices[0].message.content))

def check_guess(language, word):
    if not utils.read_config("ai_model"):
        models_raw = requests.get(
            url="https://ai.hackclub.com/proxy/v1/models",
            headers={"Authorization": f"Bearer {utils.read_config("ai_api_key")}"}
        ).json()["data"]
        models = []
        for model in models_raw:
            models.append(model["id"])
        models.remove("google/gemini-2.5-flash-image")
    else:
        models = [utils.read_config("ai_model")]

    client = OpenAI(
        api_key=utils.read_config("ai_api_key"),
        base_url="https://ai.hackclub.com/proxy/v1"
    )
    response = client.chat.completions.create(
        model=(random.choice(models) if models else "google/gemini-2.5-flash"),
        messages=[
            {"role": "system", "content": "You are a wordle game provider."},
            {"role": "user", "content": f"Check if the word '{word}' is a correct 5-character word in {language} for a Wordle-style game. Reply with only True or False and no additional text."}
        ]
    )
    return str(response.choices[0].message.content).lower() == "true"

def game(word, tries, language, letters):
    utils.clear_screen()
    print("Starting the game!")
    time.sleep(1)
    utils.clear_screen()

    formatted_guesses = []
    guesses = []
    game_status = 1

    while game_status == 1:
        if len(guesses) == tries - 1:
            game_status = 0

        utils.clear_screen()
        if formatted_guesses:
            print("Current guesses:")
            for i in formatted_guesses:
                print(i)

        print(f"\nRemaining guesses: {tries-len(guesses)}")
        print(f"Unused letters: {utils.format_unused_letters(letters)}")

        guess = input(f"\nWrite your {utils.ordinal(len(guesses)+1)} guess: ").lower()
        if len(guess) == len(word) and check_guess(language, guess):
            guesses.append(guess)
            if guess == word:
                print("You won!")
                game_status = 2
            else:
                for i, char in enumerate(guess):
                    if char in letters:
                        letters.remove(char)
            formatted_guesses.append(format_guess(guess, word))
    return game_status, guesses, formatted_guesses, letters

def settings():
    utils.clear_screen()
    length = 5
    language = ''
    while not language:
        language = input(f"What language do you want your word? ").strip().lower()
    tries = int(input("How many tries do you want to have? (default: 6) ") or 6)
    return length, language, tries

def game_ai():
    if not utils.read_config("ai_api_key"):
        print("Please set up your API key.")
        input("\nPress `Enter` to continue...")
        return
    length, language, tries = settings()
    ai_payload = start_ai_client(language)
    word = ai_payload["word"]
    all_letters = ai_payload["letters"]
    game_status, guesses, formatted_guesses, letters = game(word, tries, language, all_letters)

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