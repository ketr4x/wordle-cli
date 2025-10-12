import utils
import requests

def get_leaderboard(state, user, auth):
    response = requests.get(f"{utils.read_config('server_url')}/online/leaderboard?state={state}&user={user}&auth={auth}")
    decoded = utils.json_decode(response.text)
    top_points = decoded['top_points']
    top_matches = decoded['top_matches']
    top_avg_time = decoded['top_avg_time']
    top_winrate = decoded['top_winrate']
    user_position = decoded['user_position']
    return top_points, top_matches, top_avg_time, top_winrate, user_position

def leaderboard():
    utils.clear_screen()
    user = utils.read_config('username')
    auth = utils.read_config('password')

    def pad_with_emoji(text, width):
        emoji_count = sum(1 for c in text if ord(c) > 0x1F000)
        return text + " " * (width - len(text) - emoji_count)

    while True:
        top_points, top_matches, top_avg_time, top_winrate, user_position = get_leaderboard('basic', user, auth)

        print("=" * 120)
        print("🏆  LEADERBOARD  🏆".center(120))
        print("=" * 120)

        headers = [
            "📊 ELO                ",
            "🎮 MATCHES            ",
            "⚡ AVG TIME           ",
            "🎯 WINRATE           "
        ]
        print(f"\n{headers[0]} {headers[1]} {headers[2]} {headers[3]}")
        print(f"{'-' * 21} {'-' * 21} {'-' * 21} {'-' * 21}")

        for i in range(10):
            medal = "🥇" if i == 0 else "🥈" if i == 1 else "🥉" if i == 2 else f"{i+1:2}."

            if i < len(top_points):
                p = top_points[i]
                star = "⭐" if p['username'] == user else "  "
                col1 = pad_with_emoji(f"{medal} {p['username'][:9]:<9} {p['points']:>4} {star}", 21)
            else:
                col1 = " " * 21

            if i < len(top_matches):
                m = top_matches[i]
                star = "⭐" if m['username'] == user else "  "
                col2 = pad_with_emoji(f"{medal} {m['username'][:9]:<9}  {m['matches']:>3} {star}", 21)
            else:
                col2 = " " * 21

            if i < len(top_avg_time):
                a = top_avg_time[i]
                star = "⭐" if a['username'] == user else "  "
                time_str = f"{a['avg_time']:.1f}s"
                col3 = pad_with_emoji(f"{medal} {a['username'][:9]:<9} {time_str:>5} {star}", 21)
            else:
                col3 = " " * 21

            if i < len(top_winrate):
                w = top_winrate[i]
                star = "⭐" if w['username'] == user else "  "
                wr_str = f"{w['winrate'] * 100:.1f}%"
                col4 = pad_with_emoji(f"{medal} {w['username'][:9]:<9} {wr_str:>6} {star}", 21)
            else:
                col4 = " " * 21

            print(f"{col1} {col2} {col3} {col4}")

        print(f"\n{'Your rank: #' + str(user_position['points']):<21} "
              f"{'Your rank: #' + str(user_position['matches']):<21} "
              f"{'Your rank: #' + str(user_position['avg_time']):<21} "
              f"{'Your rank: #' + str(user_position['winrate']):<21}")
        print("=" * 120)

        input("\nPress `Enter` to exit...")
        break