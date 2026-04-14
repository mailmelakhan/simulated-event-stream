SELECT
    day,
    AVG(t.user_listening_time) AS avg_listening_time_per_user
FROM (
    SELECT
        userId,
        DATE(`timestamp`) AS day,
        SUM(length) AS user_listening_time
    FROM {{ ref('stg_events_past_12_months') }}
    WHERE page = 'NextSong'
    GROUP BY userId, DATE(`timestamp`)
) t
GROUP BY day
ORDER BY day