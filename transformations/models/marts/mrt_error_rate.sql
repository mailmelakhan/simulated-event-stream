SELECT
    DATE_TRUNC(`timestamp`, HOUR) AS hour,
    COUNT(*) AS total_requests,
    SUM(CASE WHEN status != 200 THEN 1 ELSE 0 END) AS error_count,
    SUM(CASE WHEN status != 200 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS error_rate_pct
FROM {{ ref('stg_events_past_12_months') }}
GROUP BY hour
ORDER BY hour