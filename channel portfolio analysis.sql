-- 1. Weekly Trended Sessions for New Paid Search Channel (bsearch) vs GSearch (nonbrand)
SELECT
    DATE_SUB(DATE(created_at), INTERVAL WEEKDAY(DATE(created_at)) DAY) AS start_of_week,
    COUNT(DISTINCT CASE 
        WHEN utm_source = 'gsearch' AND utm_campaign = 'nonbrand' THEN website_session_id
        ELSE NULL 
    END) AS gsearch_sessions,
    COUNT(DISTINCT CASE 
        WHEN utm_source = 'bsearch' THEN website_session_id 
        ELSE NULL 
    END) AS bsearch_sessions
FROM website_sessions
WHERE created_at > '2012-08-22' 
    AND created_at < '2012-11-29'
GROUP BY start_of_week;


-- 2. Compare Channel Characteristics (Mobile Sessions for BSearch vs GSearch)
SELECT
    utm_source,
    COUNT(DISTINCT website_session_id) AS sessions,
    COUNT(DISTINCT CASE 
        WHEN device_type = 'mobile' THEN website_session_id 
        ELSE NULL 
    END) AS mobile_sessions,
    COUNT(DISTINCT CASE 
        WHEN device_type = 'mobile' THEN website_session_id 
        ELSE NULL 
    END) / COUNT(DISTINCT website_session_id) AS pct_mobile_sessions
FROM website_sessions
WHERE created_at > '2012-08-22' 
    AND created_at < '2012-11-30'
    AND utm_campaign = 'nonbrand'
    AND utm_source IN ('gsearch', 'bsearch')
GROUP BY utm_source;


-- 3. Cross-Channel Bid Optimization (Nonbrand Session to Order Conversion Rate for GSearch and BSearch, Sliced by Device)
SELECT
    ws.device_type,
    ws.utm_source, 
    COUNT(DISTINCT ws.website_session_id) AS sessions,
    COUNT(DISTINCT odr.order_id) AS orders,
    COUNT(DISTINCT odr.order_id) / COUNT(DISTINCT ws.website_session_id) AS cnv_rate
FROM website_sessions ws
LEFT JOIN orders odr ON ws.website_session_id = odr.website_session_id 
WHERE ws.utm_campaign = 'nonbrand'
    AND ws.created_at > '2012-08-22' 
    AND ws.created_at < '2012-09-19'
GROUP BY ws.device_type, ws.utm_source;


-- 4. Analyze Channel Portfolio Trends to See Changes After Changing Bidding
SELECT 
    DATE_SUB(DATE(created_at), INTERVAL WEEKDAY(DATE(created_at)) DAY) AS start_of_week,
    COUNT(DISTINCT CASE 
        WHEN utm_source = 'gsearch' AND device_type = 'desktop' THEN website_session_id 
        ELSE NULL 
    END) AS g_dtop_sessions,
    COUNT(DISTINCT CASE 
        WHEN utm_source = 'gsearch' AND device_type = 'mobile' THEN website_session_id 
        ELSE NULL 
    END) AS g_mobile_sessions,
    COUNT(DISTINCT CASE 
        WHEN utm_source = 'bsearch' AND device_type = 'desktop' THEN website_session_id 
        ELSE NULL 
    END) AS b_dtop_sessions,
    COUNT(DISTINCT CASE 
        WHEN utm_source = 'bsearch' AND device_type = 'mobile' THEN website_session_id 
        ELSE NULL 
    END) AS b_mobile_sessions,
    COUNT(DISTINCT CASE 
        WHEN utm_source = 'bsearch' AND device_type = 'desktop' THEN website_session_id 
        ELSE NULL 
    END) / COUNT(DISTINCT CASE 
        WHEN utm_source = 'gsearch' AND device_type = 'desktop' THEN website_session_id 
        ELSE NULL 
    END) AS b_t_g_dtop_pct,
    COUNT(DISTINCT CASE 
        WHEN utm_source = 'bsearch' AND device_type = 'mobile' THEN website_session_id 
        ELSE NULL 
    END) / COUNT(DISTINCT CASE 
        WHEN utm_source = 'gsearch' AND device_type = 'mobile' THEN website_session_id 
        ELSE NULL 
    END) AS b_t_g_mobile_pct
FROM website_sessions
WHERE created_at > '2012-11-04'
    AND created_at < '2012-12-22'
    AND utm_campaign = 'nonbrand'
GROUP BY start_of_week;
