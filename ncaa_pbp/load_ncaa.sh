#!/bin/bash

cmd="psql template1 --tuples-only --command \"select count(*) from pg_database where datname = 'volleyball-w';\""

db_exists=`eval $cmd`
 
if [ $db_exists -eq 0 ] ; then
   cmd="psql template1 -t -c \"create database volleyball-w\" > /dev/null 2>&1"
#   cmd="psql -t -c \"$sql\" > /dev/null 2>&1"
#   cmd="createdb volleyball-w"
   eval $cmd
fi

psql volleyball-w -f loaders/create_ncaa_pbp_schema.sql

cp csv/ncaa_team_schedules.csv /tmp/ncaa_team_schedules.csv
chmod 777 /tmp/ncaa_team_schedules.csv
psql volleyball-w -f loaders/load_ncaa_team_schedules.sql
rm /tmp/ncaa_team_schedules.csv

cp csv/ncaa_team_rosters.csv /tmp/ncaa_team_rosters.csv
chmod 777 /tmp/ncaa_team_rosters.csv
psql volleyball-w -f loaders/load_ncaa_team_rosters.sql
rm /tmp/ncaa_team_rosters.csv

cp csv/ncaa_periods.csv /tmp/ncaa_periods.csv
chmod 777 /tmp/ncaa_games_periods.csv
psql volleyball-w -f loaders/load_ncaa_games_periods.sql
rm /tmp/ncaa_games_periods.csv

cp csv/ncaa_games_play_by_play.csv /tmp/ncaa_games_play_by_play.csv
chmod 777 /tmp/ncaa_games_play_by_play.csv
psql volleyball-w -f loaders/load_ncaa_games_play_by_play.sql
rm /tmp/ncaa_games_play_by_play.csv
