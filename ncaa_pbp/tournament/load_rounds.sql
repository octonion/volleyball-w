begin;

-- rounds

drop table if exists ncaa_pbp.rounds;

create table ncaa_pbp.rounds (
	year				integer,
	round_id			integer,
	seed				integer,
	division_id			integer,
	school_id				integer,
	team_name			text,
	bracket				int[],
	p				float,
	primary key (year,round_id,school_id)
);

copy ncaa_pbp.rounds from '/tmp/rounds.csv' with delimiter as ',' csv header quote as '"';

drop table if exists ncaa_pbp.m;

create table ncaa_pbp.m (
       school_id				integer,
       c				float,
       tof				float,
       tdf				float,
       ofd				float,
       dfd				float,
       primary key (school_id)
);

insert into ncaa_pbp.m
(school_id,c,tof,tdf,ofd,dfd)
(select
r.school_id as school_id,
--exp(i.estimate)*y.exp_factor as c,
1.0 as c,

hdof.exp_factor*h.offensive as tof,
h.defensive*hddf.exp_factor as tdf,

o.exp_factor as ofd,
d.exp_factor as dfd
from ncaa_pbp.rounds r
join ncaa_pbp._schedule_factors h
  on (h.year,h.school_id)=(r.year,r.school_id)
join ncaa_pbp.teams hd
  on (hd.year,hd.team_id)=(r.year,r.school_id)
join ncaa_pbp._factors hdof
  on (hdof.parameter,hdof.level::integer)=('o_div',hd.division)
join ncaa_pbp._factors hddf
  on (hddf.parameter,hddf.level::integer)=('d_div',hd.division)
join ncaa_pbp._factors o
  on (o.parameter,o.level)=('field','offense_home')
join ncaa_pbp._factors d
  on (d.parameter,d.level)=('field','defense_home')
--join ncaa_pbp._factors y
--  on (y.parameter,y.level)=('year',r.year::text)
--join ncaa_pbp._basic_factors i
--  on (i.factor)=('(Intercept)')

);

-- matchup probabilities

drop table if exists ncaa_pbp.matrix_p;

create table ncaa_pbp.matrix_p (
	year				integer,
	field				text,
	school_id			integer,
	opponent_id			integer,
	t_mu				float,
	team_p				float,
	o_mu				float,
	opponent_p			float,
	primary key (year,field,school_id,opponent_id)
);

insert into ncaa_pbp.matrix_p
(year,field,school_id,opponent_id,t_mu,o_mu)
(select
r1.year,
'home',
r1.school_id,
r2.school_id,
(m1.c*m1.tof*m1.ofd*m2.tdf) as t_mu,
(m1.c*m2.tof*m2.dfd*m1.tdf) as o_mu
from ncaa_pbp.rounds r1
join ncaa_pbp.rounds r2
  on ((r2.year)=(r1.year) and not((r2.school_id)=(r1.school_id)))
join ncaa_pbp.m m1
  on (m1.school_id)=(r1.school_id)
join ncaa_pbp.m m2
  on (m2.school_id)=(r2.school_id)
where
  r1.year=2016
);

insert into ncaa_pbp.matrix_p
(year,field,school_id,opponent_id,t_mu,o_mu)
(select
r1.year,
'away',
r1.school_id,
r2.school_id,
(m1.c*m1.tof*m1.dfd*m2.tdf) as t_mu,
(m1.c*m2.tof*m2.ofd*m1.tdf) as o_mu
from ncaa_pbp.rounds r1
join ncaa_pbp.rounds r2
  on ((r2.year)=(r1.year) and not((r2.school_id)=(r1.school_id)))
join ncaa_pbp.m m1
  on (m1.school_id)=(r1.school_id)
join ncaa_pbp.m m2
  on (m2.school_id)=(r2.school_id)
where
  r1.year=2016
);

insert into ncaa_pbp.matrix_p
(year,field,school_id,opponent_id,t_mu,o_mu)
(select
r1.year,
'neutral',
r1.school_id,
r2.school_id,
(m1.c*m1.tof*m2.tdf) as t_mu,
(m1.c*m2.tof*m1.tdf) as o_mu
from ncaa_pbp.rounds r1
join ncaa_pbp.rounds r2
  on ((r2.year)=(r1.year) and not((r2.school_id)=(r1.school_id)))
join ncaa_pbp.m m1
  on (m1.school_id)=(r1.school_id)
join ncaa_pbp.m m2
  on (m2.school_id)=(r2.school_id)
where
  r1.year=2016
);

update ncaa_pbp.matrix_p
set
team_p = vbp(t_mu,o_mu,'win'),
opponent_p = vbp(t_mu,o_mu,'lose');

-- Home advantage

drop table if exists ncaa_pbp.matrix_field;

create table ncaa_pbp.matrix_field (
	year				integer,
	round_id			integer,
	school_id			integer,
	school_seed			integer,
	opponent_id			integer,
	opponent_seed			integer,
	field				text,
	primary key (year,round_id,school_id,opponent_id)
);

insert into ncaa_pbp.matrix_field
(year,round_id,school_id,school_seed,opponent_id,opponent_seed,field)
(select
r1.year,
gs.round_id,
r1.school_id,
r1.seed,
r2.school_id,
r2.seed,
'neutral'
from ncaa_pbp.rounds r1
join ncaa_pbp.rounds r2
  on (r2.year=r1.year and not(r2.school_id=r1.school_id))
join (select generate_series(1, 6) round_id) gs
  on TRUE
where
  r1.year=2016
);

-- Rounds 1&2 seeds have home

update ncaa_pbp.matrix_field
set field='home'
where
    round_id in (1,2)
and school_seed is not null;

update ncaa_pbp.matrix_field
set field='away'
where
    round_id in (1,2)
and opponent_seed is not null;

-- Rounds 3&4 Kentucky has home

update ncaa_pbp.matrix_field
set field='home'
where year=2016
and round_id in (3,4)
and school_id in (334);

update ncaa_pbp.matrix_field
set field='away'
where year=2016
and round_id in (3,4)
and opponent_id in (334);

-- Rounds 3&4 Louisville has home except vs Kentucky (away),
-- Western Ky. (neutral)

update ncaa_pbp.matrix_field
set field='home'
where year=2016
and round_id in (3,4)
and school_id in (367)
and opponent_id not in (334,772);

update ncaa_pbp.matrix_field
set field='away'
where year=2016
and round_id in (3,4)
and opponent_id in (367)
and school_id not in (334,772);

-- Rounds 3&4 Western Ky. has home except vs Kentucky (away),
-- Louisville (neutral)

update ncaa_pbp.matrix_field
set field='home'
where year=2016
and round_id in (3,4)
and school_id in (772)
and opponent_id not in (334,367);

update ncaa_pbp.matrix_field
set field='away'
where year=2016
and round_id in (3,4)
and opponent_id in (772)
and school_id not in (334,367);

-- Rounds 3&4 Iowa St. has home

update ncaa_pbp.matrix_field
set field='home'
where year=2016
and round_id in (3,4)
and school_id in (311);

update ncaa_pbp.matrix_field
set field='away'
where year=2016
and round_id in (3,4)
and opponent_id in (311);

-- Rounds 3&4 San Diego has home

update ncaa_pbp.matrix_field
set field='home'
where year=2016
and round_id in (3,4)
and school_id in (627);

update ncaa_pbp.matrix_field
set field='away'
where year=2016
and round_id in (3,4)
and opponent_id in (627);

-- Rounds 3&4 Southern California has home except vs San Diego (away)

update ncaa_pbp.matrix_field
set field='home'
where year=2016
and round_id in (3,4)
and school_id in (657)
and opponent_id not in (627);

update ncaa_pbp.matrix_field
set field='away'
where year=2016
and round_id in (3,4)
and opponent_id in (657)
and school_id not in (627);

-- Rounds 3&4 Texas has home

update ncaa_pbp.matrix_field
set field='home'
where year=2016
and round_id in (3,4)
and school_id in (703);

update ncaa_pbp.matrix_field
set field='away'
where year=2016
and round_id in (3,4)
and opponent_id in (703);

-- Rounds 3&4 SMU has home except vs Texas (away)

update ncaa_pbp.matrix_field
set field='home'
where year=2016
and round_id in (3,4)
and school_id in (663)
and opponent_id not in (703);

update ncaa_pbp.matrix_field
set field='away'
where year=2016
and round_id in (3,4)
and opponent_id in (663)
and school_id not in (703);

-- Rounds 5&6 Nebraska has home

update ncaa_pbp.matrix_field
set field='home'
where year=2016
and round_id in (5,6)
and school_id in (463);

update ncaa_pbp.matrix_field
set field='away'
where year=2016
and round_id in (5,6)
and opponent_id in (463);

commit;
