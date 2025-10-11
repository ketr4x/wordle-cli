import utils
import json

def configuration():
    utils.clear_screen()
    print("Current configuration:")

    with open('user/config.json') as config_file:
        config = json.load(config_file)
    for key, value in config.items():
        print(f"{key}: {value}")

    while True:
        print("To change a value, type the key and enter the new value. Type Q to quit.")
        print("Example: server http://ketrax.ovh/dev/wordle")
        args = input(">").split()
        if args[0].lower() == "q":
            break
        utils.write_config(args[0], args[1])