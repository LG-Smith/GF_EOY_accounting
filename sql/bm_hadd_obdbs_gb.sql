
--------------------------------------------------------------------------------
--GEORGES BANK (GB)
--------------------------------------------------------------------------------

INSERT INTO hadd_obdbs_gb
SELECT
  fishing_year
  ,permit
  ,link1
  ,obs_area
  ,discard_hadd
  ,kept_hadd
  ,bycatch_hadd
  ,kall
  ,unob_kall
  ,trip_kall
  ,discard_hadd+((trip_discard_hadd/trip_kall)*unob_kall) obs_discard_hadd
  ,kept_hadd+((trip_kept_hadd/trip_kall)*unob_kall) obs_kept_hadd
  ,bycatch_hadd+((trip_bycatch_hadd/trip_kall)*unob_kall) obs_bycatch_hadd
  ,substring(vtrserno, 1,14) vtrserno -- AWA added 11.02.21
FROM(
  SELECT
    fishing_year
    ,permit
    ,link1
    ,obs_area
    ,discard_hadd
    ,kept_hadd
    ,bycatch_hadd
    ,kall
    ,unob_kall
    ,SUM(kall) OVER(PARTITION BY vtrserno) trip_kall -- AWA changed from link1 to vtrserno 11.02.21
    ,SUM(discard_hadd) OVER(PARTITION BY vtrserno) trip_discard_hadd -- AWA changed from link1 to vtrserno 11.02.21
    ,SUM(kept_hadd) OVER(PARTITION BY vtrserno) trip_kept_hadd -- AWA changed from link1 to vtrserno 11.02.21
    ,SUM(bycatch_hadd) OVER(PARTITION BY vtrserno) trip_bycatch_hadd -- AWA changed from link1 to vtrserno 11.02.21
    ,substring(vtrserno, 1,14) vtrserno -- AWA added 11.02.21
  FROM(
    SELECT
      permit
      ,link1
      ,fishing_year
      ,obs_area
      ,SUM(CASE WHEN obsrflag = 1 AND catdisp = 0 AND substr(nespp4,1,3) = 147 THEN a.livewt ELSE 0 END) discard_hadd
      ,SUM(CASE WHEN obsrflag = 1 AND catdisp = 1 AND substr(nespp4,1,3) = 147 THEN a.livewt ELSE 0 END) kept_hadd
      ,SUM(CASE WHEN obsrflag = 1 AND catdisp <> 9 AND substr(nespp4,1,3) = 147 THEN a.livewt ELSE 0 END) bycatch_hadd
      ,SUM(CASE WHEN obsrflag = 1 THEN a.livewt ELSE 0 END) kall
      ,SUM(CASE WHEN obsrflag = 0 THEN a.livewt ELSE 0 END) unob_kall
      ,substring(vtrserno, 1,14) vtrserno -- AWA added 11.02.21
    FROM
      hadd_obdbs_trips a
    WHERE
      obs_gear IN (170, 370)
--    AND a.fishing_year = &fy
    AND obs_area IN(521, 522, 525, 526, 561, 562)  --GB
    AND EXISTS( select 'x' from permit.vps_fishery_ner vfn where vfn.vp_num = a.permit and plan = 'HRG' and ap_year = a.fishing_year) --only include valid permits
    GROUP BY
      permit
      ,link1
      ,fishing_year
      ,obs_area
      ,substring(vtrserno, 1,14) -- AWA added 11.02.21
    HAVING(
      SUM(CASE WHEN obsrflag = 1 AND catdisp <> 9 AND substr(nespp4,1,3) = 147 THEN a.livewt ELSE 0 END) > 0
      OR SUM(CASE WHEN obsrflag = 1 AND catdisp = 1 THEN a.livewt ELSE 0 END) > 0
      OR SUM(CASE WHEN obsrflag = 0 AND catdisp = 1 THEN a.livewt ELSE 0 END) > 0
      )
  )
)
WHERE
  trip_kall >0  --omit Observer trips where no kall was observed for the trip.  treat these as unobserved trips.
ORDER BY
  fishing_year,permit
