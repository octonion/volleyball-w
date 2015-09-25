#!/bin/bash

cmd="psql template1 --tuples-only --command \"select count(*) from pg_database where datname = 'volleyball-w';\""

db_exists=`eval $cmd`
 
if [ $db_exists -eq 0 ] ; then
   cmd="createdb volleyball-w;"
   eval $cmd
fi

psql volleyball-w -f loaders_tsv/create_ncaa_pbp_schema.sql

tail -q -n+2 tsv/ncaa_teams*_1.tsv >> /tmp/ncaa_teams.tsv
psql volleyball-w -f loaders_tsv/load_ncaa_teams.sql
rm /tmp/ncaa_teams.tsv

tail -q -n+2 tsv/ncaa_team_schedules_mt_*_1.tsv >> /tmp/ncaa_team_schedules.tsv
psql volleyball-w -f loaders_tsv/load_ncaa_team_schedules.sql
rm /tmp/ncaa_team_schedules.tsv

#cp tsv/ncaa_games_box_scores_mt.tsv /tmp/ncaa_games_box_scores.tsv
#psql volleyball-w -f loaders_tsv/load_ncaa_box_scores.sql
#rm /tmp/ncaa_games_box_scores.tsv

tail -q -n+2 tsv/ncaa_team_rosters_mt*_1.tsv >> /tmp/ncaa_team_rosters.tsv
psql volleyball-w -f loaders_tsv/load_ncaa_team_rosters.sql
rm /tmp/ncaa_team_rosters.tsv

tail -q -n+2 tsv/ncaa_games_periods_mt*_1.tsv >> /tmp/ncaa_games_periods.tsv
rpl "[" "{" /tmp/ncaa_games_periods.tsv
rpl "]" "}" /tmp/ncaa_games_periods.tsv
psql volleyball-w -f loaders_tsv/load_ncaa_games_periods.sql
rm /tmp/ncaa_games_periods.tsv

#cp tsv/ncaa_games_play_by_play_mt.tsv /tmp/ncaa_games_play_by_play.tsv
#psql volleyball-w -f loaders_tsv/load_ncaa_games_play_by_play.sql
#rm /tmp/ncaa_games_play_by_play.tsv
