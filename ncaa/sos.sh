#!/bin/bash

psql volleyball-w -f sos/standardized_results.sql

psql volleyball-w -c "drop table if exists ncaa._basic_factors;"
psql volleyball-w -c "drop table if exists ncaa._parameter_levels;"

psql volleyball-w -c "vacuum analyze ncaa.results;"

R --vanilla -f sos/lmer.R

psql volleyball-w -c "vacuum full verbose analyze ncaa._basic_factors;"
psql volleyball-w -c "vacuum full verbose analyze ncaa._parameter_levels;"

psql volleyball-w -f sos/normalize_factors.sql

psql volleyball-w -c "vacuum full verbose analyze ncaa._factors;"

psql volleyball-w -f sos/schedule_factors.sql

psql volleyball-w -c "vacuum full verbose analyze ncaa._schedule_factors;"

psql volleyball-w -f sos/connectivity.sql > sos/connectivity.txt

psql volleyball-w -f sos/current_ranking.sql > sos/current_ranking.txt

psql volleyball-w -f sos/division_ranking.sql > sos/division_ranking.txt

psql volleyball-w -f sos/test_predictions.sql > sos/test_predictions.txt

psql volleyball-w -f sos/predict_daily.sql > sos/predict_daily.txt
