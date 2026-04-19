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