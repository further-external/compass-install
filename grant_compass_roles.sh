#!/usr/bin/env bash
# Grants the IAM roles Compass needs in a client GCP project.
# Usage: bash grant_compass_roles.sh [PROJECT_ID]
# Defaults to the project selected in Cloud Shell ($GOOGLE_CLOUD_PROJECT).
set -euo pipefail

PROJECT_ID="${1:-${GOOGLE_CLOUD_PROJECT:-}}"
if [[ -z "$PROJECT_ID" ]]; then
	echo "No project selected in Cloud Shell. Pass the project ID instead:" >&2
	echo "  bash grant_compass_roles.sh <PROJECT_ID>" >&2
	exit 1
fi

COMPASS_PROJECT="pegasus-prod-448021"
COMPASS_DATA_SA="compass-data@${PROJECT_ID}.iam.gserviceaccount.com"
COMPASS_READ_SA="compass-read@${COMPASS_PROJECT}.iam.gserviceaccount.com"
COMPASS_WRITE_SA="compass-write@${COMPASS_PROJECT}.iam.gserviceaccount.com"
COMPASS_INFRASTRUCTURE_SA="compass-infrastructure@${COMPASS_PROJECT}.iam.gserviceaccount.com"

COMPASS_DATA_ROLES=(
	roles/editor
	roles/bigquery.admin
	roles/storage.objectAdmin
	roles/logging.privateLogViewer
	roles/secretmanager.secretAccessor
)

COMPASS_READ_ROLES=(
	roles/bigquery.dataViewer
	roles/bigquery.jobUser
	roles/geminidataanalytics.dataAgentUser
	roles/cloudaicompanion.user
	roles/aiplatform.user
	roles/modelarmor.user
)

COMPASS_WRITE_ROLES=(
	roles/storage.admin
	roles/bigquery.dataEditor
	roles/bigquery.jobUser
)

COMPASS_INFRASTRUCTURE_ROLES=(
	roles/editor
	roles/storage.admin
	roles/bigquery.admin
	roles/secretmanager.secretAccessor
)

# Grants each role to the member, retrying while a new service account propagates
grant_roles() {
	local member="$1"
	shift
	local role attempt error
	for role in "$@"; do
		for attempt in 1 2 3 4 5 6; do
			if error="$(gcloud projects add-iam-policy-binding "$PROJECT_ID" \
				--member="serviceAccount:${member}" \
				--role="$role" \
				--condition=None \
				--quiet 2>&1 >/dev/null)"; then
				echo "  granted ${role}"
				break
			fi
			if [[ "$attempt" -eq 6 || "$error" != *"does not exist"* ]]; then
				echo "  FAILED ${role} for ${member}:" >&2
				echo "$error" >&2
				exit 1
			fi
			sleep 10
		done
	done
}

account="$(gcloud config get-value account 2>/dev/null || true)"
if [[ -z "$account" ]]; then
	echo "No gcloud account is signed in. Run 'gcloud auth login' first." >&2
	exit 1
fi

if ! gcloud projects describe "$PROJECT_ID" --format="value(projectId)" >/dev/null 2>&1; then
	echo "Project '${PROJECT_ID}' not found, or ${account} cannot access it." >&2
	exit 1
fi

cat <<EOF

Signed in as: ${account}
Project:      ${PROJECT_ID}

This will:
  - enable the IAM API
  - create service account ${COMPASS_DATA_SA} (if missing)
  - grant ${#COMPASS_DATA_ROLES[@]} roles to ${COMPASS_DATA_SA}
  - grant ${#COMPASS_READ_ROLES[@]} roles to ${COMPASS_READ_SA}
  - grant ${#COMPASS_WRITE_ROLES[@]} roles to ${COMPASS_WRITE_SA}
  - grant ${#COMPASS_INFRASTRUCTURE_ROLES[@]} roles to ${COMPASS_INFRASTRUCTURE_SA}

EOF
read -r -p "Continue? [y/N] " answer
if [[ ! "$answer" =~ ^[Yy]$ ]]; then
	echo "Aborted."
	exit 1
fi

echo
echo "Enabling IAM API..."
gcloud services enable iam.googleapis.com --project="$PROJECT_ID"

if gcloud iam service-accounts describe "$COMPASS_DATA_SA" --project="$PROJECT_ID" >/dev/null 2>&1; then
	echo "Service account ${COMPASS_DATA_SA} already exists."
else
	echo "Creating service account ${COMPASS_DATA_SA}..."
	gcloud iam service-accounts create compass-data \
		--project="$PROJECT_ID" \
		--display-name="Service Account for Compass Data"
fi

echo
echo "compass-data:"
grant_roles "$COMPASS_DATA_SA" "${COMPASS_DATA_ROLES[@]}"

echo "compass-read:"
grant_roles "$COMPASS_READ_SA" "${COMPASS_READ_ROLES[@]}"

echo "compass-write:"
grant_roles "$COMPASS_WRITE_SA" "${COMPASS_WRITE_ROLES[@]}"

echo "compass-infrastructure:"
grant_roles "$COMPASS_INFRASTRUCTURE_SA" "${COMPASS_INFRASTRUCTURE_ROLES[@]}"

echo
echo "Done. Compass roles are granted in ${PROJECT_ID}."
