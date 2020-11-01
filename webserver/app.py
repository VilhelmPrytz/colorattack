# flask web server for Color Attack website
# Copyright Vilhelm Prytz 2019
# https://colorattack.vilhelmprytz.se - vilhelm@prytznet.se

# flask app init
from flask import Flask, render_template
from db import sql_query
app = Flask(__name__)

# variables
releases_filename = "releases.txt"

# parse releases
releases = []
with open(releases_filename, "r") as f:
    for release in f.read().split("\n"):
        if len(release) > 3:
            releases.append(release)

# functions
def getLeaderboard_v1():
    mysql_result = sql_query("SELECT * from highscores ORDER BY score DESC LIMIT 20")
    leaderboard = []
    i = 0
    for entry in mysql_result:
        i = i+1
        leaderboard.append([entry[1], entry[2], i])
    return leaderboard

def getLeaderboard_v2():
    mysql_result = sql_query("SELECT * from highscores_v2 ORDER BY score DESC LIMIT 20")
    leaderboard = []
    i = 0
    for entry in mysql_result:
        i = i+1
        leaderboard.append([entry[1], entry[2], entry[3], i])
    return leaderboard

# ERROR HANDLER
@app.errorhandler(500)
def error_500(e):
    return render_template("errors/500.html")

# main routes
@app.route("/")
def index():
    leaderboard_v1 = getLeaderboard_v1()
    leaderboard_v2 = getLeaderboard_v2()

    return render_template("index.html", releases=releases, latest_version=releases[-1], leaderboard_v1=leaderboard_v1, leaderboard_v2=leaderboard_v2)

# submit new score
@app.route("/api/v1/highscore/<highscore>")
def v1_highscore(highscore):
    insert_highscore = ("INSERT INTO highscores "
              "(date, score) "
              "VALUES (CURRENT_TIMESTAMP(), " + highscore + ")")

    result = sql_query(insert_highscore)

    return "success"

# submit new score
@app.route("/api/v2/highscore/<highscore>/<name>")
def v2_highscore(highscore, name):
    insert_highscore = ("INSERT INTO highscores_v2 "
              "(date, score, name) "
              "VALUES (CURRENT_TIMESTAMP(), " + highscore + ", '" + str(name) + "')")

    result = sql_query(insert_highscore)

    return "success"
