import time
import os

from randomword import game1
import todaysword
import settings

import utils

print("Welcome to Wordle!")
time.sleep(1)
utils.clear_screen()
# TODO: 'WORDLE' ASCII ART HERE
print("Choose the option you want...")
print("1. Random Word\n2. Today's Word")
print("\nS. Settings")
print("Q. Quit")

option = input().upper()
if option == '1':
    game1()
elif option == '2':
    todaysword()
elif option == 'S':
    settings()
elif option == 'Q':
    exit
else:
    print("Invalid option")