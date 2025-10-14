from server.app import app, db
from sqlalchemy import text

def migrate_auth_column():
    with app.app_context():
        db.session.execute(text('ALTER TABLE "user" ALTER COLUMN auth TYPE VARCHAR(256);'))
        db.session.commit()
        print("User.auth column updated to VARCHAR(256)")

if __name__ == "__main__":
    migrate_auth_column()