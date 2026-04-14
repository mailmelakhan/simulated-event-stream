WITH monthly_users AS (
    SELECT DISTINCT
        userId,
        DATE_TRUNC(`timestamp`, MONTH) AS month
    FROM {{ ref('stg_events_past_12_months') }}
    WHERE level = 'paid'
),

churn_calc AS (
    SELECT
        prev.month AS prev_month,
        COUNT(DISTINCT prev.userId) AS prev_users,
        COUNT(DISTINCT curr.userId) AS retained_users
    FROM monthly_users prev
    LEFT JOIN monthly_users curr
        ON prev.userId = curr.userId
        AND DATE(curr.month) = DATE_SUB(DATE(prev.month), INTERVAL 1 MONTH)
    GROUP BY prev.month
)

SELECT
    prev_month,
    (prev_users - retained_users) * 100.0 / prev_users AS churn_pct
FROM churn_calc
ORDER BY prev_month