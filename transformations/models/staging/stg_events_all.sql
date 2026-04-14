SELECT *
FROM {{ source('bq_user_event_data_raw', 'user-events-table') }}