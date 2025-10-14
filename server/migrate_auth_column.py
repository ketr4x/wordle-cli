from server.app import db

def migrate_auth_column():
    db.session.execute('ALTER TABLE "user" ALTER COLUMN auth TYPE VARCHAR(256);')
    db.session.commit()
    print("User.auth column updated to VARCHAR(256)")

if __name__ == "__main__":
    migrate_auth_column()
