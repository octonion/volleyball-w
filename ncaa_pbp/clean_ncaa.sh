#!/bin/bash

psql volleyball-w -f clean/add_ncaa_play_by_play_id.sql

psql volleyball-w -f clean/add_ncaa_team_schedules_extra_fields.sql

psql volleyball-w -f clean/generate_play_by_play_clean.sql

