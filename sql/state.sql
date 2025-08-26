WITH hullids AS (
    SELECT camsid, MAX(hullid) AS hullid
    FROM    &land
    WHERE   year >= 2023
    AND     permit = '000000'
    GROUP BY camsid
),
Mass_areas AS (
    --from discussion with Mass:
        --all Mass state winter flounder trips should be in 514, except for 16.
        --CAMS is putting many of them into 538
    --rem to caveat State Table, that some data based on Mass logbook data, *not CAMS*
    SELECT  l.camsid  --, l.state, l.hullid, l.date_trip
        , MIN(CASE WHEN l.dlr_docn IN ('455921374962', '349121377671', '153721405518', '153721422214',
        '99821831871', '374821869386', '374821895428', '374821895447', '99821886746',  '374821895401',
        '374821923112', '374822017187', '374822017188', '374822017189', '374821949956', '374821977462') THEN
                        s.area
                   ELSE '514'
              END) AS area
    FROM    XCAMS_LAND l, XCAMS_SUBTRIP s, XCAMS_FISHERY_GROUP g
    where   l.camsid = s.camsid
    and     l.subtrip = s.subtrip
    and     l.camsid = g.camsid
    AND     l.subtrip = g.subtrip
    AND     l.year >= 2024
    AND     l.state = 'MA'
    AND     g.fishery_group = 'STATE'
    AND     l.itis_tsn = '172905'
    GROUP BY l.camsid
--    AND     l.hullid = 'MS1866BS'  --camsid = '000000_652109_0016_060374820408112_230606000000'
)

--Main
    SELECT fy, fishery_group, stock_id
        , SUM(CASE WHEN source = 'LANDINGS' THEN livlb ELSE 0 END)/2204.62262 AS Landings
        , SUM(CASE WHEN source = 'DISCARD' THEN livlb ELSE 0 END)/2204.62262 AS Estimated_discards
        , SUM(livlb)/2204.62262 AS Catch
        , COUNT(DISTINCT permit) AS permit_count
        , COUNT(DISTINCT camsid) AS trip_count
--        , listagg(distinct camsid, ', ' ON OVERFLOW TRUNCATE) as trips
        , listagg(distinct state, ', ' ON OVERFLOW TRUNCATE) as states
        , MIN(date_run) AS date_run
    FROM    (
        SELECT camsid, date_trip, permit, hullid, fy
            , area, negear, vtr_mesh, mesh_cat, itis_tsn, itis_group1, fishery_group
            --due to bad data in FY23. Can clean up
            , CASE WHEN camsid = '000000_546527_0016_040483521409635_240410000000' AND itis_tsn =  '172873' THEN
                        'WITGMMA'
                   ELSE apsd.get_stock_id_itis(itis_tsn, area)
              END AS stock_id
            --due to bad data in FY23. Can clean up
            , livlb, state, source, date_run
--        select count(*)  --92523
        FROM    (
            SELECT l.camsid, l.date_trip, s.permit, l.hullid
                , apsd.get_gf_fy(l.date_trip) AS fy
                , CASE WHEN ma.area IS NULL THEN s.area ELSE ma.area END AS area
                , s.negear, s.vtr_mesh, s.mesh_cat, l.itis_tsn, l.itis_group1, g.fishery_group
                , l.livlb, l.state, 'LANDINGS' AS source, l.date_run
            FROM    XCAMS_LAND l, XCAMS_SUBTRIP s, XCAMS_FISHERY_GROUP g, mass_areas ma
            where   l.camsid = s.camsid
            and     l.subtrip = s.subtrip
            and     l.camsid = g.camsid
            and     l.subtrip = g.subtrip
            AND     l.camsid = ma.camsid(+)
            and     trunc(l.date_trip) between XSTART_DATE and XEND_DATE --appears data are complete
            AND     g.fishery_group IN ('STATE')
            AND     l.itis_tsn IN ('164712','164744','172905','172873','172909','172877','164732'
                ,'166774','164727','172746','172933','630979','171341')  --from cfg_itis
            AND     l.livlb > 0
            UNION ALL
            SELECT l.camsid, l.date_trip, s.permit, h.hullid
                , apsd.get_gf_fy(l.date_trip) AS fy
                , CASE WHEN ma.area IS NULL THEN s.area ELSE ma.area END AS area
                , s.negear, s.vtr_mesh, s.mesh_cat, l.itis_tsn, l.common_name, g.fishery_group
                , l.cams_discard AS livlb, p.state_abb AS state, 'DISCARD' AS source, l.date_run
--            select * --count(distinct p.state_abb)
            FROM    XCAMS_DISCARD l, XCAMS_SUBTRIP s, XCAMS_FISHERY_GROUP g, hullids h, mass_areas ma
                , (SELECT DISTINCT state_abb, port_grp FROM cams_garfo.cfg_port) p
            where   l.camsid = s.camsid
            and     l.subtrip = s.subtrip
            and     l.camsid = g.camsid
            and     l.subtrip = g.subtrip
            AND     l.camsid = h.camsid(+)
            AND     l.camsid = ma.camsid(+)
            AND     s.main_port_grp = p.port_grp(+)
            and     trunc(l.date_trip) between XSTART_DATE and XEND_DATE
            AND     g.fishery_group IN ('STATE')
            AND     l.itis_tsn IN ('164712','164744','172905','172873','172909','172877','164732'
                ,'166774','164727','172746','172933','630979','171341')  --from cfg_itis
            AND     l.cams_discard > 0
        )
    )
    GROUP BY fy, stock_id, fishery_group
    ORDER BY fy, apsd.get_stock_sort_order_fnc(stock_id);
