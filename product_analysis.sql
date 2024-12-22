-- 1. Get the list of current primary products
SELECT DISTINCT product_id 
FROM order_items
WHERE is_primary_item = 1;

-- 2. Get performance baseline for existing products (sales, revenue, and margin)
SELECT  
    YEAR(created_at) AS year,
    MONTH(created_at) AS month,
    COUNT(order_item_id) AS number_of_sales,
    SUM(price_usd) AS total_revenue,
    SUM(price_usd) - SUM(cogs_usd) AS total_margin
FROM order_items
WHERE created_at < '2013-01-04'
GROUP BY 1, 2;

-- 3. Product trending analysis (April 2, 2012 - April 5, 2013)
-- Analyze product sales and session trends for product 1 and product 2
SELECT 
    YEAR(ws.created_at) AS yr,
    MONTH(ws.created_at) AS mo,
    COUNT(DISTINCT odr.order_id) AS number_of_orders,
    COUNT(DISTINCT ws.website_session_id) AS number_of_sessions,
    COUNT(DISTINCT odr.order_id) / COUNT(DISTINCT ws.website_session_id) AS session_to_order_conversion_rate,
    SUM(odr.price_usd) / COUNT(DISTINCT ws.website_session_id) AS revenue_per_session,
    COUNT(CASE WHEN odr.primary_product_id = 1 THEN odr.order_id ELSE NULL END) AS product_1_sales,
    COUNT(CASE WHEN odr.primary_product_id = 2 THEN odr.order_id ELSE NULL END) AS product_2_sales
FROM website_sessions ws
LEFT JOIN orders odr ON ws.website_session_id = odr.website_session_id
WHERE ws.created_at > '2012-04-01' 
    AND ws.created_at < '2013-04-05'
GROUP BY 1, 2;

-- 4. Product-level website analysis: Product Page Navigation
-- Create table for product pageviews
CREATE TEMPORARY TABLE product_pageviews
SELECT 
    website_pageview_id,
    website_session_id,
    created_at,
    CASE 
        WHEN created_at < '2013-01-06' THEN 'pre_product_2' 
        ELSE 'post_product_2' 
    END AS time_period
FROM website_pageviews
WHERE created_at > '2012-10-06' 
    AND created_at < '2013-04-06'
    AND pageview_url = '/products';

-- Create table for the next pageviews after product page
CREATE TEMPORARY TABLE next_pageviews
SELECT 
    PP.time_period,
    pp.website_session_id,
    MIN(wp.website_pageview_id) AS min_next_pageview_id
FROM product_pageviews pp 
LEFT JOIN website_pageviews wp ON pp.website_session_id = wp.website_session_id	
    AND wp.website_pageview_id > pp.website_pageview_id
GROUP BY 1, 2;

-- Create table with the next pageview URLs
CREATE TEMPORARY TABLE next_pageviews_url
SELECT 
    np.time_period,
    np.website_session_id,
    wp.pageview_url AS next_pageview_url
FROM next_pageviews np
LEFT JOIN website_pageviews wp ON np.min_next_pageview_id = wp.website_pageview_






