--MERGE DMIS AND OBSERVER DATA BASED ON AMS MATCHING TABLE
--*NOTE:orpahned observer records (those w/o a DMIS match) do NOT get included on final hadd bycatch calculation
INSERT /*+ APPEND*/ INTO hadd_final_gom
WITH cams_frame AS (
SELECT distinct
   ck.fishing_year
  ,ck.id
  --,d.das_id
  ,substring(ck.vtrserno, 1,14) vtrserno -- AWA 10.27.21
  --,d.activity_code
  --,d.fishery_group
  ,ck.permit
  ,ck.date_land
FROM
  hadd_cams_kall_gom ck
)
--, obs_trips AS( -- AWA 11.02.21 dont need link1 to das_ID
--SELECT
--  das_id
--  ,MIN(link1) link1
--FROM
--  dmis.d_match_ams_vtr av
--  ,dmis.d_match_obs_link o
--WHERE
--  av.dmis_trip_id = o.dmis_trip_id
--AND av.das_id IS NOT NULL
--GROUP BY
--  das_id
--)
--BEGIN MAIN QUERY
--MATCHED DMIS-OBSERVER TRIPS.  USE OBSERVED HADDOCK VALUE.
SELECT
   cf.fishing_year
  ,cf.id
  --,df.das_id
  ,o.link1
  --,df.activity_code
  --,df.fishery_group
  ,to_number(cf.permit) permit
  ,cf.date_land
  ,(o.obs_area) area
  ,NULL kall
  ,NULL discard_hadd_ratio
  ,NULL kept_hadd_ratio
  ,NULL bycatch_hadd_ratio
  ,o.obs_discard_hadd final_discard_hadd
  ,o.obs_kept_hadd final_kept_hadd
  ,o.obs_bycatch_hadd final_bycatch_hadd
  ,'OBSERVED' calc_method
  ,substring(cf.vtrserno, 1,14) vtrserno -- AWA
FROM
  cams_frame cf
  --,obs_trips a -- AWA
  ,hadd_obdbs_gom o
WHERE
  --a.das_id = df.das_id AND -- AWA 11.02.21 switch to match on vtrserno
  --o.link1 = a.link1
  substring(cf.vtrserno, 1,14) = substring(o.vtrserno, 1,14)
UNION ALL
--UNMATCHED DMIS-OBSERVER TRIPS.  USE ESTIMATED HADDOCK VALUE.
SELECT
   c.fishing_year
  ,c.id
  --,d.das_id
  ,NULL link1
  --,d.activity_code
  --,d.fishery_group
  ,to_number(c.permit) permit
  ,c.date_land
  ,c.area
  ,c.cams_kall
  ,c.discard_hadd_ratio
  ,c.kept_hadd_ratio
  ,c.bycatch_hadd_ratio
  ,c.est_discard_hadd
  ,c.est_kept_hadd
  ,c.est_bycatch_hadd
  ,'ESTIMATED'
  ,substring(c.vtrserno, 1,14) vtrserno --AWA
FROM
  hadd_cams_kall_gom c
WHERE NOT EXISTS( select 'x'
                  from
                    --obs_trips a -- AWA
                    hadd_cams_kall_gom cf -- AWA
                    ,hadd_obdbs_gom o
                  where
                  substring(cf.vtrserno, 1,14) = substring(o.vtrserno, 1,14) -- AWA
                  and substring(o.vtrserno, 1,14) = substring(c.vtrserno, 1,14) -- AWA
                    --a.das_id = d.das_id AND -- AWA
                    --o.link1 = a.link1
                    )
