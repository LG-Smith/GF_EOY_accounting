--PULL CAMS data and estimate Haddock bycatch based on bycatch ratio

INSERT /*+ APPEND*/ INTO  hadd_cams_kall_gb
WITH assumed_rate AS( ---prior year discard rate
SELECT
  NVL(SUM(kept_hadd)/SUM(kall),0) assumed_kept_hadd_ratio
  ,NVL(SUM(discard_hadd)/SUM(kall),0) assumed_discard_hadd_ratio
  ,NVL(SUM(bycatch_hadd)/SUM(kall),0) assumed_bycatch_hadd_ratio
FROM
  (select * from hadd_obdbs_gb where fishing_year = &fy-1)
),hadd_ratio AS(
SELECT
  get_transition_rate(obs_trips,assumed_kept_hadd_ratio,inseason_kept_hadd_ratio) kept_hadd_ratio
  ,get_transition_rate(obs_trips,assumed_discard_hadd_ratio,inseason_discard_hadd_ratio) discard_hadd_ratio
  ,get_transition_rate(obs_trips,assumed_bycatch_hadd_ratio,inseason_bycatch_hadd_ratio) bycatch_hadd_ratio
FROM( --current year discard rate
  SELECT
    COUNT(distinct vtrserno) obs_trips -- AWA 11.02.21 changed from link1 to vtrserno
    ,SUM(kept_hadd)/SUM(kall) inseason_kept_hadd_ratio
    ,SUM(discard_hadd)/SUM(kall) inseason_discard_hadd_ratio
    ,SUM(bycatch_hadd)/SUM(kall) inseason_bycatch_hadd_ratio
  FROM
    hadd_obdbs_gb
WHERE
  fishing_year = &fy  --ADDED THIS LINE OF CODE ON 7/20/2015 to separate observed inseason trips
)
,assumed_rate
), land_plus_disc as(
SELECT
   get_gf_fy(cl.date_trip) fishing_year
  ,get_gf_fy(cl.date_trip)||'_'||cl.camsid id
  --,TO_CHAR(das_id ) das_id
  --,activity_code
  --,fishery_group
  ,permit
  ,TRUNC(date_trip) date_land
  ,area
  ,SUM(lndlb) cams_kall
  ,hd.discard_hadd_ratio
  ,hd.kept_hadd_ratio
  ,hd.bycatch_hadd_ratio
  ,SUM(lndlb)*hd.discard_hadd_ratio est_discard_hadd
  ,SUM(lndlb)*hd.kept_hadd_ratio est_kept_hadd
  ,SUM(lndlb)*hd.bycatch_hadd_ratio est_bycatch_hadd
  ,vtrserno -- AWA 11.02.21
FROM
  cams_garfo.cams_land cl
  ,hadd_ratio hd
WHERE
  EXISTS( select 'x' from permit.vps_fishery_ner vfn where vfn.vp_num = cl.permit and plan = 'HRG' and ap_year = get_gf_fy(cl.date_trip)) --only include valid permits
AND get_gf_fy(cl.date_trip) = &fy
AND area IN(521, 522, 525, 526, 561, 562)  --GB
AND negear IN ('170', '370')
----and activity_code not like '%%%-%%%-%%%%R%'  --***Need to exclude RSA trips***--
GROUP BY
    get_gf_fy(cl.date_trip)
   ,get_gf_fy(cl.date_trip)||'_'||cl.camsid
  --,TO_CHAR(das_id)
  --,activity_code
  --,fishery_group
  ,permit
  ,TRUNC(date_trip)
  ,hd.discard_hadd_ratio
  ,hd.kept_hadd_ratio
  ,hd.bycatch_hadd_ratio
  ,area
  ,vtrserno -- AWA 11.02.21
    order by permit,date_land)
select * from land_plus_disc
UNION ALL --- add vtr orphans
SELECT
   get_gf_fy(co.date_trip) fishing_year
  ,get_gf_fy(co.date_trip)||'_'||co.camsid id
  --,TO_CHAR(das_id ) das_id
  --,activity_code
  --,fishery_group
  ,permit
  ,TRUNC(date_trip) date_land
  ,area
  ,SUM(lndlb) cams_kall
  ,hd.discard_hadd_ratio
  ,hd.kept_hadd_ratio
  ,hd.bycatch_hadd_ratio
  ,SUM(lndlb)*hd.discard_hadd_ratio est_discard_hadd
  ,SUM(lndlb)*hd.kept_hadd_ratio est_kept_hadd
  ,SUM(lndlb)*hd.bycatch_hadd_ratio est_bycatch_hadd
  ,vtrserno -- AWA 11.02.21
FROM
  cams_garfo.cams_vtr_orphans co
  ,hadd_ratio hd
WHERE
  EXISTS( select 'x' from permit.vps_fishery_ner vfn where vfn.vp_num = co.permit and plan = 'HRG' and ap_year = get_gf_fy(co.date_trip)) --only include valid permits
AND get_gf_fy(co.date_trip) = &fy
AND area IN(521, 522, 525, 526, 561, 562)  --GB
AND negear IN ('170', '370')
----and activity_code not like '%%%-%%%-%%%%R%'  --***Need to exclude RSA trips***--
GROUP BY
    get_gf_fy(co.date_trip)
   ,get_gf_fy(co.date_trip)||'_'||co.camsid
  --,TO_CHAR(das_id)
  --,activity_code
  --,fishery_group
  ,permit
  ,TRUNC(date_trip)
  ,hd.discard_hadd_ratio
  ,hd.kept_hadd_ratio
  ,hd.bycatch_hadd_ratio
  ,area
  ,vtrserno -- AWA 11.02.21
