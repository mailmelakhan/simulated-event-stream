SELECT
    CASE
        WHEN userAgent LIKE '%iPhone%' THEN 'iPhone'
        WHEN userAgent LIKE '%iPad%' THEN 'iPad'
        WHEN userAgent LIKE '%Macintosh%' THEN 'Mac'
        WHEN userAgent LIKE '%Windows%' THEN 'Windows'
        WHEN userAgent LIKE '%Linux%' THEN 'Linux'
        ELSE 'Other'
    END AS device_type,
    COUNT(*) AS events
FROM {{ ref('stg_events_past_12_months') }}
GROUP BY device_type
ORDER BY events DESC