#!/usr/bin/python3

import sys
import csv
import datetime
import psycopg2

from scipy.special import comb

try:
    conn = psycopg2.connect("dbname='volleyball-w'")
except:
    print("Can't connect to database.")
    sys.exit()

today = datetime.datetime.now()
start = today.strftime("%F")
end = today + datetime.timedelta(days=6)

select = """
select
ts.game_date,
(case when ts.neutral_site then 'Neutral'
      when not(ts.neutral_site) and ts.home_game then 'Home'
      when not(ts.neutral_site) and not(ts.home_game) then 'Away'
end),
t.team_name,
'D'||t.division as t_div,
(tf.exp_factor*td.exp_factor*sft.offensive),
o.team_name,
'D'||o.division as o_div,
(of.exp_factor*od.exp_factor*sfo.offensive)
--ts.neutral_site,
--ts.home_game,
--tf.exp_factor,
--of.exp_factor
from ncaa_pbp.team_schedules ts
join ncaa_pbp.teams t
  on (t.team_id,t.year)=(ts.team_id,ts.year)
join ncaa_pbp._schedule_factors sft
  on (sft.school_id,sft.year)=(ts.team_id,ts.year)
join ncaa_pbp._factors td
  on (td.parameter,td.level::integer)=('o_div',t.division)
join ncaa_pbp.teams o
  on (o.team_name,o.year)=(ts.opponent_name,ts.year)
join ncaa_pbp._schedule_factors sfo
  on (sfo.school_id,sfo.year)=(o.team_id,o.year)
join ncaa_pbp._factors od
  on (od.parameter,od.level::integer)=('o_div',o.division)
join ncaa_pbp._factors tf on
tf.level=
(case when ts.neutral_site then 'neutral'
      when not(ts.neutral_site) and ts.home_game then 'offense_home'
      when not(ts.neutral_site) and not(ts.home_game) then 'defense_home'
end)
join ncaa_pbp._factors of on
of.level=
(case when ts.neutral_site then 'neutral'
      when not(ts.neutral_site) and ts.home_game then 'defense_home'
      when not(ts.neutral_site) and not(ts.home_game) then 'offense_home'
end)
where ts.game_date between current_date and current_date+6
and t.team_name < o.team_name
order by ts.team_name asc,ts.game_date asc
;
"""

cur = conn.cursor()
cur.execute(select)

rows = cur.fetchall()

csvfile = open('predict_weekly.csv', 'w', newline='')
predict = csv.writer(csvfile)

header = ["game_date","site","team","tdiv","opponent","odiv","win","lose",
          "w3","w4","w5","l3","l4","l5"]
predict.writerow(header)

for row in rows:
    
    game_date = row[0]
    site = row[1]
    team = row[2]
    tdiv = row[3]
    to = row[4]
    opponent = row[5]
    odiv = row[6]
    oo = row[7]

    r = to/oo

    p = r/(1+r)
    q = 1-p

    w25 = 0.0

    for i in range(0, 24):
        w25 = w25 + comb(24+i, i)*p**24*q**i*p

    tie = comb(48, 24)*p**24*q**24

    w25 = w25 + tie*p**2/(1-2*p*q)

    w15 = 0.0

    for i in range(0, 14):
        w15 = w15 + comb(14+i, i)*p**14*q**i*p

    tie = comb(28, 14)*p**14*q**14

    w15 = w15 + tie*p**2/(1-2*p*q)

    win = w25**3 + comb(3, 1)*w25**3*(1-w25) + comb(4, 2)*w25**2*(1-w25)**2*w15
    lose = 1-win

    win = "%4.3f" % win
    lose = "%4.3f" % lose

    w3 = "%4.3f" % (w25**3)
    w4 = "%4.3f" % (comb(3, 1)*w25**3*(1-w25))
    w5 = "%4.3f" % (comb(4, 2)*w25**2*(1-w25)**2*w15)

    l25 = 1.0-w25
    l15 = 1.0-w15

    l3 = "%4.3f" % (l25**3)
    l4 = "%4.3f" % (comb(3, 1)*l25**3*(1-l25))
    l5 = "%4.3f" % (comb(4, 2)*l25**2*(1-l25)**2*l15)
    data = [game_date,site,team,tdiv,opponent,odiv,win,lose,w3,w4,w5,l3,l4,l5]
    predict.writerow(data)

csvfile.close()
