WITH scal_frame AS (
SELECT a.stock_id, s.source
FROM (select distinct stock_id FROM apsd.t_dc_obspeciesstockarea) a
CROSS JOIN (
    SELECT 'DISCARD' AS source FROM dual
    UNION ALL
    SELECT 'LAND' AS source FROM dual) s
WHERE a.stock_id IN ('YELGB', 'YELSNE', 'FLDSNEMA', 'FLGMGBSS')
)
SELECT scal_frame.stock_id, fishery_group, sum(livlb)/2204.62262 MT, scal_frame.source
FROM (SELECT l.camsid, l.date_trip, s.permit, apsd.get_scal_fy(l.date_trip) AS scal_fy
                , s.area, s.negear, s.vtr_mesh, s.mesh_cat, l.itis_tsn, it.itis_group1, g.fishery_group
                , apsd.get_stock_id_itis(l.itis_tsn, s.area) AS stock_id,
                l.livlb, 'LAND' source
            FROM    XCAMS_LAND l, XCAMS_SUBTRIP  s, XCAMS_FISHERY_GROUP  g, cams_garfo.cfg_itis it
            WHERE   l.camsid = s.camsid
            and     l.itis_tsn = it.itis_tsn
            AND     l.subtrip = s.subtrip
            AND     l.camsid = g.camsid
            and     l.subtrip = g.subtrip
            and     trunc(l.date_trip) between XSCAL_START_DATE and XSCAL_END_DATE
            AND     g.fishery_group = 'SCALLOP'
            AND     l.itis_tsn IN ('172909','172746')  --from cfg_itis
            AND     l.livlb > 0
      UNION ALL
            SELECT l.camsid, l.date_trip, s.permit, apsd.get_scal_fy(l.date_trip) AS scal_fy
                , s.area, s.negear, s.vtr_mesh, s.mesh_cat, l.itis_tsn, it.itis_group1, g.fishery_group
                , apsd.get_stock_id_itis(l.itis_tsn, s.area) AS stock_id,
                l.cams_discard AS livlb, 'DISCARD' source
            FROM    XCAMS_DISCARD l,XCAMS_SUBTRIP  s, XCAMS_FISHERY_GROUP  g, cams_garfo.cfg_itis it
            WHERE   l.camsid = s.camsid
            and     l.itis_tsn = it.itis_tsn
            AND     l.subtrip = s.subtrip
            AND     l.camsid = g.camsid
            and     l.subtrip = g.subtrip
            and     trunc(l.date_trip) between XSCAL_START_DATE and XSCAL_END_DATE
            AND     g.fishery_group = 'SCALLOP'
            AND     l.itis_tsn IN ('172909','172746')  --from cfg_itis
            AND     l.cams_discard > 0) c
RIGHT JOIN scal_frame
ON scal_frame.stock_id = c.stock_id
AND scal_frame.source = c.source
WHERE scal_frame.stock_id IN ('YELGB', 'YELSNE', 'FLDSNEMA', 'FLGMGBSS')
group by scal_frame.stock_id, fishery_group, scal_frame.source

