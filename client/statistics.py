import utils
import requests

# Fetches user statistics from the server
def get_stats(user, auth):
    response = requests.get(f"{utils.read_config('server_url')}/online/stats?user={user}&auth={auth}")
    if response.status_code != 200:
        print(f"Error fetching stats: {response.status_code} - {response.text}")
        return None, None, None, None, None, None
    
    statistics = response.json()
    avg_time = statistics["avg_time"]
    matches = statistics["matches"]
    points = statistics["points"]
    wins = statistics["wins"]
    word_freq = statistics["word_freq"]
    registered_on = statistics["registered_on"]
    return avg_time, matches, points, wins, word_freq, registered_on

def stats():
    user = utils.read_config("username")
    auth = utils.read_config("password")  # Changed from "auth" to "password"

    utils.clear_screen()
    print(f"{user}'s statistics:\n")
    result = get_stats(user, auth)
    
    # Handle potential errors
    if result[0] is None:
        print("Failed to fetch statistics. Please try again later.")
        input("\nPress `Enter` to exit...")
        return
    
    avg_time, matches, points, wins, word_freq, registered_on = result
    print(f"Registered on {registered_on}")
    print(f"Average time per game: {avg_time:.2f}s")
    print(f"Total matches: {matches}")
    print(f"Total wins: {wins}")
    print(f"Total losses: {matches - wins}")
    print(f"Winrate: {wins / (matches - wins) * 100:.2f}%")
    print(f"ELO: {points}")
    if word_freq:
        print("Most used words:")
        for word in reversed(sorted(word_freq, key=word_freq.get)):
            print(f"{word}: {word_freq[word]}")
    else:
        print("No words recorded yet.")
    input("\nPress `Enter` to exit...")