# Compass Install

Sets up your GCP project for Compass data warehouse.

### Before you start

You need the **Owner** role on the GCP project you are connecting to Compass, and the project must be linked to a billing account.

### Run it

1. In the [Google Cloud console](https://console.cloud.google.com/), select your project in the project picker at the top of the page.
2. Open Cloud Shell with the **Activate Cloud Shell** button (`>_`) in the top bar.
3. Paste this command:

   ```bash
   rm -rf compass-install; \
   git clone https://github.com/further-external/compass-install.git && \
   bash compass-install/grant_compass_roles.sh
   ```

4. Follow instructions in the console.

It takes about 5 minutes. When it finishes you'll see `Done.` message.

### What it does

1. Enables the Google Cloud APIs Compass uses.
2. Creates internal `compass-data` service account.
3. Creates the Docker repository in Artifact Registry for the Compass pipeline images.
4. Grants IAM roles to the Compass service accounts:

<table>
  <tr>
    <th>Service account</th>
    <th>What it does</th>
    <th width="40%">Roles</th>
  </tr>
  <tr>
    <td valign="top"><code>compass-data@</code></td>
    <td valign="top">Internal service account. Runs the Compass data pipelines from Artifact Registry.</td>
    <td valign="top">
      <ul>
        <li>Editor</li>
        <li>BigQuery Admin</li>
        <li>Storage Object Admin</li>
        <li>Secret Manager Secret Accessor</li>
        <li>Private Logs Viewer</li>
      </ul>
    </td>
  </tr>
  <tr>
    <td valign="top"><code>compass-infrastructure@</code></td>
    <td valign="top">Creates and maintains the Compass resources in your project.</td>
    <td valign="top">
      <ul>
        <li>Editor</li>
        <li>BigQuery Admin</li>
        <li>Storage Admin</li>
        <li>Secret Manager Secret Accessor</li>
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
    <td valign="top">Used by the Compass web app to save data to BigQuery and Cloud Storage in your project.</td>
    <td valign="top">
      <ul>
        <li>BigQuery Data Editor</li>
        <li>BigQuery Job User</li>
        <li>Storage Admin</li>
      </ul>
    </td>
  </tr>
</table>

