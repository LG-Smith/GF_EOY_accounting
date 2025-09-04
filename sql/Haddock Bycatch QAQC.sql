-----------------------------
  --- Haddock catch cap for the herring fishery yearend accounting FY24 (May 1, 2024 to April 30, 2025)
--- A Asci 8/29/25
-----------------------------
  --- run Haddock in herring QM code in pull_hadd_caps.R (copy of QuotaMonitoring/code_cams/Herring/Herring_and_catch_cap_QM.R) on Prod Server

--fy = 2024
--report_type = 'YE'
--comments = 'YEAREND'
--report_week = '04-SEP-25'

--- apsd schema
SELECT
distinct load_id
,run_time
,comments
FROM
hadd_final_arch
order by run_time desc;
--  202509041446	04-SEP-25	YEAREND
--  202509031522	03-SEP-25	INIT YEAREND
--  202409050836	05-SEP-24	YEAREND

--  compare run with last in season QM
select * from hadd_final_arch
where load_id in (202509041446, 202505010849);
-- copy/paste to QAQC tab
---create compare tab
-- new estimates are slightly lower than last in season run for GB
-- 1 extra GB observed trip came through for Jan 7 (000202501R82001) with zero observed bycatch
-- 1 dropped trip for GOM (010202411D23018)


SELECT (select distinct dateland from hadd_obdbs_trips t where t.link1 = t1.link1) dateland, t1.*
  FROM hadd_obdbs_gb t1
order by fishing_year;
-- copy/paste to gb obdbs tab
-- 4 inseason trips with zero bycatch, transitioning with last years rate which was >0

SELECT (select distinct dateland from hadd_obdbs_trips t where t.link1 = t1.link1) dateland, t1.*
  FROM hadd_obdbs_gom t1
order by fishing_year;
-- 6 inseason trips with zero bycatch


-- this year's run
select *
from hadd_obdbs_trips_arch
where load_id = 202509041446;
and link1 in('000202501R82001', '010202501Z58001')
order by link1;

select link1
, source
from hadd_obdbs_trips
where link1 in('000202501R82001', '010202501Z58001')
group by link1,source;
-- two trips partially still in OBPRELIM...000202501R82001, 010202501Z58001
-- both in OBDBS now

--see how they look in cams = same
select *
from cams_garfo.cams_obdbs_all_years
where link1 in('000202501R82001', '010202501Z58001');
-- turns out this is an issue with a new observer process, obprelim trips were not removed after being added to obdbs
-- waited for resolution up stream


select *
from hadd_obdbs_arch
where load_id = 202509041446;

select *
from hadd_final_arch
where load_id = 202509041446
order by stock_area, calc_method desc;
-- copy/paste to hadd_final_arch

 select stock_id
, round(sum(final_discard_hadd)/2204.62262,2) hadd_discard_mt
, round(sum(final_kept_hadd)/2204.62262,2) hadd_kept_mt
, round(sum(final_bycatch_hadd)/2204.62262,2) hadd_bycatch_mt
from hadd_final_arch h
LEFT JOIN (SELECT DISTINCT area, stock_id FROM apsd.t_dc_obspeciesstockarea WHERE species_itis = 164744) st
ON h.area = st.area
where load_id = 202509041446
and fishing_year = 2024
AND report_type = 'YE'
GROUP BY stock_id;


select * from hadd_final_arch order by run_time desc;

-- AWA
DEF comments = 'YEAREND';
DEF load_id = '202509041446';
--SELECT &load_id FROM dual;

--EDIT COMMENTS
UPDATE hadd_obdbs_trips_arch SET comments = '&comments' WHERE load_id = '&load_id';
UPDATE hadd_obdbs_arch SET comments = '&comments' WHERE load_id = '&load_id';
UPDATE hadd_cams_kall_arch SET comments = '&comments' WHERE load_id = '&load_id';
UPDATE hadd_final_arch SET comments = '&comments' WHERE load_id ='&load_id';
commit;


