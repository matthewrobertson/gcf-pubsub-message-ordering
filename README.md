# Functions Framework + Cloud Run + Pub/Sub Message Ordering + Terraform

This sample demonstrates deploying a Python Google Cloud Function to CloudRun, then configuring a Pub/Sub subscription to invoke it. 

First create a container from the Python source code:

NOTE: You should replace `PROJECT_ID` with your own source code

```
cd ./src/
gcloud builds submit --pack image=gcr.io/PROJECT_ID/cr-background-function
```

Then deploy the image to CloudRun:

NOTE: You should replace the `PROJECT_ID` in [./terraform/main.tf](./terraform/main.tf) with your own GCP project ID and the `image` with the gcr URL you created in the previous step.

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

## Explanation

The sample builds a container using the same GCP buildpacks that power Google Cloud Functions. The necessary configuration is passed via build environment variables set in [./src/project.toml](./src/project.toml).

```
[[build.env]]
name = "GOOGLE_FUNCTION_TARGET"
value = "hello"

[[build.env]]
name = "GOOGLE_FUNCTION_SIGNATURE_TYPE"
value = "event"
```

Setting `GOOGLE_FUNCTION_SIGNATURE_TYPE=event` enables automatic request marshaling to convert the incoming HTTP request into the [GCF background function arguments](https://cloud.google.com/functions/docs/writing/background#functions-writing-background-hello-pubsub-python)


The function is then deployed to CloudRun and the service URL is used as the Pub/Sub subscription push endpoint:

```
push_config {
    push_endpoint = google_cloud_run_service.default.status[0].url
}
```

## HEADS UP

There is a bug in the Python functions frameworks that breaks automatic cloudevent marshaling of Pub/Sub payloads that do not include any `attributes`. 
