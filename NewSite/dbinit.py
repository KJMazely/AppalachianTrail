from sqlalchemy import create_engine, Column, Integer, String
from sqlalchemy.orm import declarative_base 
from sqlalchemy.orm import sessionmaker
import hashlib


def _hash_password(password: str) -> str:
    return hashlib.sha256(password.encode('utf-8')).hexdigest()

engine = create_engine('sqlite:///apptrail.db', echo=True)

# 2. Define a Base class for your models
Base = declarative_base()

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

Base.metadata.create_all(engine)

Session = sessionmaker(bind=engine)
session = Session()

# add initial users
if not session.query(User).first():  # Check if the table is empty before adding users
    user1 = User(username='spongebob', password=_hash_password('spongebob123'), score=0)
    user2 = User(username='patrick', password=_hash_password('patrick123'), score=20)
    session.add_all([user1, user2])
    session.commit()

