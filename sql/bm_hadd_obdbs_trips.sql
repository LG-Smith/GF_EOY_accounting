--OBSERVER TRIPS (comprehensive). OBDBS and OBPRELIM
-- 11.02.21 Ashley Weston Asci added Portside Sampled Data, stat area assigned from VTR
INSERT /*+ APPEND*/ INTO hadd_obdbs_trips
SELECT
  a.link1
  ,to_char(a.permit1) permit
  ,a.hullnum1 hullnum
  --,a.tripid
  ,a.tripext
  ,a.year
  ,get_gf_fy(a.dateland) fishing_year
  ,a.dateland
  --,b.targspec1
  --,b.haulnum
  ,a.link3 -- AWA instead of haulnum
  ,b.obs_gear
  ,b.obsrflag
  ,b.obs_area
  --,b.lathbeg
  --,b.lonhbeg
  --,b.lathend
  --,b.lonhend
  ,a.nespp4
  ,substring(a.fishdisp,1,1) catdisp
  --,c.drflag
  ,a.hailwt
  --,NVL(c.hailwt*cv.cf_rptqty_lndlb*cv.cf_lndlb_livlb,c.hailwt) livewt
  ,a.livewt
  ,b.source
  ,substring(b.vtrserno, 1,14) vtrserno -- AWA added 11.2.21
  ,g.herring herr_trip
FROM
 CAMS_GARFO.CAMS_OBDBS_ALL_YEARS a
 , cams_garfo.cams_obs_catch b
 ,cams_garfo.cams_fishery_group g
WHERE
  (a.link3 = b.link3 and a.nespp3 = b.nespp3 and a.fishdisp = b.fishdisp)
  and (b.cams_subtrip = (g.camsid||'_'||g.subtrip))
AND a.negear IN ('170', '370')
--AND primgear = '1'
AND substring(a.fishdisp,1,1) IS NOT NULL
--AND (d.targspec1 IN ('1685','1670', '2120') or d.targspec2 IN ('1685', '1670', '2120'))
AND get_gf_fy(a.dateland) BETWEEN  &fy-1 AND &fy
and g.herring = 1
--union all -- AWA add portside sampling data 11.02.21
--select
--null link1
--,t.permit permit
--,t.pss_hullid hullnum
----,t.pss_tripid tripid
--,t.pss_tripext tripext
--,t.pss_year year
--,get_gf_fy(t.pss_land) fishing_year
--,t.pss_land dateland
----,null targspec1
--, null link3
----,e.pss_event haulnum
--,t.pss_negear obs_gear
--,e.pss_obs_flg obsrflag
--,nvl(i.vtr_area, i.vtr_carea) area -- area from VTR
----,null lathbeg
----,null lonhbeg
----,null lathend
----,null lonhend
--,s.pss_nespp4 nespp4
--,substring(s.pss_fishdisp,1,1) catdisp
----,s.pss_drflg drflag
---,s.pss_hail hailwt
-- -- ,NVL(s.pss_hail*cv.cf_rptqty_lndlb*cv.cf_lndlb_livlb,s.pss_hail) livewt
-- , pss_hail livwt
--, 'PSS' source
--,substring(t.pss_vtr, 1,14) vtrserno --AWA added 10.26.21
--, null herr_trip
--from CAMS_GARFO.stg_pss_trp t
--, CAMS_GARFO.stg_pss_event e
--, CAMS_GARFO.stg_pss_spp s LEFT OUTER JOIN fso_admin.obdbs_obspecconv cv ON
--    ( s.pss_nespp4 = cv.nespp4_obs AND
--      substring(s.pss_fishdisp,1,1) = cv.catdisp_code AND
--      s.pss_drflg = cv.drflag_code
--    )
--,cams_garfo.stg_vtr_images i
--, cams_garfo.stg_vtr_catch c -- AWA
--where t.pss_tripid = e.pss_tripid -- match on tripid, does not have link1, or area
--and (e.pss_tripid = s.pss_tripid and e.pss_event = s.pss_event)  -- tripid and event(haul)
--and substring(t.pss_vtr,1,14) = substring(i.vtrserno, 1,14)
--and i.vtr_imgid = c.vtr_imgid -- AWA
--AND t.pss_negear in ('170', '370')
--AND substring(s.pss_fishdisp,1,1) IS NOT NULL
--AND get_gf_fy(t.pss_land) BETWEEN  &fy-1 AND &fy
--AND t.pss_prg in ('260', '270')
--and c.vtr_sppcode <> 'NC' -- AWA
