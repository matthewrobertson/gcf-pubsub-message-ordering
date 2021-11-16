# Update variables.tf with your project name and region
provider "google" {
  project = "PROJECT_ID"
  region  = "us-central1"
}


# Create a staging bucket to hold the function source code
resource "google_storage_bucket" "bucket" {
  name     = "pubsub-ordering-deployment-bucket"
  location = "US-CENTRAL1"
  uniform_bucket_level_access = true
}

# Compress the application source code
data "archive_file" "src" {
  type        = "zip"
  source_dir  = "${path.root}/../src"
  output_path = "${path.root}/../generated/src.zip"
}

# Upload the compressed source to the staging bucket
resource "google_storage_bucket_object" "archive" {
  name   = "${data.archive_file.src.output_md5}.zip"
  bucket = google_storage_bucket.bucket.name
  source = "${path.root}/../generated/src.zip"
}

# Deploy the function 
resource "google_cloudfunctions_function" "function" {
  name        = "pubsub-message-ordering-cloud-function"
  description = "A Cloud Function with a manually configured PubSub trigger."
  runtime     = "python39"
  source_archive_bucket = google_storage_bucket.bucket.name
  source_archive_object = google_storage_bucket_object.archive.name
  trigger_http          = true  # We set the function tigger to HTTP 
  entry_point           = "on_message"
}

# Create a service account
resource "google_service_account" "service_account" {
  account_id   = "cloud-function-invoker"
  display_name = "Cloud Function Tutorial Invoker Service Account"
}

# Grant the service account premission to invoke the function
resource "google_cloudfunctions_function_iam_member" "invoker" {
  project        = google_cloudfunctions_function.function.project
  region         = google_cloudfunctions_function.function.region
  cloud_function = google_cloudfunctions_function.function.name

  role   = "roles/cloudfunctions.invoker"
  member = "serviceAccount:${google_service_account.service_account.email}"
}

# Create a pubsub topic
resource "google_pubsub_topic" "example" {
  name = "message-ordering-topic"
}

resource "google_pubsub_subscription" "example" {
  name  = "message-ordering-subscription"
  topic = google_pubsub_topic.example.name

  ack_deadline_seconds = 30
  enable_message_ordering = true


  push_config {
    push_endpoint = google_cloudfunctions_function.function.https_trigger_url

    # configure the push subscription to use the dedicated service account created above
    oidc_token {
      service_account_email = google_service_account.service_account.email
    }
  }
}