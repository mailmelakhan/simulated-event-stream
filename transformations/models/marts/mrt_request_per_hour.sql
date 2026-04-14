SELECT
    DATE_TRUNC(`timestamp`, HOUR) as hour,
    COUNT(*) AS requests
FROM {{ ref('stg_events_past_12_months') }}
WHERE `timestamp` >= (CURRENT_TIMESTAMP - INTERVAL 162 DAY)
GROUP BY hour
ORDER BY hour
