SELECT
    location,
    COUNT(*) AS events,
    COUNT(DISTINCT userId) AS users
FROM {{ ref('stg_events_past_12_months') }}
GROUP BY location
ORDER BY events DESC