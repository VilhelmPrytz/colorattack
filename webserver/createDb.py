from db import sql_query

def createDb():
    sql_query("""CREATE TABLE highscores (
id int NOT NULL AUTO_INCREMENT,
date DATETIME,
score int NOT NULL,
PRIMARY KEY (ID)
);""")

def create_v2_db():
    sql_query("""CREATE TABLE highscores_v2 (
id int NOT NULL AUTO_INCREMENT,
date DATETIME,
score int NOT NULL,
name varchar(10) NOT NULL,
PRIMARY KEY (ID)
);""")

if __name__ == "__main__":
    createDb()
