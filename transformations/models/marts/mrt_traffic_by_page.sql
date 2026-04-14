SELECT
    page,
    COUNT(*) AS requests
FROM {{ ref('stg_events_past_12_months') }}
GROUP BY page
ORDER BY requests DESC