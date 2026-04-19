SELECT
    DATE_TRUNC(`timestamp`, HOUR) as hour,
    COUNT(*) AS requests
FROM {{ ref('stg_events_past_12_months') }}
GROUP BY hour
ORDER BY hour
