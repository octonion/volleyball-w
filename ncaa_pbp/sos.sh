#!/bin/bash

psql volleyball-w -f sos/standardized_results.sql

psql volleyball-w -c "drop table if exists ncaa_pbp._basic_factors;"
psql volleyball-w -c "drop table if exists ncaa_pbp._parameter_levels;"

psql volleyball-w -c "vacuum analyze ncaa_pbp.results;"

R --vanilla -f sos/lmer.R

psql volleyball-w -c "vacuum full verbose analyze ncaa_pbp._basic_factors;"
psql volleyball-w -c "vacuum full verbose analyze ncaa_pbp._parameter_levels;"

psql volleyball-w -f sos/normalize_factors.sql

psql volleyball-w -c "vacuum full verbose analyze ncaa_pbp._factors;"

psql volleyball-w -f sos/schedule_factors.sql

psql volleyball-w -c "vacuum full verbose analyze ncaa_pbp._schedule_factors;"

psql volleyball-w -f sos/connectivity.sql > sos/connectivity.txt

psql volleyball-w -f sos/current_ranking.sql > sos/current_ranking.txt
cp /tmp/current_ranking.csv sos/

psql volleyball-w -f sos/division_ranking.sql > sos/division_ranking.txt

psql volleyball-w -f sos/test_predictions.sql > sos/test_predictions.txt

psql volleyball-w -f sos/predict_weekly.sql > sos/predict_weekly.txt
