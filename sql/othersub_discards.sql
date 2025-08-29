SELECT stock_id
    , SCALLOP, FLUKE, HAGFISH, HERRING, 0 AS "LOBSTER/CRAB", MACKEREL, MENHADEN, MONKFISH, REDCRAB
    , 0 AS RESEARCH, SCUP, SHRIMP, SQUID, "SQUID/WHITING", "SURF CLAM",	"WHELK/CONCH", WHITING, UNCATEGORIZED
    , ye_sort_order, sysdate, fy
FROM   (
--fix GBEs and pad out missing stocks
SELECT *
FROM   (
--pivot FMPs
WITH pivot_data AS (
    SELECT fy, stock_id, fishery_group, sum(livlb) AS livlb
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
                    AND (area in (521,522,525,526,561,562) OR area < 520) THEN
                    0  --this goes into the haddock/herring sub-ACL
               WHEN stock_id = 'YELGB'
                    AND negear IN ('050','054','059','150','350','360')
                    AND (vtr_mesh < 5 OR mesh_cat = 'SM') THEN
                    0  --this goes into the YELGB small mesh sub-ACL
               WHEN fishery_group = 'SCALLOP' AND stock_id IN ('YELGB','YELSNE','FLGMGBSS','FLDSNEMA') THEN
                    0  --scallop bycatch sub-ACLs. should this be dredge only?
               ELSE livlb
            END AS livlb
    FROM    (
            SELECT l.camsid, l.date_trip, s.permit, apsd.get_gf_fy(l.date_trip) AS fy
                , s.area, s.negear, s.vtr_mesh, s.mesh_cat, l.itis_tsn, it.itis_group1, g.fishery_group
                , apsd.get_stock_id_itis(l.itis_tsn, s.area) AS stock_id
                , l.cams_discard AS livlb
            FROM    XCAMS_DISCARD l, XCAMS_SUBTRIP s, XCAMS_FISHERY_GROUP g, cams_garfo.cfg_itis it
            WHERE   l.camsid = s.camsid
            and     l.itis_tsn = it.itis_tsn
            and     l.subtrip = s.subtrip
            and     l.camsid = g.camsid
            and     l.subtrip = g.subtrip
            and     trunc(l.date_trip) between XSTART_DATE and XEND_DATE
            AND     g.fishery_group NOT IN ('GROUND','GROUND_ASSUMED','PCHARTER','STATE','NAFO','OUTSIDE','SCALLOP')
            AND     l.itis_tsn IN ('164712','164744','172905','172873','172909','172877','164732'
                ,'166774','164727','172746','172933','630979','171341')  --from cfg_itis
            AND     l.cams_discard > 0
            UNION ALL
        --just append the scallop bycatches
            SELECT l.camsid, l.date_trip, s.permit, apsd.get_scal_fy(l.date_trip) AS scal_fy
                , s.area, s.negear, s.vtr_mesh, s.mesh_cat, l.itis_tsn, it.itis_group1, g.fishery_group
                , apsd.get_stock_id_itis(l.itis_tsn, s.area) AS stock_id,
                l.cams_discard AS livlb
            FROM    XCAMS_DISCARD l, XCAMS_SUBTRIP s, XCAMS_FISHERY_GROUP g, cams_garfo.cfg_itis it
            WHERE   l.camsid = s.camsid
            and     l.itis_tsn = it.itis_tsn
            AND     l.subtrip = s.subtrip
            AND     l.camsid = g.camsid
            and     l.subtrip = g.subtrip
            and     trunc(l.date_trip) between XSCAL_START_DATE and XSCAL_END_DATE
            AND     g.fishery_group = 'SCALLOP'
            AND     l.itis_tsn IN ('164712','164744','172905','172873','172909','172877','164732'
                ,'166774','164727','172746','172933','630979','171341')  --from cfg_itis
            AND     l.cams_discard > 0
--        )
    )
    )
    GROUP BY fy, stock_id, fishery_group
--    order by fy, stock_id
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
			'LOBSTER/CRAB' AS "LOBSTER/CRAB",
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
) RIGHT OUTER JOIN (
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
      AND     fishery = 'LM'
    )
    GROUP BY stock_id
)
USING(stock_id)
--fix GBEs and pad out missing stocks
)
ORDER BY ye_sort_order, fy
