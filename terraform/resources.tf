resource "google_storage_bucket" "user-events-bucket" {
  name                        = var.bucket_name
  location                    = "US"
  force_destroy               = true
  uniform_bucket_level_access = true
}

/*
Service Account with permission to read/write on managed kafka. Using it with cloud run job,
which generates user events and sends to kafka.
 */
resource "google_service_account" "kafka_read_write" {
  project      = var.project_id
  account_id   = "kafka-read-write"
  display_name = "A service account that has read/write access to kafka"
}

resource "google_project_iam_member" "kafka_read_write_user" {
  project = var.project_id
  role    = "roles/managedkafka.client"
  member  = "serviceAccount:${google_service_account.kafka_read_write.email}"
}

/*
Service Account with permission to read/write from kafka, bigquery and cloud storage services.
This service account is used by dataflow service to read messages from kafka and stream them to bigquery.
 */
resource "google_service_account" "dataflow" {
  project      = var.project_id
  account_id   = "dataflow-read-write"
  display_name = "A service account that has read/write access to kafka, bigquery and cloud storage services"
}

resource "google_project_iam_member" "dataflow_admin" {
  project = var.project_id
  role    = "roles/dataflow.admin"
  member  = "serviceAccount:${google_service_account.dataflow.email}"
}

resource "google_project_iam_member" "dataflow_worker" {
  project = var.project_id
  role    = "roles/dataflow.worker"
  member  = "serviceAccount:${google_service_account.dataflow.email}"
}

resource "google_project_iam_member" "dataflow_kafka_read_write" {
  project = var.project_id
  role    = "roles/managedkafka.client"
  member  = "serviceAccount:${google_service_account.dataflow.email}"
}

resource "google_project_iam_member" "dataflow_bigquery_read_write" {
  project = var.project_id
  role    = "roles/bigquery.dataEditor"
  member  = "serviceAccount:${google_service_account.dataflow.email}"
}

resource "google_project_iam_member" "dataflow_iam_service_account_token_creator" {
  project = var.project_id
  role    = "roles/iam.serviceAccountTokenCreator"
  member  = "serviceAccount:${google_service_account.dataflow.email}"
}

resource "google_project_iam_member" "dataflow_iam_service_account_user" {
  project = var.project_id
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${google_service_account.dataflow.email}"
}

resource "google_project_iam_member" "dataflow_cloud_storage_read_write" {
  project = var.project_id
  role    = "roles/storage.admin"
  member  = "serviceAccount:${google_service_account.dataflow.email}"
}

resource "google_project_iam_member" "dataflow_service_agent" {
  project = var.project_id
  role    = "roles/dataflow.serviceAgent"
  member  = "serviceAccount:${google_service_account.dataflow.email}"
}

resource "google_project_iam_member" "compute_service_agent" {
  project = var.project_id
  role    = "roles/compute.serviceAgent"
  member  = "serviceAccount:${google_service_account.dataflow.email}"
}

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
/*
resource "google_managed_kafka_cluster" "kafka_cluster" {
  cluster_id = var.kafka_cluster_name
  location   = var.location
  capacity_config {
    vcpu_count   = 3
    memory_bytes = 3221225472
  }
  gcp_config {
    access_config {
      network_configs {
        subnet = "projects/${var.project_id}/regions/${var.location}/subnetworks/default"
      }
    }
  }
  rebalance_config {
    mode = "AUTO_REBALANCE_ON_SCALE_UP"
  }
  labels = {
    key = "value"
  }
}

resource "google_managed_kafka_topic" "kafka_topic" {
  topic_id           = var.kafka_topic_name
  cluster            = google_managed_kafka_cluster.kafka_cluster.cluster_id
  location           = var.location
  partition_count    = 2
  replication_factor = 3
  configs = {
    "cleanup.policy" = "compact"
  }
  depends_on = [google_managed_kafka_cluster.kafka_cluster]
}

resource "google_cloud_run_v2_job" "event_simulator" {
  client              = "cloud-console"
  name                = "user-event-simulator"
  location            = var.location
  deletion_protection = false

  template {
    template {
      containers {
        name  = "event-simulator"
        image = "mailmelakhan/eventsim:0.9.0"
        args = [
          "--nusers=1000",
          "--from=730",
          "--growth-rate=0.04",
          "--kafkaBrokerList=bootstrap.user-events-kafka-cluster.us-central1.managedkafka.data-eng-project-490702.cloud.goog:9092",
          "--kafkaTopic=user-events-topic",
          "--config=examples/example-config.json"
        ]
        resources {
          limits = {
            cpu    = "1000m"
            memory = "1Gi"
          }
        }
      }
      vpc_access {
        egress = "ALL_TRAFFIC"
        network_interfaces {
          network    = "default"
          subnetwork = "default"
          tags       = []
        }
      }
      timeout = "3600s"
      max_retries     = 0
      service_account = google_service_account.kafka_read_write.email
    }
    task_count  = 1
    parallelism = 1
  }
  depends_on = [google_managed_kafka_cluster.kafka_cluster, google_managed_kafka_topic.kafka_topic]
}

resource "google_dataflow_flex_template_job" "kafka_to_bigquery" {
  provider                = google-beta
  project                 = var.project_id
  region                  = var.location
  name                    = "kafka-to-bigquery"
  container_spec_gcs_path = "gs://dataflow-templates-${var.location}/2025-03-11-00_RC02/flex/Kafka_to_BigQuery_Flex"
  service_account_email   = google_service_account.dataflow.email
  machine_type            = "e2-medium"
  enable_streaming_engine = true
  parameters = {
    readBootstrapServerAndTopic = "bootstrap.user-events-kafka-cluster.us-central1.managedkafka.data-eng-project-490702.cloud.goog:9092;user-events-topic"
    consumerGroupId             = "kafka-to-bigquery"
    enableCommitOffsets         = true
    messageFormat               = "JSON"
    kafkaReadAuthenticationMode = "APPLICATION_DEFAULT_CREDENTIALS"
    outputProject               = var.project_id
    outputDataset               = google_bigquery_dataset.user_events_dataset.dataset_id
    outputTableSpec             = "${var.project_id}:${google_bigquery_dataset.user_events_dataset.dataset_id}.${google_bigquery_table.user_events_table.table_id}"
    outputDeadletterTable       = "${var.project_id}:${google_bigquery_dataset.user_events_dataset.dataset_id}.${google_bigquery_table.user_events_table_dlq.table_id}"
    numStorageWriteApiStreams   = 1
    writeMode                   = "SINGLE_TABLE_NAME"
    useBigQueryDLQ              = true
  }
  depends_on = [google_managed_kafka_cluster.kafka_cluster, google_managed_kafka_topic.kafka_topic, google_bigquery_dataset.user_events_dataset, google_bigquery_table.user_events_table, google_bigquery_table.user_events_table_dlq, google_storage_bucket.user-events-bucket]
}
*/