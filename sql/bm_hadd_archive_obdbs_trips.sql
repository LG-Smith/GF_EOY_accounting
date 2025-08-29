INSERT /*+ APPEND*/ INTO hadd_obdbs_trips_arch
WITH tstamp AS(
SELECT
  TO_NUMBER(TO_CHAR(SYSDATE,'YYYYMMDDHH24MI')) load_id
  ,SYSDATE run_time
FROM
  dual
)
SELECT
  ts.load_id
  ,t1.link1
  ,t1.permit
  ,t1.hullnum
  --,t1.tripid
  ,t1.tripext
  ,t1.year
  ,t1.fishing_year
  ,t1.dateland
  --,t1.targspec1
  ,t1.link3
  ,t1.obs_gear
  ,t1.obsrflag
  ,t1.obs_area
  --,t1.lathbeg
  --,t1.lonhbeg
  --,t1.lathend
  --,t1.lonhend
  ,t1.nespp4
  ,t1.catdisp
  --,t1.drflag
  ,t1.hailwt
  ,t1.livewt
  ,t1.source
 --, t1.*
  ,'&report_type' report_type
  ,ts.run_time
  ,'&comments' comments
FROM
  hadd_obdbs_trips t1
  ,tstamp ts
