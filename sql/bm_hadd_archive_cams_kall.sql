INSERT /*+ APPEND*/ INTO hadd_cams_kall_arch
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
  ,t1.id
  --,t1.das_id
  --,t1.activity_code
  --,t1.fishery_group
  ,t1.permit
  ,t1.date_land
  ,t1.area
  ,t1.cams_kall
  ,t1.discard_hadd_ratio
  ,t1.kept_hadd_ratio
  ,t1.bycatch_hadd_ratio
  ,t1.est_discard_hadd
  ,t1.est_kept_hadd
  ,t1.est_bycatch_hadd
 --, t1.*
 ,'GB' stock_area
  ,'&report_type' report_type
  ,ts.run_time
  ,'&comments' comments
FROM
  hadd_cams_kall_gb t1
  ,tstamp ts
UNION ALL
  SELECT
  ts.load_id
  ,t1.fishing_year
  ,t1.id
  --,t1.das_id
  --,t1.activity_code
  --,t1.fishery_group
  ,t1.permit
  ,t1.date_land
  ,t1.area
  ,t1.cams_kall
  ,t1.discard_hadd_ratio
  ,t1.kept_hadd_ratio
  ,t1.bycatch_hadd_ratio
  ,t1.est_discard_hadd
  ,t1.est_kept_hadd
  ,t1.est_bycatch_hadd
 --, t1.*
 ,'GOM' stock_area
  ,'&report_type' report_type
  ,ts.run_time
  ,'&comments' comments
FROM
  hadd_cams_kall_gom t1
  ,tstamp ts