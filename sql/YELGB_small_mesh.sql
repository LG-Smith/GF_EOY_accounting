--small mesh YELGB sub-ACL
    SELECT stock_id, negear, vtr_mesh, mesh_cat, SUM(livlb), COUNT(DISTINCT camsid), 'LAND' source
    FROM    (
        SELECT l.camsid, l.date_trip, s.permit, apsd.get_gf_fy(l.date_trip) AS fy
            , s.area, s.negear, s.vtr_mesh, s.mesh_cat, l.itis_tsn, l.itis_group1, g.fishery_group
            , apsd.get_stock_id_itis(l.itis_tsn, s.area) AS stock_id
            , l.livlb
        FROM    XCAMS_LAND l, XCAMS_SUBTRIP s, XCAMS_FISHERY_GROUP g
        where   l.camsid = s.camsid
        and     l.subtrip = s.subtrip
        and     l.camsid = g.camsid
        and     l.subtrip = g.subtrip
        and     trunc(l.date_trip) between XSTART_DATE and XEND_DATE
        AND     g.fishery_group NOT IN ('GROUND','GROUND_ASSUMED','PCHARTER','STATE','NAFO','OUTSIDE','SCALLOP')
        AND     apsd.get_stock_id_itis(l.itis_tsn, s.area) = 'YELGB'
        AND     s.negear IN ('050','054','059','150','350')
        AND     (s.vtr_mesh < 5 OR s.mesh_cat = 'SM')
        AND     l.livlb > 0
    )
    WHERE   stock_id = 'YELGB'
    GROUP BY stock_id, negear, vtr_mesh, mesh_cat
    UNION ALL
    SELECT stock_id, negear, vtr_mesh, mesh_cat, SUM(cams_discard), COUNT(DISTINCT camsid), 'DISCARD' source
    FROM    (
        SELECT l.camsid, l.date_trip, s.permit, apsd.get_gf_fy(l.date_trip) AS fy
            , s.area, s.negear, s.vtr_mesh, s.mesh_cat, l.itis_tsn, 'YELLOWTAIL' AS common_name, g.fishery_group
            , apsd.get_stock_id_itis(l.itis_tsn, s.area) AS stock_id
            , l.cams_discard
        FROM    XCAMS_DISCARD l, XCAMS_SUBTRIP s, XCAMS_FISHERY_GROUP g
        where   l.camsid = s.camsid
        and     l.subtrip = s.subtrip
        and     l.camsid = g.camsid
        and     l.subtrip = g.subtrip
        and     trunc(l.date_trip) between XSTART_DATE and XEND_DATE
        AND     g.fishery_group NOT IN ('GROUND','GROUND_ASSUMED','PCHARTER','STATE','NAFO','OUTSIDE','SCALLOP')
        AND     apsd.get_stock_id_itis(l.itis_tsn, s.area) = 'YELGB'
        AND     s.negear IN ('050','054','059','150','350')
        AND     (s.vtr_mesh < 5 OR s.mesh_cat = 'SM')
        AND     l.cams_discard > 0
    )
    WHERE   stock_id = 'YELGB'
    GROUP BY stock_id, negear, vtr_mesh, mesh_cat
