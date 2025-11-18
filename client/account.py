import utils
import requests

def account():
    utils.clear_screen()
    username = utils.read_config("username")
    password = utils.read_config("password")
    formatted_password = f"{password[0:3]}{('*' * (len(password) - 5) if len(password) > 5 else '')}{password[-2:]}" if len(password) >= 5 else password
    print("Account setup")
    print(f"Current username: {username}")
    print(f"Current password: {formatted_password}")
    if input("Do you want to change any details? (y/n) ").lower() == "y":
        new_username, new_password = username, password
        while new_username == username:
            new_username = input("New username: (Enter to preserve) ")
        while new_password == password:
            new_password = input("New password: (Enter to preserve) ")

        address = f"{utils.read_config('server_url')}/online/change_data"
        if new_username != username and new_password != password:
            mode = 'everything'
        elif new_username != username:
            mode = 'username'
        elif new_password != password:
            mode = 'password'
        else:
            print("Nothing to change")
            mode = ""

        response = None
        response2 = None
        if mode in ['everything', "username"]:
            response = requests.get(f'{address}/user?user={username}&auth={password}&new_user={new_username}')
        if mode in ['everything', "password"]:
            target_user = username if mode == 'password' else new_username
            response2 = requests.get(f"{address}/auth?user={target_user}&auth={password}&new_auth={new_password}")

        if response is not None and response2 is not None:
            if response.status_code == 200 and response2.status_code == 200:
                print("Changed the username and password successfully")
            elif response.status_code == 200:
                print("Changed the username successfully")
            elif response2.status_code == 200:
                print("Changed the password successfully")
            else:
                print(f'Failed to change the account details: {response.text}, {response2.text}')
            if response.status_code != 200 and mode in ["everything", "username"]:
                print(f"Failed to change the username: {response.text}")
            if response2.status_code != 200 and mode in ["everything", "password"]:
                print(f"Failed to change the password: {response2.text}")
            utils.write_config("password", new_password)
            utils.write_config("username", new_username)
    if input("Do you want to delete your account? (y/n) ").lower() == "y":
        if input("Confirm by typing 'delete' ").lower() == "delete":
            address = f"{utils.read_config('server_url')}/online/delete_account"
            response = requests.get(f"{address}?user={username}&auth={password}")
            if response.status_code == 200:
                print("Deleted the account successfully")
                utils.write_config("password", "")
                utils.write_config("username", "")
            else:
                print(f'Failed to delete the account: {response.text}')
    input('Press `Enter` to continue...')