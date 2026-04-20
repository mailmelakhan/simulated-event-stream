/*
Service Account with permission to read/write on managed kafka. Using it with cloud run job,
which generates user events and sends to kafka.
 */
resource "google_service_account" "kafka_read_write" {
  project      = var.project_id
  account_id   = "kafka-read-write"
  display_name = "A service account that has read/write access to kafka"
  depends_on = [google_project_service.enabled_apis]
}

resource "google_project_iam_member" "kafka_read_write_user" {
  project = var.project_id
  role    = "roles/managedkafka.client"
  member  = "serviceAccount:${google_service_account.kafka_read_write.email}"
  depends_on = [google_project_service.enabled_apis]
}

/*
Service Account with permission to read/write to bug query.
Using it with cloud run job for DBT transformations.
 */
resource "google_service_account" "bigquery_read_write" {
  project      = var.project_id
  account_id   = "bigquery-read-write"
  display_name = "A service account that has read/write access to bigquery"
}

resource "google_project_iam_member" "bigquery_read_write_user" {
  project = var.project_id
  role    = "roles/bigquery.dataEditor"
  member  = "serviceAccount:${google_service_account.bigquery_read_write.email}"
}

resource "google_project_iam_member" "bigquery_job_user" {
  project = var.project_id
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${google_service_account.bigquery_read_write.email}"
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
          "--from=366",
          "--growth-rate=0.04",
          "--kafkaBrokerList=bootstrap.${var.kafka_cluster_name}.${var.location}.managedkafka.${var.project_id}.cloud.goog:9092",
          "--kafkaTopic=${var.kafka_topic_name}",
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
  depends_on = [google_project_service.enabled_apis, google_managed_kafka_cluster.kafka_cluster, google_managed_kafka_topic.kafka_topic]
}

resource "google_cloud_run_v2_job" "dbt_transform" {
  client              = "cloud-console"
  name                = "dbt-transform"
  location            = var.location
  deletion_protection = false

  template {
    template {
      containers {
        name  = "dbt-transform"
        image = "mailmelakhan/dbt_transform_user_events:0.0.5"
        args = [
          "--vars={\"PROJECT_ID\":\"${var.project_id}\", \"BQ_DATASET\":\"${google_bigquery_dataset.user_events_dataset.dataset_id}\", \"AUTH_METHOD\":\"oauth\"}"
        ]
        resources {
          limits = {
            cpu    = "1000m"
            memory = "1Gi"
          }
        }
      }
      timeout = "3600s"
      max_retries     = 0
      service_account = google_service_account.bigquery_read_write.email
    }
    task_count  = 1
    parallelism = 1
  }
  depends_on = [google_project_service.enabled_apis, google_bigquery_table.user_events_table]
}