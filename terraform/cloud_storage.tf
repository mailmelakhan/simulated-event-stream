/**
For debugging purpose, not used in pipeline.
 */
resource "google_storage_bucket" "user-events-bucket" {
  name                        = var.bucket_name
  location                    = "US"
  force_destroy               = true
  uniform_bucket_level_access = true
}