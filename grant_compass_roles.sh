#!/usr/bin/env bash
# Sets up a client GCP project for Compass: APIs, Artifact Registry, Terraform state bucket and IAM roles.
# Usage: bash grant_compass_roles.sh [PROJECT_ID]
# Defaults to the project selected in Cloud Shell ($GOOGLE_CLOUD_PROJECT).
# Asks for the region (us-central1 or europe-west4); skip the question with COMPASS_REGION=<region>.
set -euo pipefail

PROJECT_ID="${1:-${GOOGLE_CLOUD_PROJECT:-}}"
if [[ -z "$PROJECT_ID" ]]; then
	echo "No project selected in Cloud Shell. Pass the project ID instead:" >&2
	echo "  bash grant_compass_roles.sh <PROJECT_ID>" >&2
	exit 1
fi

COMPASS_PROJECT="pegasus-prod-448021"
ARTIFACT_REPOSITORY="pegasus-modules"
TERRAFORM_STATE_BUCKET="gs://${PROJECT_ID}-terraform-state"
COMPASS_DATA_SA="compass-data@${PROJECT_ID}.iam.gserviceaccount.com"
COMPASS_READ_SA="compass-read@${COMPASS_PROJECT}.iam.gserviceaccount.com"
COMPASS_WRITE_SA="compass-write@${COMPASS_PROJECT}.iam.gserviceaccount.com"
COMPASS_INFRASTRUCTURE_SA="compass-infrastructure@${COMPASS_PROJECT}.iam.gserviceaccount.com"

REQUIRED_APIS=(
	artifactregistry.googleapis.com
	cloudbuild.googleapis.com
	bigquerydatatransfer.googleapis.com
	bigquery.googleapis.com
	cloudtrace.googleapis.com
	searchads360.googleapis.com
	sqladmin.googleapis.com
	displayvideo.googleapis.com
	doubleclickbidmanager.googleapis.com
	dfareporting.googleapis.com
	analyticsdata.googleapis.com
	analyticsadmin.googleapis.com
	youtube.googleapis.com
	cloudscheduler.googleapis.com
	logging.googleapis.com
	monitoring.googleapis.com
	run.googleapis.com
	workflows.googleapis.com
	cloudaicompanion.googleapis.com
	geminidataanalytics.googleapis.com
	aiplatform.googleapis.com
	modelarmor.googleapis.com
	apikeys.googleapis.com
	secretmanager.googleapis.com
	cloudresourcemanager.googleapis.com
	iam.googleapis.com
	storage.googleapis.com
)

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
	roles/storage.objectViewer
	roles/storage.bucketViewer
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

if [[ -z "${COMPASS_REGION:-}" ]]; then
	echo
	echo "Select the region for Compass resources:"
	echo "  1) us-central1  (US)"
	echo "  2) europe-west4 (EU)"
	while [[ -z "${COMPASS_REGION:-}" ]]; do
		read -r -p "Region (1 or 2): " region_choice
		case "$region_choice" in
			1) COMPASS_REGION="us-central1" ;;
			2) COMPASS_REGION="europe-west4" ;;
			*) echo "Enter 1 or 2." >&2 ;;
		esac
	done
fi

cat <<EOF

Signed in as: ${account}
Project:      ${PROJECT_ID}
Region:       ${COMPASS_REGION}

This will:
  - enable ${#REQUIRED_APIS[@]} APIs
  - create service account ${COMPASS_DATA_SA} (if missing)
  - create Artifact Registry repository ${ARTIFACT_REPOSITORY} in ${COMPASS_REGION} (if missing)
  - create Terraform state bucket ${TERRAFORM_STATE_BUCKET} in ${COMPASS_REGION} (if missing)
  - grant ${#COMPASS_READ_ROLES[@]} roles to ${COMPASS_READ_SA}
  - grant ${#COMPASS_WRITE_ROLES[@]} roles to ${COMPASS_WRITE_SA}
  - grant ${#COMPASS_INFRASTRUCTURE_ROLES[@]} roles to ${COMPASS_INFRASTRUCTURE_SA}
  - grant ${#COMPASS_DATA_ROLES[@]} roles to ${COMPASS_DATA_SA}

EOF
read -r -p "Continue? [y/N] " answer
if [[ ! "$answer" =~ ^[Yy]$ ]]; then
	echo "Aborted."
	exit 1
fi

echo
echo "Enabling ${#REQUIRED_APIS[@]} APIs (this can take a few minutes)..."
# gcloud enables at most 20 services per call
for ((i = 0; i < ${#REQUIRED_APIS[@]}; i += 20)); do
	gcloud services enable "${REQUIRED_APIS[@]:i:20}" --project="$PROJECT_ID"
done

if gcloud iam service-accounts describe "$COMPASS_DATA_SA" --project="$PROJECT_ID" >/dev/null 2>&1; then
	echo "Service account ${COMPASS_DATA_SA} already exists."
else
	echo "Creating service account ${COMPASS_DATA_SA}..."
	gcloud iam service-accounts create compass-data \
		--project="$PROJECT_ID" \
		--display-name="Service Account for Compass Data"
fi

if gcloud artifacts repositories describe "$ARTIFACT_REPOSITORY" --location="$COMPASS_REGION" --project="$PROJECT_ID" >/dev/null 2>&1; then
	echo "Artifact Registry repository ${ARTIFACT_REPOSITORY} already exists."
else
	echo "Creating Artifact Registry repository ${ARTIFACT_REPOSITORY} in ${COMPASS_REGION}..."
	gcloud artifacts repositories create "$ARTIFACT_REPOSITORY" \
		--project="$PROJECT_ID" \
		--location="$COMPASS_REGION" \
		--repository-format=docker \
		--description="Container images for Pegasus Cloud Run jobs and services"
fi

if gcloud storage buckets describe "$TERRAFORM_STATE_BUCKET" --project="$PROJECT_ID" >/dev/null 2>&1; then
	echo "Terraform state bucket ${TERRAFORM_STATE_BUCKET} already exists."
else
	echo "Creating Terraform state bucket ${TERRAFORM_STATE_BUCKET} in ${COMPASS_REGION}..."
	gcloud storage buckets create "$TERRAFORM_STATE_BUCKET" \
		--project="$PROJECT_ID" \
		--location="$COMPASS_REGION" \
		--uniform-bucket-level-access \
		--public-access-prevention
	# Keep previous state versions so a bad apply can be rolled back
	gcloud storage buckets update "$TERRAFORM_STATE_BUCKET" --versioning
fi

echo
echo "compass-read:"
grant_roles "$COMPASS_READ_SA" "${COMPASS_READ_ROLES[@]}"

echo "compass-write:"
grant_roles "$COMPASS_WRITE_SA" "${COMPASS_WRITE_ROLES[@]}"

echo "compass-infrastructure:"
grant_roles "$COMPASS_INFRASTRUCTURE_SA" "${COMPASS_INFRASTRUCTURE_ROLES[@]}"

# Last, so the new compass-data service account has time to propagate
echo "compass-data:"
grant_roles "$COMPASS_DATA_SA" "${COMPASS_DATA_ROLES[@]}"

echo
echo "Done. ${PROJECT_ID} is set up for Compass."
