SELECT
DATE_TRUNC(`timestamp`, MONTH) as date,
COUNT(DISTINCT userId) AS active_users
FROM {{ ref('stg_events_past_12_months') }}
GROUP BY date
ORDER BY date