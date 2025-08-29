-----------------------------
  --- Haddock catch cap for the herring fishery yearend accounting FY24 (May 1, 2024 to April 30, 2025)
--- A Asci 8/29/25
-----------------------------
  --- run Haddock in herring QM code in pull_hadd_caps.R (copy of QuotaMonitoring/code_cams/Herring/Herring_and_catch_cap_QM.R) on Prod Server

--fy = 2024
--report_type = 'YE'
--comments = 'YEAREND'
--report_week = '29-AUG-25'

--- apsd schema
SELECT
distinct load_id
,run_time
,comments
FROM
hadd_final_arch
order by run_time desc;
--  202409050836	05-SEP-24	YEAREND

--  compare run with last in season QM
select * from hadd_final_arch
where load_id in (202409050836, 202404250846);
-- copy/paste to QAQC tab
---create compare tab
-- seeing substantial differences from last inseason run...
-- 2 extra observed trip came through for April 11 (010202404W69007) and April 18 (010202404W71007)
-- last years rate was much lower (zero)

SELECT (select distinct dateland from hadd_obdbs_trips t where t.link1 = t1.link1) dateland, t1.*
  FROM hadd_obdbs_gb t1
order by fishing_year;
-- copy/paste to gb obdbs tab

SELECT (select distinct dateland from hadd_obdbs_trips t where t.link1 = t1.link1) dateland, t1.*
  FROM hadd_obdbs_gom t1
order by fishing_year;
--no inseason gom trips; using last years obs (5 trips)
-- all obs in november, this years trips all in november
-- seems reasonable to use these observations to estimate this years


-- this year's run
select *
from hadd_obdbs_trips_arch
where load_id = 202409050836;

select link1
, source
from hadd_obdbs_trips
group by link1,source;
-- one trip that was in OBPRELIM; 010202404W69007, now in OBDBS, an additional obs trip came through also

select *
from hadd_obdbs_arch
where load_id = 202409050836;

select *
from hadd_final_arch
where load_id = 202409050836
order by stock_area, calc_method desc;

select round(sum(final_bycatch_hadd)/2204.62262,2) hadd_bycatch_mt
, stock_area
from hadd_final_arch
where load_id = 202409050836
group by stock_area;

select * from hadd_final_arch order by run_time desc;


DEF comments = 'YEAREND';
DEF load_id = '202409050836';
--SELECT &load_id FROM dual;

--EDIT COMMENTS
UPDATE hadd_obdbs_trips_arch SET comments = '&comments' WHERE load_id = '&load_id';
UPDATE hadd_obdbs_arch SET comments = '&comments' WHERE load_id = '&load_id';
UPDATE hadd_cams_kall_arch SET comments = '&comments' WHERE load_id = '&load_id';
UPDATE hadd_final_arch SET comments = '&comments' WHERE load_id ='&load_id';
commit;


