# Compass Install

Grants the Google Cloud IAM roles that Compass needs in your GCP project.

## Before you start

- You need the **Owner** role on the GCP project you are connecting to Compass.
- Have your **project ID** ready (for example `my-company-compass`). You can find it on the [Google Cloud console dashboard](https://console.cloud.google.com/home/dashboard).

## Run it

1. Open [Cloud Shell](https://shell.cloud.google.com/?show=terminal). It's already signed in as you.
2. Paste this command, replacing `<PROJECT_ID>` with your project ID:

   ```bash
   git clone https://github.com/further-external/compass-install.git && bash compass-install/grant-compass-roles/grant_compass_roles.sh <PROJECT_ID>
   ```

3. Check the signed-in account and project the script prints, then type `y` to continue.

It takes about 2 minutes. When it finishes you'll see `Done. Compass roles are granted in <PROJECT_ID>.`

## What it does

The script only adds access. It never removes existing roles, so it is safe to run more than once.

1. Enables the IAM API in your project.
2. Creates the `compass-data` service account in your project (skipped if it already exists).
3. Grants these roles on your project:

| Service account | Roles |
|---|---|
| `compass-data@<PROJECT_ID>.iam.gserviceaccount.com` | BigQuery Admin, BigQuery Job User, Storage Object Admin, Artifact Registry Reader, Cloud Run Developer, Workflows Invoker, Logs Viewer, Private Logs Viewer, Gemini Data Analytics Data Agent Editor and Creator, Dataform Admin, API Keys Admin, Secret Manager Admin |
| `compass-read@pegasus-prod-448021.iam.gserviceaccount.com` | BigQuery Data Viewer, BigQuery Job User, Gemini Data Analytics Data Agent User, Gemini for Google Cloud User, Agent Platform User, Model Armor User |
| `compass-write@pegasus-prod-448021.iam.gserviceaccount.com` | Storage Admin, BigQuery Data Editor, BigQuery Job User |
| `compass-infrastructure@pegasus-prod-448021.iam.gserviceaccount.com` | Editor, Storage Admin, BigQuery Admin, Secret Manager Secret Accessor |

The full role IDs are listed at the top of [`grant-compass-roles/grant_compass_roles.sh`](grant-compass-roles/grant_compass_roles.sh).

## Check the result

List every role the Compass service accounts have on your project:

```bash
gcloud projects get-iam-policy <PROJECT_ID> --flatten="bindings[].members" --filter="bindings.members~compass-" --format="table(bindings.members, bindings.role)"
```

## Troubleshooting

**`destination path 'compass-install' already exists`**: you ran the command before in this Cloud Shell. Get the latest version and run the script again:

```bash
git -C compass-install pull && bash compass-install/grant-compass-roles/grant_compass_roles.sh <PROJECT_ID>
```

**`Project '<PROJECT_ID>' not found, or ... cannot access it`**: check the project ID, and that the account shown in Cloud Shell is an Owner of that project.

**`FAILED ... PERMISSION_DENIED`**: the signed-in account is not an Owner of the project. Ask a project Owner to run the script.
