select
mp.field,
t1.team_name as team1,
mp.t_mu::numeric(4,3) as mu1,
t2.team_name as team2,
mp.o_mu::numeric(4,3) as mu2
from ncaa_pbp.matrix_p mp
join ncaa_pbp.teams t1
  on (mp.year,mp.school_id)=(t1.year,t1.team_id)
join ncaa_pbp.teams t2
  on (mp.year,mp.opponent_id)=(t2.year,t2.team_id)
where
  t1.team_name='Penn St.' and t2.team_name='Howard';
