resource "google_project_service_identity" "workflows_agent" {
  provider = google-beta
  project  = var.project_id
  service  = "workflows.googleapis.com"
  depends_on = [google_project_service.enabled_apis]
}

resource "google_service_account" "workflow_service_account" {
  project      = var.project_id
  account_id   = "workflow-executor"
  display_name = "A service account that has permission to trigger workflow and cloud run jobs"
  depends_on = [google_project_service.enabled_apis]
}

resource "google_project_iam_member" "workflow_user" {
  project = var.project_id
  role    = "roles/run.admin" //TODO: Fix this
  member  = "serviceAccount:${google_service_account.workflow_service_account.email}"
  depends_on = [google_project_service.enabled_apis]
}

resource "google_service_account" "workflow_invoker_service_account" {
  project      = var.project_id
  account_id   = "workflow-invoker"
  display_name = "A service account that has permission to trigger workflow and cloud run jobs"
  depends_on = [google_project_service.enabled_apis]
}

resource "google_project_iam_member" "workflow_invoker_user" {
  project = var.project_id
  role    = "roles/workflows.invoker"
  member  = "serviceAccount:${google_service_account.workflow_invoker_service_account.email}"
  depends_on = [google_project_service.enabled_apis]
}

resource "google_workflows_workflow" "transformation_workflow" {
  name            = "transformation-workflow"
  region          = "us-central1"
  description     = "User Events Workflow"
  service_account = google_service_account.workflow_service_account.id
  call_log_level  = "LOG_ERRORS_ONLY"
  deletion_protection = false
  source_contents     = <<-EOF
main:
    params: [event]
    steps:
        - init:
            assign:
                - project_id: ${var.project_id}
                - job_location: ${var.location}
                - event_simulator_job_name: ${google_cloud_run_v2_job.event_simulator.name}
                - transformation_job_name: ${google_cloud_run_v2_job.dbt_transform.name}
        - run_dbt_transform:
            call: googleapis.run.v1.namespaces.jobs.run
            args:
                name: $${"namespaces/" + project_id + "/jobs/" +transformation_job_name}
                location: $${job_location}
            result: job_execution
        - finish:
            return: $${job_execution}
EOF
  depends_on          = [google_project_service.enabled_apis, google_project_service_identity.workflows_agent]
}

resource "google_cloud_scheduler_job" "workflow_scheduler" {
  name             = "workflow-scheduler"
  description      = "Workflow scheduler"
  region           = var.location
  schedule         = "0 8 * * *"
  time_zone        = "America/New_York"
  attempt_deadline = "320s"

  retry_config {
    retry_count = 1
  }

  http_target {
    http_method = "POST"
    uri         = "https://workflowexecutions.googleapis.com/v1/${google_workflows_workflow.transformation_workflow.id}/executions"
    oauth_token {
      service_account_email = google_service_account.workflow_invoker_service_account.email
    }
  }
  depends_on = [google_project_service.enabled_apis]
}
