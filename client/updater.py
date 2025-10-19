import json
import os
import subprocess
import sys
from urllib.request import urlopen, Request
from urllib.error import URLError, HTTPError
from datetime import datetime
import utils

def load_json(path):
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)

def fetch_json(url, timeout=10):
    req = Request(url, headers={"User-Agent": "updater/1.0"})
    with urlopen(req, timeout=timeout) as r:
        return json.loads(r.read().decode("utf-8"))

def version_tuple(v):
    return tuple(int(x) for x in str(v).split(".") if x.isdigit())

def is_git_repo():
    return os.path.isdir(".git")

def run(cmd):
    print(">", " ".join(cmd))
    completed = subprocess.run(cmd, check=False)
    return completed.returncode == 0

def pip_update(repo, ref="master"):
    pkg = f"git+{repo}@{ref}"
    return run([sys.executable, "-m", "pip", "install", "--upgrade", pkg])

def git_update(remote_branch="origin/master"):
    if not is_git_repo():
        print("Not a git clone; cannot git-pull.")
        return False
    if not run(["git", "fetch", "origin"]):
        return False
    return run(["git", "reset", "--hard", remote_branch])

def update():
    utils.clear_screen()
    if not os.path.exists("../data.json"):
        print(f"Local manifest {"../data.json"} not found.")
        input("Press `Enter` to continue...")
        return 2

    local = load_json("../data.json")
    update_url = local.get("update_url") or "https://raw.githubusercontent.com/ketr4x/wordle-cli/master/data.json"
    try:
        remote = fetch_json(update_url)
    except (URLError, HTTPError, Exception) as e:
        print("Failed to fetch remote manifest:", e)
        input("Press `Enter` to continue...")
        return 3

    lv = version_tuple(local.get("version", "0"))
    rv = version_tuple(remote.get("version", "0"))
    print("Local version:", local.get("version"), "- Remote version:", remote.get("version"))

    if rv <= lv:
        print("Already up to date.")
        input("Press `Enter` to continue...")
        return 0

    print("New version available!")
    print(f"Updating to {remote.get("version")} from {local.get("version")}")
    published_at = remote.get("published_at", "")
    if published_at:
        try:
            pub_date = datetime.fromisoformat(published_at.replace('Z', '+00:00'))
            print(f"The update is released at {pub_date.strftime('%Y-%m-%d %H:%M:%S UTC')}")
        except ValueError:
            print(f"The update is released at {published_at}")
    print("Release notes:")
    print(remote.get("release_notes", "No release notes available."))
    if is_git_repo():
        updated = git_update("origin/" + remote["branch"])
    else:
        repo_url = remote.get("repo") or local.get("repo")
        updated = pip_update(repo_url, remote["branch"])

    if updated:
        local["version"] = remote.get("version")
        try:
            with open("../data.json", "w", encoding="utf-8") as f:
                json.dump(local, f, indent=2)
        except FileNotFoundError:
            pass
        print("Update applied.")
        input("Press `Enter` to continue...")
        return 0
    else:
        print("Update failed.")
        input("Press `Enter` to continue...")
        return 4