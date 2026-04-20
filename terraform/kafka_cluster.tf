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
  depends_on = [google_project_service.enabled_apis]
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
  depends_on = [google_project_service.enabled_apis, google_managed_kafka_cluster.kafka_cluster]
}