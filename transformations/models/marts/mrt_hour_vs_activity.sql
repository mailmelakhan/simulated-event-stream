SELECT
    EXTRACT(HOUR FROM `timestamp`) AS hour,
    COUNT(*) AS events,
    COUNT(DISTINCT userId) AS active_users
FROM {{ ref('stg_events_past_12_months') }}
GROUP BY hour
ORDER BY hour