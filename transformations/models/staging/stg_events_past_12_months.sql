SELECT *
FROM {{ source('bq_user_event_data_raw', 'user-events-table') }}
WHERE DATE_DIFF( DATE(`timestamp`), DATE(CURRENT_TIMESTAMP), MONTH) <= 12