INSERT /*+ APPEND*/ INTO hadd_obdbs_arch
WITH tstamp AS(
SELECT
  TO_NUMBER(TO_CHAR(SYSDATE,'YYYYMMDDHH24MI')) load_id
  ,SYSDATE run_time
FROM
  dual
)
SELECT
  ts.load_id
  ,t1.fishing_year
  ,t1.permit
  ,t1.link1
  ,t1.obs_area
  ,t1.discard_hadd
  ,t1.kept_hadd
  ,t1.bycatch_hadd
  ,t1.KALL
  ,t1.unob_kall
  ,t1.trip_kall
  ,t1.obs_discard_hadd
  ,t1.obs_kept_hadd
  ,t1.obs_bycatch_hadd
 --, t1.*
 ,'GB' stock_area
  ,'&report_type' report_type
  ,ts.run_time
  ,'&comments' comments
FROM
  hadd_obdbs_gb t1
  ,tstamp ts
UNION ALL
  SELECT
  ts.load_id
   ,t1.fishing_year
  ,t1.permit
  ,t1.link1
  ,t1.obs_area
  ,t1.discard_hadd
  ,t1.kept_hadd
  ,t1.bycatch_hadd
  ,t1.KALL
  ,t1.unob_kall
  ,t1.trip_kall
  ,t1.obs_discard_hadd
  ,t1.obs_kept_hadd
  ,t1.obs_bycatch_hadd
 --, t1.*
 ,'GOM' stock_area
  ,'&report_type' report_type
  ,ts.run_time
  ,'&comments' comments
FROM
  hadd_obdbs_gom t1
  ,tstamp ts