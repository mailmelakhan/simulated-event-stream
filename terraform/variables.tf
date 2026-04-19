variable "project_id" {
  type        = string
  description = "Gcloud project id"
}

variable "bucket_name" {
  type        = string
  description = "User event data bucket name"
  default     = "user-events-data-bucket"
}

variable "location" {
  type        = string
  description = "Resource location"
  default     = "us-central1"
}


variable "kafka_cluster_name" {
  type        = string
  description = "Kafka topic to user events"
  default     = "user-events-kafka-cluster"
}

variable "kafka_topic_name" {
  type        = string
  description = "Kafka topic to user events"
  default     = "user-events-topic"
}


