import time
import utils
import json

def configuration():
    utils.clear_screen()

    while True:
        print("Current configuration:")

        with open('user/config.json') as config_file:
            config = json.load(config_file)
        for key, value in config.items():
            print(f"{key}: {value}")

        print("To change a value, type the key and enter the new value. Type Q to quit.")
        print("Example: server http://ketrax.ovh/dev/wordle")
        args = input(">").split()
        if args[0].lower() == "q" or args[0].lower() == "quit" or args[0].lower() == "exit":
            break
        if len(args) == 1:
            args.append("")
        if len(args) == 2:
            if utils.read_config(args[0]) is not None:
                utils.write_config(args[0], args[1])
            else:
                print("Please enter a valid argument")
                time.sleep(1)
        else:
            print("Please enter a valid argument")
            time.sleep(1)