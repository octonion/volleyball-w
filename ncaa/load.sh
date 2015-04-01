#!/bin/bash

cmd="psql template1 --tuples-only --command \"select count(*) from pg_database where datname = 'volleyball-w';\""

db_exists=`eval $cmd`
 
if [ $db_exists -eq 0 ] ; then
   cmd="createdb volleyball-w"
   eval $cmd
fi

psql volleyball-w -f schema/create_schema_ncaa.sql

tail -q -n+2 csv/ncaa_games_*.csv > /tmp/ncaa_games.csv
psql volleyball-w -f loaders/load_ncaa_games.sql
rm /tmp/ncaa_games.csv

#cat csv/ncaa_players_*.csv > /tmp/ncaa_statistics.csv
#rpl ",-," ",," /tmp/ncaa_statistics.csv
#rpl ",-," ",," /tmp/ncaa_statistics.csv
#rpl ".," "," /tmp/ncaa_statistics.csv
#rpl ".0," "," /tmp/ncaa_statistics.csv
#rpl ".00," "," /tmp/ncaa_statistics.csv
#rpl ".000," "," /tmp/ncaa_statistics.csv
#rpl -e ",-\n" ",\n" /tmp/ncaa_statistics.csv
#psql volleyball-w -f loaders/load_ncaa_statistics.sql
#rm /tmp/ncaa_statistics.csv

#psql volleyball-w -f schema/create_ncaa_players.sql

cp csv/ncaa_schools.csv /tmp/ncaa_schools.csv
psql volleyball-w -f loaders/load_ncaa_schools.sql
rm /tmp/ncaa_schools.csv

cp csv/ncaa_divisions.csv /tmp/ncaa_divisions.csv
psql volleyball-w -f loaders/load_ncaa_divisions.sql
rm /tmp/ncaa_divisions.csv

#cp ncaa/schools_divisions.csv /tmp/ncaa_schools_divisions.csv
#psql volleyball-w -f load_ncaa_divisions.sql
#rm /tmp/ncaa_schools_divisions.csv

cp csv/ncaa_colors.csv /tmp/ncaa_colors.csv
psql volleyball-w -f loaders/load_ncaa_colors.sql
rm /tmp/ncaa_colors.csv

#cp csv/ncaa_geocodes.csv /tmp/ncaa_geocodes.csv
#psql volleyball-w -f loaders/load_ncaa_geocodes.sql
#rm /tmp/ncaa_geocodes.csv
