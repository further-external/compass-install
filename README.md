# Compass Install

Grants the Google Cloud IAM roles that Compass needs in your GCP project.

### Before you start

You need the **Owner** role on the GCP project you are connecting to Compass.

### Run it

1. In the [Google Cloud console](https://console.cloud.google.com/), select your project in the project picker at the top of the page.
2. Open Cloud Shell with the **Activate Cloud Shell** button (`>_`) in the top bar.
3. Paste this command:

   ```bash
   git clone https://github.com/further-external/compass-install.git && bash compass-install/grant_compass_roles.sh
   ```

4. Check the project id and type `y` to continue.

It takes about 2 minutes. When it finishes you'll see `Done.` message.

### What it does

Enables the IAM API and grants IAM roles to Compass service accounts:

| Service account | What it does | Roles |
|---|---|---|
| `compass-data@` | Created in your project. Runs the Compass data pipelines: Cloud Run jobs (data connectors, dbt, ML models) and the Workflows that schedule them. | • BigQuery Admin<br>• BigQuery Job User<br>• Storage Object Admin<br>• Artifact Registry Reader<br>• Cloud Run Developer<br>• Workflows Invoker<br>• Logs Viewer<br>• Private Logs Viewer<br>• Gemini Data Analytics Data Agent Editor<br>• Gemini Data Analytics Data Agent Creator<br>• Dataform Admin<br>• API Keys Admin<br>• Secret Manager Admin |
| `compass-read@` | Used by the Compass app to read your data for dashboards and AI features (data agents, Gemini, Model Armor safety checks). | • BigQuery Data Viewer<br>• BigQuery Job User<br>• Gemini Data Analytics Data Agent User<br>• Gemini for Google Cloud User<br>• Agent Platform User<br>• Model Armor User |
| `compass-write@` | Used by the Compass app to save data to BigQuery and Cloud Storage in your project. | • Storage Admin<br>• BigQuery Data Editor<br>• BigQuery Job User |
| `compass-infrastructure@` | Creates and maintains the Compass resources in your project: BigQuery datasets, Cloud Storage buckets, Cloud Run jobs, Workflows, schedules, API keys, secrets and alerts. | • Editor<br>• Storage Admin<br>• BigQuery Admin<br>• Secret Manager Secret Accessor |

### Check the result

List Compass service accounts that have access to your project:

```bash
gcloud projects get-iam-policy "$GOOGLE_CLOUD_PROJECT" --flatten='bindings[].members' --filter='bindings.members~"^serviceAccount:compass-"' --format='value(bindings.members.sub("serviceAccount:",""))' | sort -u
```

