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

### Check the result

List Compass service accounts that have access to your project:

```bash
gcloud projects get-iam-policy "$GOOGLE_CLOUD_PROJECT" --flatten='bindings[].members' --filter='bindings.members~"^serviceAccount:compass-"' --format='value(bindings.members.sub("serviceAccount:",""))' | sort -u
```

### What it does

Enables the IAM API and grants IAM roles to Compass service accounts:

<table>
  <tr>
    <th>Service account</th>
    <th>What it does</th>
    <th width="40%">Roles</th>
  </tr>
  <tr>
    <td valign="top"><code>compass-data@</code></td>
    <td valign="top">Internal service account. Runs the Compass data pipelines.</td>
    <td valign="top">
      <ul>
        <li>BigQuery Admin</li>
        <li>BigQuery Job User</li>
        <li>Storage Object Admin</li>
        <li>Artifact Registry Reader</li>
        <li>Cloud Run Developer</li>
        <li>Workflows Invoker</li>
        <li>Logs Viewer</li>
        <li>Private Logs Viewer</li>
        <li>Gemini Data Analytics Data Agent Editor</li>
        <li>Gemini Data Analytics Data Agent Creator</li>
        <li>Dataform Admin</li>
        <li>API Keys Admin</li>
        <li>Secret Manager Admin</li>
      </ul>
    </td>
  </tr>
  <tr>
    <td valign="top"><code>compass-read@</code></td>
    <td valign="top">Used by the Compass web app to read the data for dashboards and AI features.</td>
    <td valign="top">
      <ul>
        <li>BigQuery Data Viewer</li>
        <li>BigQuery Job User</li>
        <li>Gemini Data Analytics Data Agent User</li>
        <li>Gemini for Google Cloud User</li>
        <li>Agent Platform User</li>
        <li>Model Armor User</li>
      </ul>
    </td>
  </tr>
  <tr>
    <td valign="top"><code>compass-write@</code></td>
    <td valign="top">Used by the Compass app to save data to BigQuery and Cloud Storage in your project.</td>
    <td valign="top">
      <ul>
        <li>Storage Admin</li>
        <li>BigQuery Data Editor</li>
        <li>BigQuery Job User</li>
      </ul>
    </td>
  </tr>
  <tr>
    <td valign="top"><code>compass-infrastructure@</code></td>
    <td valign="top">Creates and maintains the Compass resources in the project.</td>
    <td valign="top">
      <ul>
        <li>Editor</li>
        <li>Storage Admin</li>
        <li>BigQuery Admin</li>
        <li>Secret Manager Secret Accessor</li>
      </ul>
    </td>
  </tr>
</table>

