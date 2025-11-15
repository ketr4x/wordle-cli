import utils
import requests

def account():
    utils.clear_screen()
    username = utils.read_config("username")
    password = utils.read_config("password")
    print("Account setup")
    print(f"Current username: {username}")
    print(f"Current password: {password}")
    if input("Do you want to change any details? (y/n) ").lower() == "y":
        new_username, new_password = username, password
        while new_username == username:
            new_username = input("New username: (Enter to preserve) ")
        while new_password == password:
            new_password = input("New password: (Enter to preserve) ")

        address = f"{utils.read_config("server_url")}/online/change_data"
        if new_username != username and new_password != password:
            mode = 'everything'
        elif new_username != username:
            mode = 'username'
        elif new_password != password:
            mode = 'password'
        else:
            print("Nothing to change")
            input("Press `Enter` to continue...")
            return

        response = requests.get(f'{address}/user?user={username}&auth={password}&new_user={new_username}') if (mode == 'everything' or mode == 'username') else requests.Response()
        response2 = requests.get(f'{address}/auth?user={username if mode == "password" else new_username}&auth={password}&new_auth={new_password}') if (mode == 'everything' or mode == 'password') else requests.Response()

        if response.status_code == 200 and response2.status_code == 200:
            print("Changed the username and password successfully")
            input("Press `Enter` to continue...")
            utils.write_config("password", new_password)
            utils.write_config("username", new_username)
            return
        elif response.status_code == 200:
            print("Changed the username successfully")
        elif response2.status_code == 200:
            print("Changed the password successfully")
        else:
            print(f'Failed to change the account details: {response.text}, {response2.text}')
            input('Press `Enter` to continue...')
            return
        if response.status_code != 200 and mode in ["everything", "username"]:
            print(f"Failed to change the username: {response.text}")
        if response2.status_code != 200 and mode in ["everything", "password"]:
            print(f"Failed to change the password: {response2.text}")
        input("Press `Enter` to continue...")
        utils.write_config("password", new_password)
        utils.write_config("username", new_username)