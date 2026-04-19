resource "google_bigquery_dataset" "user_events_dataset" {
  dataset_id    = "UserEventsDataset"
  friendly_name = "user-events-dataset"
  description   = "Dataset to store and organize user activities"
  location      = "US"
  access {
    role          = "OWNER"
    special_group = "projectOwners"
  }
  access {
    role          = "roles/bigquery.dataEditor"
    user_by_email = google_service_account.dataflow.email
  }
}

resource "google_bigquery_table" "user_events_table" {
  dataset_id = google_bigquery_dataset.user_events_dataset.dataset_id
  table_id   = "user-events-table"
  deletion_protection = false
  time_partitioning {
    field = "timestamp"
    type = "DAY"
  }
  schema     = <<EOF
[
  {
    "name": "ts",
    "type": "INTEGER",
    "mode": "NULLABLE",
    "description": "Timestamp"
  },
  {
    "name": "timestamp",
    "type": "TIMESTAMP",
    "mode": "NULLABLE",
    "description": "Timestamp"
  },
  {
    "name": "userId",
    "type": "INTEGER",
    "mode": "NULLABLE",
    "description": "User id"
  },
  {
    "name": "firstName",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "User first name"
  },
  {
    "name": "lastName",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "User last name"
  },
  {
    "name": "gender",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "Gender: M/F"
  },
  {
    "name": "level",
    "type": "STRING",
    "description": "Paid/Free"
  },
  {
    "name": "location",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "User location"
  },
  {
    "name": "registration",
    "type": "INTEGER",
    "mode": "NULLABLE",
    "description": "Timestamp since when user is registered"
  },
  {
    "name": "auth",
    "type": "STRING",
    "description": "User auth mode: Logged In/Logged Out/Guest"
  },
  {
    "name": "sessionId",
    "type": "INTEGER",
    "mode": "NULLABLE",
    "description": "User session id"
  },
  {
    "name": "itemInSession",
    "type": "INTEGER",
    "description": "Request count within same session"
  },
  {
    "name": "length",
    "type": "FLOAT",
    "mode": "NULLABLE",
    "description": "Session length"
  },
  {
    "name": "page",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "Name of the page logged for user request"
  },
  {
    "name": "method",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "Request method GET/PUT"
  },
  {
    "name": "status",
    "type": "INTEGER",
    "description": "Request status"
  },
  {
    "name": "userAgent",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "User agent name"
  },
  {
    "name": "artist",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "Name of artist"
  },
  {
    "name": "song",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "Name of the song"
  }
]
EOF

}

resource "google_bigquery_table" "user_events_table_dlq" {
  dataset_id = google_bigquery_dataset.user_events_dataset.dataset_id
  table_id   = "user-events-table-dlq"
}
