--othersub landings *********************************************************************************************************
    --check total lbs against UNION query
SELECT stock_id  --, apsd.get_stock_name(stock_id) AS stock
    , SCALLOP, FLUKE, HAGFISH, HERRING, "LOBSTER/CRAB", MACKEREL, MENHADEN, MONKFISH, REDCRAB, RESEARCH
    , SCUP, SHRIMP, SQUID, "SQUID/WHITING",	"SURF CLAM", "WHELK/CONCH", WHITING, UNCATEGORIZED, ye_sort_order, sysdate
    , NVL(fy,2023) AS fy
FROM   (
--fix GBEs and pad out missing stocks
SELECT *
FROM   (
--pivot FMPs
WITH pivot_data AS (
    SELECT fy, stock_id, fishery_group, sum(livlb) AS livlb
--        , count(distinct permit) AS permit_count
--        , COUNT(DISTINCT camsid) AS trip_count
--        , sum(livlb_old) AS livlb_old
--        , listagg(distinct camsid, ', ' ON OVERFLOW TRUNCATE) as trips
    FROM    (
    SELECT camsid, date_trip, permit, fy, itis_tsn, itis_group1, fishery_group
        , DECODE(stock_id,'CODGBE','CODGB','CODGBW','CODGB','HADGBE','HADGB','HADGBW','HADGB',stock_id) AS stock_id
        , livlb AS livlb_old
        , CASE WHEN stock_id IN ('HADGBE','HADGBW','HADGB','HADGM')
                    AND fishery_group = 'HERRING'
                    AND negear IN ('170','370')
                    AND (area in (521,522,525,526,561,562) OR area < 520)
               THEN 0  --this goes into the haddock/herring sub-ACL
               WHEN stock_id = 'YELGB'
                    AND negear IN ('050','054','059','150','350')
                    AND (vtr_mesh < 5 OR mesh_cat = 'SM')
               THEN 0  --this goes into the YELGB small mesh sub-ACL
               ELSE livlb
            END AS livlb
    FROM    (
--    select fishery_group, count(*), sum(livlb)
--    from    (
        --982 records
        SELECT l.camsid, l.date_trip, s.permit, apsd.get_gf_fy(l.date_trip) AS fy
            , s.area, s.negear, s.vtr_mesh, s.mesh_cat, l.itis_tsn, l.itis_group1, g.fishery_group
            , apsd.get_stock_id_itis(l.itis_tsn, s.area) AS stock_id
            , l.livlb
        FROM     XCAMS_LAND l, XCAMS_SUBTRIP s, XCAMS_FISHERY_GROUP g
        where   l.camsid = s.camsid
        and     l.subtrip = s.subtrip
        and     l.camsid = g.camsid
        and     l.subtrip = g.subtrip
        and     trunc(l.date_trip) between XSTART_DATE and XEND_DATE
        AND     g.fishery_group NOT IN ('GROUND','GROUND_ASSUMED','PCHARTER','STATE','NAFO','OUTSIDE','SCALLOP')
        AND     l.itis_tsn IN ('164712','164744','172905','172873','172909','172877','164732'
            ,'166774','164727','172746','172933','630979','171341')  --from cfg_itis
        AND     l.livlb > 0
        UNION ALL
        --just append the scallop bycatches
        SELECT l.camsid, l.date_trip, s.permit, apsd.get_scal_fy(l.date_trip) AS scal_fy
            , s.area, s.negear, s.vtr_mesh, s.mesh_cat, l.itis_tsn, l.itis_group1, g.fishery_group
            , apsd.get_stock_id_itis(l.itis_tsn, s.area) AS stock_id
            , l.livlb
        FROM     XCAMS_LAND l, XCAMS_SUBTRIP s, XCAMS_FISHERY_GROUP g
        where   l.camsid = s.camsid
        and     l.subtrip = s.subtrip
        and     l.camsid = g.camsid
        and     l.subtrip = g.subtrip
        and     trunc(l.date_trip) between XSCAL_START_DATE and XSCAL_END_DATE
        AND     g.fishery_group = 'SCALLOP'
        AND     l.itis_tsn IN ('164712','164744','172905','172873','172909','172877','164732'
            ,'166774','164727','172746','172933','630979','171341')  --from cfg_itis
        AND     l.livlb > 0
--    )
--    group by fishery_group
    )
    )
    GROUP BY fy, stock_id, fishery_group
--    order by stock_id
)

--Main
  SELECT *
  FROM   pivot_data
  PIVOT (
         SUM(livlb/2204.62262)        --<-- pivot_clause
         FOR fishery_group      --<-- pivot_for_clause
		 IN (  			   		--<-- pivot_in_clause
		 	'SCALLOP'	AS	SCALLOP,
		 	'FLUKE'		AS	FLUKE,
			'HAGFISH'	AS	HAGFISH,
			'HERRING'	AS	HERRING,
			'LOBSTER/CRAB' as "LOBSTER/CRAB",
			'MACKEREL'	AS	MACKEREL,
			'MENHADEN'	AS	MENHADEN,
			'MONKFISH'	AS	MONKFISH,
			'REDCRAB'	AS	REDCRAB,
			'RESEARCH'	AS	RESEARCH,
			'SCUP'		AS	SCUP,
			'SHRIMP'	AS	SHRIMP,
			'SQUID'		AS	SQUID,
			'SQUID/WHITING' as "SQUID/WHITING",
			'SURF CLAM'	AS	"SURF CLAM",
			'TILEFISH'	AS	TILEFISH,
			'WHELK/CONCH' as "WHELK/CONCH",
			'WHITING'	AS	WHITING,
			'UNCATEGORIZED'	AS	UNCATEGORIZED
		 )
        )
--pivot FMPs
) right outer JOIN (
   SELECT stock_id, MAX(ye_sort_order) AS ye_sort_order
   FROM (
      SELECT CASE WHEN STOCK_ID IN ('CODGBE','CODGBW') THEN
                        'CODGB'
                   WHEN STOCK_ID IN ('HADGBE','HADGBW') THEN
                        'HADGB'
                   ELSE stock_id
              END AS stock_id, apsd.get_stock_sort_order_fnc(stock_id) as ye_sort_order
      FROM	  apsd.t_dc_obspeciesstockarea
      WHERE   stock_id NOT LIKE '%UNKNOWN%'
      AND     stock_id <> 'OTHER'
      AND     fmp = 'MUL'
      AND     fishery = 'LM')
   GROUP BY stock_id)
USING(stock_id)
--fix GBEs and pad out missing stocks
)
ORDER BY ye_sort_order, NVL(fy,0)
