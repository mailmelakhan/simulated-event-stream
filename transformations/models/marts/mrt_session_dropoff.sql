WITH ranked_events AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY sessionId
               ORDER BY `timestamp` DESC
           ) AS rn
    FROM {{ ref('stg_events_past_12_months') }}
)

SELECT
    page AS last_page,
    COUNT(*) AS drop_off_sessions
FROM ranked_events
WHERE rn = 1
GROUP BY page
ORDER BY drop_off_sessions DESC