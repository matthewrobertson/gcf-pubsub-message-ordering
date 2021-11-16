# Cloud Functions + Pub/Sub Message Ordering + Terraform

This sample demonstrates deploying a Python Google Cloud Function that is triggered by a manually configured Pub/Sub topic. The sample can be deployed using terraform:

NOTE: You should replace the `PROJECT_ID` in [./terraform/main.tf](./terraform/main.tf#L3) with your own GCP project ID

```bash
cd ./terraform/
terraform init
terraform plan
terraform apply
```

Then send a message to the Pub/Sub topic to trigger the function:

```bash
gcloud pubsub topics publish projects/PROJECT_ID/topics/message-ordering-topic \
  --message=hello \
  --attribute=foo="bar" \
  --ordering-key=5
```

View the function logs so observe the invocation:

```bash
gcloud functions logs read pubsub-message-ordering-cloud-function --region="us-central1" --project=PROJECT_ID
```

## Explanation

This sample uses the new [declarative functions signatures API](https://github.com/GoogleCloudPlatform/functions-framework-python#quickstart-register-your-function-using-decorator) to configure the signature type of the cloud function using a Python decorator:

```python
@functions_framework.cloud_event
def on_message(cloud_event):
```

This enables automatic request marshaling to convert the incoming HTTP request into a [CloudEvent](https://cloudevents.io/).


The function is then deployed using an HTTP trigger and its `trigger_url` is used to manually configure the Pub/Sub subscription:

```
push_config {
    push_endpoint = google_cloudfunctions_function.function.https_trigger_url
}
```

## HEADS UP

There is a bug in the Python functions frameworks that breaks automatic cloudevent marshaling of Pub/Sub payloads that do not include any `attributes`. 
