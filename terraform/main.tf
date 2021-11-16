# Update variables.tf with your project name and region
provider "google" {
  project = "PROJECT_ID"
  region  = "us-central1"
}

# Deploy the container image as a CR service 
resource "google_cloud_run_service" "default" {
  name     = "cloudrun-srv"
  location = "us-central1"

  template {
    spec {
      containers {
        image = "gcr.io/PROJECT_ID/cr-background-function:latest"
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
}

# Create a service account
resource "google_service_account" "service_account" {
  account_id   = "cloud-function-invoker"
  display_name = "Cloud Function Tutorial Invoker Service Account"
}

# Grant the service account premission to invoke the function
resource "google_cloud_run_service_iam_member" "invoker" {
  project        = google_cloud_run_service.default.project
  location = google_cloud_run_service.default.location
  service = google_cloud_run_service.default.name

  role   = "roles/run.invoker"
  member = "serviceAccount:${google_service_account.service_account.email}"
}

# Create a pubsub topic
resource "google_pubsub_topic" "example" {
  name = "message-ordering-topic-cr"
}

resource "google_pubsub_subscription" "example" {
  name  = "message-ordering-subscription"
  topic = google_pubsub_topic.example.name

  ack_deadline_seconds = 30
  enable_message_ordering = true


  push_config {
    push_endpoint = google_cloud_run_service.default.status[0].url

    # configure the push subscription to use the dedicated service account created above
    oidc_token {
      service_account_email = google_service_account.service_account.email
    }
  }
}