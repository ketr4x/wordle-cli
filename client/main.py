import time
import utils

from randomword import game_random
from todaysword import game_daily

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



while True:
    utils.clear_screen()
    print("Welcome to Wordle!")
    time.sleep(1)
    utils.clear_screen()
    print(ascii_art)

    print("1. Random Word\n2. Today's Word\n3. Ranked")
    print("\nC. Configuration")
    print("S. Statistics")
    print("Q. Quit")

    option = input("\nChoose the option you want...: ").upper()
    if option == '1':
        game_random()
    elif option == '2':
        game_daily()
    elif option == '3':
        print("not implemented")
    elif option == 'C':
        print("not implemented")
    elif option == 'S':
        print("not implemented")
    elif option == 'Q' or option == 'X':
        exit()
    else:
        print("Invalid option")