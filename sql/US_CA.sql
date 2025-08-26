--US/Canada catch
    --paste into Excel, US_Canada_Data
    --note need to use frozen FY23 commercial gf data
SELECT sector_group, stock_id, apsd.get_stock_name(stock_id) AS stock, kept_mt, catch_mt, discard_mt, catch, week_end
    , apsd.get_stock_sort_order_fnc(stock_id) AS ye_sort_order, date_run
    , trips, min_camsid, max_camsid
FROM    (
SELECT CASE WHEN TO_NUMBER(sectid) = 2 THEN 'COMMON_POOL'
            WHEN TO_NUMBER(sectid) > 2 THEN 'SECTOR'
            ELSE 'ERROR'
        END AS sector_group
    , stock_id
    , SUM(kept)/2204.62262 AS kept_mt
    , SUM(kept + discard)/2204.62262 AS catch_mt
    , SUM(discard)/2204.62262 AS discard_mt
    , SUM(kept + discard) AS catch
    , MAX(date_trip) AS week_end, MIN(date_run) AS date_run
    , count(distinct camsid) AS trips, min(camsid) AS min_camsid, max(camsid) AS max_camsid
FROM    (
    --landings
        SELECT l.camsid, s.sectid, apsd.get_stock_id_itis(l.itis_tsn, s.area) as stock_id
            , TRUNC(l.date_trip) as date_trip, livlb AS kept, 0 AS discard, 'LAND' AS source, l.date_run
        FROM    XCAMS_LAND l, XCAMS_SUBTRIP s
        WHERE   l.camsid = s.camsid
        AND     l.subtrip = s.subtrip
        AND     TRUNC(l.date_trip) BETWEEN XSTART_DATE AND XEND_DATE
        AND     s.gf = '1'
        AND     l.itis_tsn IN ('164712','164744','172909')
        AND STATUS <> 'VTR_DISCARD'
    --landings
    UNION ALL
    --discards
        SELECT l.camsid, s.sectid, apsd.get_stock_id_itis(l.itis_tsn, s.area) as stock_id
            , TRUNC(l.date_trip) as date_trip, 0 AS kept, cams_discard AS discard, 'DISCARD' AS source, l.date_run
        FROM    XCAMS_DISCARD l, XCAMS_SUBTRIP s
        WHERE   l.camsid = s.camsid
        AND     l.subtrip = s.subtrip
        AND     TRUNC(l.date_trip) BETWEEN XSTART_DATE AND XEND_DATE
        AND     s.gf = '1'
        AND     l.itis_tsn IN ('164712','164744','172909')
    --discards
)
GROUP BY GROUPING SETS ((
    CASE WHEN TO_NUMBER(sectid) = 2 THEN 'COMMON_POOL'
            WHEN TO_NUMBER(sectid) > 2 THEN 'SECTOR'
            ELSE 'ERROR'
        END
    , stock_id), (stock_id))
)
WHERE   stock_id IN ('CODGBE','HADGBE')  --YELGB uses total commercial catch
ORDER BY NVL(sector_group,'AAA') DESC, ye_sort_order
