-- 1. Traffic Source Analysis

-- 1.1 Use UTM parameters to identify paid website sessions and revenue impact
SELECT 
    ws.utm_content,
    COUNT(DISTINCT ws.website_session_id) AS sessions,
    COUNT(DISTINCT od.order_id) AS orders,
    COUNT(DISTINCT od.order_id) / COUNT(DISTINCT ws.website_session_id) AS session_to_order_conv_rt
FROM website_sessions ws
LEFT JOIN orders od ON ws.website_session_id = od.website_session_id
GROUP BY ws.utm_content
ORDER BY sessions DESC;


-- 1.2 Session-to-order conversion rate for a specific campaign (gsearch, nonbrand)
SELECT 
    COUNT(DISTINCT ws.website_session_id) AS sessions, 
    COUNT(DISTINCT ord.order_id) AS orders, 
    COUNT(DISTINCT ord.order_id) / COUNT(DISTINCT ws.website_session_id) AS session_to_order_cvr
FROM website_sessions ws
LEFT JOIN orders ord ON ws.website_session_id = ord.website_session_id
WHERE ws.created_at < '2012-04-14' 
    AND ws.utm_source = 'gsearch' 
    AND ws.utm_campaign = 'nonbrand';

-- Bid Optimization and Trend Analysis

-- 1.3 Analyze weekly session trends after bid reduction
SELECT 
    MIN(DATE(created_at)) AS week_start_date,
    COUNT(DISTINCT website_session_id) AS sessions
FROM website_sessions
WHERE created_at < '2012-05-10' 
    AND utm_source = 'gsearch' 
    AND utm_campaign = 'nonbrand'
GROUP BY YEAR(created_at), WEEK(created_at)
ORDER BY week_start_date;

-- 1.4 Session-to-order CVR by device type
SELECT 
    ws.device_type,  
    COUNT(DISTINCT ws.website_session_id) AS sessions, 
    COUNT(DISTINCT ord.order_id) AS orders, 
    COUNT(DISTINCT ord.order_id) / COUNT(DISTINCT ws.website_session_id) AS session_to_order_cvr
FROM website_sessions ws
LEFT JOIN orders ord ON ws.website_session_id = ord.website_session_id
WHERE ws.created_at < '2012-05-11' 
    AND ws.utm_source = 'gsearch' 
    AND ws.utm_campaign = 'nonbrand'
GROUP BY ws.device_type;

-- Device level trend analysis for desktop and mobile sessions
SELECT 
    MIN(DATE(created_at)) AS week_start_date, 
    COUNT(CASE WHEN device_type = 'desktop' THEN 1 ELSE NULL END) AS dtop_sessions,
    COUNT(CASE WHEN device_type = 'mobile' THEN 1 ELSE NULL END) AS mob_sessions
FROM website_sessions
WHERE created_at BETWEEN '2012-04-15' AND '2012-06-09' 
    AND utm_source = 'gsearch' 
    AND utm_campaign = 'nonbrand'
GROUP BY YEAR(created_at), WEEK(created_at);

-- 2. Website Performance Analysis
-- 2.1 Most viewed website pages
SELECT 
    pageview_url,
    COUNT(DISTINCT website_pageview_id) AS sessions
FROM website_pageviews
WHERE created_at < '2012-06-09'
GROUP BY pageview_url
ORDER BY sessions DESC;

-- Identify landing pages for all sessions
CREATE TEMPORARY TABLE first_viewpage
SELECT 
    website_session_id, 
    MIN(website_pageview_id) AS landing_page
FROM website_pageviews
WHERE created_at < '2012-06-12'
GROUP BY website_session_id;

SELECT 
    wp.pageview_url AS landing_page_url, 
    COUNT(DISTINCT fv.website_session_id) AS sessions_hitting_landing_page
FROM first_viewpage fv
LEFT JOIN website_pageviews wp ON fv.landing_page = wp.website_pageview_id
GROUP BY wp.pageview_url;

-- 2.2 Home page performance and bounce rate analysis
CREATE TEMPORARY TABLE first_pageviews
SELECT 
    website_session_id, 
    MIN(website_pageview_id) AS min_pageview_id
FROM website_pageviews
WHERE created_at < '2012-06-14'
GROUP BY website_session_id;

CREATE TEMPORARY TABLE sessions_w_home_landing_page
SELECT 
    fv.website_session_id, 
    wp.pageview_url AS landing_page
FROM first_pageviews fv
LEFT JOIN website_pageviews wp ON fv.min_pageview_id = wp.website_pageview_id
WHERE wp.pageview_url = '/home';

CREATE TEMPORARY TABLE bounce_sessions
SELECT 
    slp.website_session_id, 
    slp.landing_page,
    COUNT(wp.website_pageview_id) AS pageviews
FROM sessions_w_home_landing_page slp
LEFT JOIN website_pageviews wp ON slp.website_session_id = wp.website_session_id
GROUP BY slp.website_session_id, slp.landing_page
HAVING pageviews = 1;

SELECT 
    COUNT(DISTINCT slp.website_session_id) AS sessions,
    COUNT(DISTINCT bs.website_session_id) AS b_sessions,
    COUNT(DISTINCT bs.website_session_id) / COUNT(DISTINCT slp.website_session_id) AS bounce_rate
FROM sessions_w_home_landing_page slp
LEFT JOIN bounce_sessions bs ON slp.website_session_id = bs.website_session_id;

-- 2.3 A/B test analysis for bounce rate reduction between home and lander-1
CREATE TEMPORARY TABLE website_firstpageviews
SELECT 
    wp.website_session_id,
    MIN(wp.website_pageview_id) AS first_viewpage
FROM website_pageviews wp
INNER JOIN website_sessions ws ON wp.website_session_id = ws.website_session_id
WHERE wp.created_at BETWEEN '2012-06-19 00:35:54' AND '2012-07-28'
    AND ws.utm_source = 'gsearch'
    AND ws.utm_campaign = 'nonbrand'
GROUP BY wp.website_session_id;

CREATE TEMPORARY TABLE first_viewpage_w_utm_url
SELECT 
    fp.website_session_id, 
    fp.first_viewpage, 
    wp.pageview_url
FROM website_firstpageviews fp
LEFT JOIN website_pageviews wp ON fp.first_viewpage = wp.website_pageview_id
WHERE wp.pageview_url IN ('/home', '/lander-1');

-- Bounce analysis for landing page versions
CREATE TEMPORARY TABLE utm_bounce_sessions
SELECT 
    futm.website_session_id, 
    futm.pageview_url, 
    COUNT(DISTINCT wp.website_pageview_id) AS count_of_pageviews
FROM first_viewpage_w_utm_url futm
LEFT JOIN website_pageviews wp ON futm.website_session_id = wp.website_session_id
GROUP BY futm.website_session_id, futm.pageview_url
HAVING COUNT(wp.website_pageview_id) = 1;

SELECT 
    futm.pageview_url, 
    COUNT(DISTINCT futm.website_session_id) AS all_sessions,
    COUNT(DISTINCT bs.website_session_id) AS bounced_sessions,
    COUNT(DISTINCT bs.website_session_id) / COUNT(DISTINCT futm.website_session_id) AS bounce_rate
FROM first_viewpage_w_utm_url futm
LEFT JOIN utm_bounce_sessions bs ON futm.website_session_id = bs.website_session_id
GROUP BY futm.pageview_url;

-- 2.4 Weekly trend analysis of landing pages

-- overall paid search bounce trended weekly

CREATE TEMPORARY TABLE first_viewpage
SELECT 
		wp.website_session_id,
        MIN(wp.website_pageview_id) AS first_pageview_id,
        COUNT(DISTINCT wp.website_pageview_id) AS session_page_views
FROM website_pageviews wp
RIGHT JOIN website_sessions ws ON wp.website_session_id = ws.website_session_id
WHERE ws.created_at > '2012-06-01'
	AND ws.created_at < '2012-08-31'
	AND ws.utm_source = 'gsearch' 
    AND ws.utm_campaign = 'nonbrand'
GROUP BY ws.website_session_id;

CREATE TEMPORARY TABLE first_viewpage_url
SELECT 
    fv.website_session_id,
    fv.session_page_views,
    wp.pageview_url,
    wp.created_at AS pv_created_at
FROM first_viewpage fv
LEFT JOIN website_pageviews wp ON fv.first_pageview_id = wp.website_pageview_id;

SELECT 
    WEEK(pv_created_at) AS week,
    COUNT(session_page_views) AS sessions,
    COUNT(DISTINCT CASE WHEN session_page_views = 1 THEN website_session_id ELSE NULL END) AS bounce_sessions,
    COUNT(DISTINCT CASE WHEN session_page_views = 1 THEN website_session_id ELSE NULL END) / COUNT(session_page_views) * 1.0 AS bounce_rate,
    COUNT(DISTINCT CASE WHEN pageview_url = '/home' THEN website_session_id ELSE NULL END) AS home,
    COUNT(DISTINCT CASE WHEN pageview_url = '/lander-1' THEN website_session_id ELSE NULL END) AS lander_1
FROM first_viewpage_url
GROUP BY WEEK(pv_created_at);

-- 3. Conversion Funnel Analysis

-- 3.1 Conversion funnel from landing page to order (Aug 15 to Sept 15)
SELECT 
    COUNT(DISTINCT website_session_id) AS sessions,
    SUM(products) AS to_products,
    SUM(mr_fuzzy) AS to_mrfuzzy,
    SUM(carts) AS to_cart,
    SUM(shipping) AS to_shipping,
    SUM(billing) AS to_billing,
    SUM(thank_you) AS to_thank_you,
    SUM(products) / COUNT(DISTINCT website_session_id) AS lander_click_rt,
    SUM(mr_fuzzy) / SUM(products) AS product_click_rt,
    SUM(carts) / SUM(mr_fuzzy) AS mrfuzzy_click_rt,
    SUM(shipping) / SUM(carts) AS cart_click_rt,
    SUM(billing) / SUM(shipping) AS shipping_click_rt,
    SUM(thank_you) / SUM(billing) AS billing_click_rt
FROM (
    SELECT 
        wp.website_session_id,
        wp.website_pageview_id,
        wp.pageview_url,
        CASE WHEN wp.pageview_url = '/products' THEN 1 ELSE 0 END AS products,
        CASE WHEN wp.pageview_url = '/the-original-mr-fuzzy' THEN 1 ELSE 0 END AS mr_fuzzy,
        CASE WHEN wp.pageview_url = '/cart' THEN 1 ELSE 0 END AS carts,
        CASE WHEN wp.pageview_url = '/shipping' THEN 1 ELSE 0 END AS shipping,
        CASE WHEN wp.pageview_url = '/billing' THEN 1 ELSE 0 END AS billing,
        CASE WHEN wp.pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END AS thank_you
    FROM website_pageviews wp
    LEFT JOIN website_sessions ws ON wp.website_session_id = ws.website_session_id
    WHERE ws.utm_source = 'gsearch'
        AND ws.utm_campaign = 'nonbrand'
        AND wp.created_at BETWEEN '2012-08-05' AND '2012-09-05'
) AS funnel;
