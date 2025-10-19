import time
import utils
import os

from updater import update
from ai import game_ai
from configuration import configuration
from randomword import game_random
from todaysword import game_daily
from online import game_online, connection

ascii_art = r"""
     /$$      /$$                           /$$ /$$                  /$$$$$$  /$$       /$$$$$$
    | $$  /$ | $$                          | $$| $$                 /$$__  $$| $$      |_  $$_/
    | $$ /$$$| $$  /$$$$$$   /$$$$$$   /$$$$$$$| $$  /$$$$$$       | $$  \__/| $$        | $$  
    | $$/$$ $$ $$ /$$__  $$ /$$__  $$ /$$__  $$| $$ /$$__  $$      | $$      | $$        | $$  
    | $$$$_  $$$$| $$  \ $$| $$  \__/| $$  | $$| $$| $$$$$$$$      | $$      | $$        | $$  
    | $$$/ \  $$$| $$  | $$| $$      | $$  | $$| $$| $$_____/      | $$    $$| $$        | $$  
    | $$/   \  $$|  $$$$$$/| $$      |  $$$$$$$| $$|  $$$$$$$      |  $$$$$$/| $$$$$$$$ /$$$$$$
    |__/     \__/ \______/ |__/       \_______/|__/ \_______/       \______/ |________/|______/
    """

if os.name == 'nt':
    os.system('')

while True:
    utils.clear_screen()
    print("Welcome to Wordle!")
    time.sleep(1)
    utils.clear_screen()
    print(ascii_art)

    print("1. Random Word\n2. Today's Word\n3. AI game\n4. Ranked")
    print("\nC. Configuration\nX. Connection\nU. Updater\nQ. Quit")

    option = input("\nChoose the option you want...: ").upper()
    if option == '1':
        game_random()
    elif option == '2':
        game_daily()
    elif option == '3':
        game_ai()
    elif option == '4':
        game_online()
    elif option == 'C':
        configuration()
    elif option == 'X':
        connection()
    elif option == 'U':
        update()
    elif option == 'Q' or option == 'X':
        utils.clear_screen()
        print("See you next time!")
        time.sleep(1)
        exit()
    else:
        print("Invalid option")