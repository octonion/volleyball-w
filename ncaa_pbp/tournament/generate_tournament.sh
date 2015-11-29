#!/bin/bash

#cp rounds_2016.csv /tmp/rounds.csv
cp rounds_updated.csv /tmp/rounds.csv
psql volleyball-w -f load_rounds.sql
rm /tmp/rounds.csv

psql volleyball-w -f update_round.sql

rpl "round_id=1" "round_id=2" update_round.sql
psql volleyball-w -f update_round.sql

rpl "round_id=2" "round_id=3" update_round.sql
psql volleyball-w -f update_round.sql

rpl "round_id=3" "round_id=4" update_round.sql
psql volleyball-w -f update_round.sql

rpl "round_id=4" "round_id=1" update_round.sql

psql volleyball-w -f round_p.sql > round_p.txt
cp /tmp/round_p.csv .

psql volleyball-w -f champion_p.sql > champion_p.txt
cp /tmp/champion_p.csv .