from sqlalchemy import create_engine, Column, Integer, String
from sqlalchemy.orm import declarative_base 
from sqlalchemy.orm import sessionmaker

# 1. Create an Engine to connect to the SQLite database
# The 'sqlite:///' prefix indicates a relative path to the database file
# 'echo=True' prints generated SQL statements to the console (useful for learning)
engine = create_engine('sqlite:///apptrail.db', echo=True)

# 2. Define a Base class for your models
Base = declarative_base()

# 3. Define your data model as a Python class
class User(Base):
    __tablename__ = 'users'
    id = Column(Integer, primary_key=True)
    username = Column(String)
    password = Column(String)
    score = Column(Integer)

    def to_dict(self):
        return {
            'id': self.id,
            'username': self.username,
            'password': self.password,
            'score': self.score
        }

    def __repr__(self):
        return f"<User(username='{self.username}', password='{self.password}', score='{self.score}')>"

# 4. Create the tables in the database
Base.metadata.create_all(engine)

# 5. Create a Session to interact with the database
Session = sessionmaker(bind=engine)
session = Session()

# 6. Insert records
if not session.query(User).first():  # Check if the table is empty before adding users
    user1 = User(username='spongebob', password='spongebob123', score=100)
    user2 = User(username='patrick', password='patrick123', score=80)
    session.add_all([user1, user2])
    session.commit()

