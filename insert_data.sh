#! /bin/bash

if [[ $1 == "test" ]]
then
  PSQL="psql --username=postgres --dbname=worldcuptest -t --no-align -c"
else
  PSQL="psql --username=freecodecamp --dbname=worldcup -t --no-align -c"
fi

# Do not change code above this line. Use the PSQL variable above to query your database.

script_dir="$(cd "$(dirname "$0")" && pwd)"
team_values=""
game_values=""
declare -A teams_seen

while IFS=, read -r year round winner opponent winner_goals opponent_goals
do
  if [[ -z ${teams_seen[$winner]} ]]
  then
    teams_seen[$winner]=1
    team_values+="('$winner'),"
  fi
  if [[ -z ${teams_seen[$opponent]} ]]
  then
    teams_seen[$opponent]=1
    team_values+="('$opponent'),"
  fi
  game_values+="($year, '$round', '$winner', '$opponent', $winner_goals, $opponent_goals),"
done < <(tail -n +2 "$script_dir/games.csv")

team_values="${team_values%,}"
game_values="${game_values%,}"

$PSQL "TRUNCATE TABLE games, teams RESTART IDENTITY CASCADE;
INSERT INTO teams (name) VALUES $team_values ON CONFLICT (name) DO NOTHING;
INSERT INTO games (year, round, winner_id, opponent_id, winner_goals, opponent_goals)
SELECT game.year, game.round, winner.team_id, opponent.team_id, game.winner_goals, game.opponent_goals
FROM (VALUES $game_values) AS game(year, round, winner_name, opponent_name, winner_goals, opponent_goals)
JOIN teams AS winner ON winner.name = game.winner_name
JOIN teams AS opponent ON opponent.name = game.opponent_name;"
