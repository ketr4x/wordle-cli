from randomword import game_random
import utils
import requests
from bs4 import BeautifulSoup

def get_word():
    daily_wordle_page = requests.get(utils.read_config('daily_wordle_page'))
    body = BeautifulSoup(daily_wordle_page.text, 'html.parser').body.decode_contents().split()[0]
    return str(body) if body else Exception("Cannot get today's wordle")

def game_daily():
    game_random(get_word())