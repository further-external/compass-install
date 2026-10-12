# Compass Install

Grants the Google Cloud IAM roles that Compass needs in your GCP project.

## Before you start

- You need the **Owner** role on the GCP project you are connecting to Compass.

## Run it

1. In the [Google Cloud console](https://console.cloud.google.com/), select your project in the project picker at the top of the page.
2. Open Cloud Shell with the **Activate Cloud Shell** button (`>_`) in the top bar.
3. Paste this command:

   ```bash
   git clone https://github.com/further-external/compass-install.git && bash compass-install/grant_compass_roles.sh
   ```

4. Check the project id and type `y` to continue.

It takes about 2 minutes. When it finishes you'll see `Done.` message.

## What it does

1. Enables the IAM API in your project.
2. Creates internal `compass-data` service account in your project which will be used to run the data pipelines.
3. Grants these roles on your project:

| Service account | Roles |
|---|---|
| `compass-data@` | BigQuery Admin, BigQuery Job User, Storage Object Admin, Artifact Registry Reader, Cloud Run Developer, Workflows Invoker, Logs Viewer, Private Logs Viewer, Gemini Data Analytics Data Agent Editor and Creator, Dataform Admin, API Keys Admin, Secret Manager Admin |
| `compass-read@` | BigQuery Data Viewer, BigQuery Job User, Gemini Data Analytics Data Agent User, Gemini for Google Cloud User, Agent Platform User, Model Armor User |
| `compass-write@` | Storage Admin, BigQuery Data Editor, BigQuery Job User |
| `compass-infrastructure@` | Editor, Storage Admin, BigQuery Admin, Secret Manager Secret Accessor |


## Check the result

List every role the Compass service accounts have on your project:

```bash
gcloud projects get-iam-policy "$GOOGLE_CLOUD_PROJECT" --flatten='bindings[].members' --filter='bindings.members~"^serviceAccount:compass-(data|read|write|infrastructure)@"' --sort-by='bindings.members,bindings.role' --format='table(bindings.members.sub("serviceAccount:",""):label=SERVICE_ACCOUNT, bindings.role:label=ROLE)'
```

