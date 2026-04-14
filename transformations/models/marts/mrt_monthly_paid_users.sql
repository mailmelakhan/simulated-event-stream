SELECT
    DATE_TRUNC(`timestamp`, MONTH) as month,
    COUNT(DISTINCT CASE WHEN level = 'paid' THEN userId END) * 100.0
        / COUNT(DISTINCT userId) AS paid_user_pct
FROM  {{ ref('stg_events_past_12_months') }}
GROUP BY month
ORDER BY month