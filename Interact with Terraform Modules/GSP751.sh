#!/bin/bash
BLACK_TEXT=$'\033[0;90m'
RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
BLUE_TEXT=$'\033[0;94m'
MAGENTA_TEXT=$'\033[0;95m'
CYAN_TEXT=$'\033[0;96m'
WHITE_TEXT=$'\033[0;97m'
DIM_TEXT=$'\033[2m'
STRIKETHROUGH_TEXT=$'\033[9m'
BOLD_TEXT=$'\033[1m'
RESET_FORMAT=$'\033[0m'

clear

echo
echo "${CYAN_TEXT}${BOLD_TEXT}===================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}🚀     INITIATING EXECUTION     🚀${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}===================================${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}🔑 Let's verify your active Google Cloud accounts. Please review the list below!${RESET_FORMAT}"
echo

gcloud auth list

echo "${GREEN_TEXT}${BOLD_TEXT}🟢 Enabling App Engine API for your project...${RESET_FORMAT}"
echo

gcloud services enable appengine.googleapis.com

echo "${BLUE_TEXT}${BOLD_TEXT}🌍 Fetching your default compute zone...${RESET_FORMAT}"


export ZONE=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-zone])")
echo "${GREEN_TEXT}${BOLD_TEXT}🟢 Your default compute zone is: $ZONE${RESET_FORMAT}"

echo
echo "${BLUE_TEXT}${BOLD_TEXT}🌎 Fetching your default compute region...${RESET_FORMAT}"
echo

export REGION=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-region])")
echo "${GREEN_TEXT}${BOLD_TEXT}🟢 Your default compute region is: $REGION${RESET_FORMAT}"

echo
echo "${CYAN_TEXT}${BOLD_TEXT}🔧 Setting your compute region in gcloud config...${RESET_FORMAT}"
echo

gcloud config set compute/region $REGION

echo "${MAGENTA_TEXT}${BOLD_TEXT}📝 Retrieving your current GCP Project ID...${RESET_FORMAT}"
echo

export PROJECT_ID=$(gcloud config get-value project)
echo "${GREEN_TEXT}${BOLD_TEXT}🟢 Your current GCP Project ID is: $PROJECT_ID${RESET_FORMAT}"

echo
echo "${YELLOW_TEXT}${BOLD_TEXT}📦 Cloning the Terraform Google Network module repository...${RESET_FORMAT}"
echo

git clone https://github.com/terraform-google-modules/terraform-google-network
cd terraform-google-network

echo "${GREEN_TEXT}${BOLD_TEXT}🔖 Checking out the required version of the module...${RESET_FORMAT}"
echo

git checkout tags/v6.0.1 -b v6.0.1

echo "${CYAN_TEXT}${BOLD_TEXT}🔍 Confirming your active GCP project...${RESET_FORMAT}"
echo

gcloud config list --format 'value(core.project)'

cd examples/simple_project

echo "${YELLOW_TEXT}${BOLD_TEXT}🛠️ Creating variables file for Terraform...${RESET_FORMAT}"
echo

cat > variables.tf <<EOF
variable "project_id" {
    description = "The project ID to host the network in"
    default     = "$DEVSHELL_PROJECT_ID"
}

variable "network_name" {
    description = "The name of the VPC network being created"
    default     = "example-vpc"
}
EOF

echo "${GREEN_TEXT}${BOLD_TEXT}🛠️ Generating main Terraform configuration...${RESET_FORMAT}"
echo

cat > main.tf <<EOF
module "test-vpc-module" {
    source       = "terraform-google-modules/network/google"
    version      = "~> 6.0"
    project_id   = var.project_id # Replace this with your project ID in quotes
    network_name = var.network_name
    mtu          = 1460

    subnets = [
        {
            subnet_name   = "subnet-01"
            subnet_ip     = "10.10.10.0/24"
            subnet_region = "$REGION"
        },
        {
            subnet_name           = "subnet-02"
            subnet_ip             = "10.10.20.0/24"
            subnet_region         = "$REGION"
            subnet_private_access = "true"
            subnet_flow_logs      = "true"
        },
        {
            subnet_name               = "subnet-03"
            subnet_ip                 = "10.10.30.0/24"
            subnet_region             = "$REGION"
            subnet_flow_logs          = "true"
            subnet_flow_logs_interval = "INTERVAL_10_MIN"
            subnet_flow_logs_sampling = 0.7
            subnet_flow_logs_metadata = "INCLUDE_ALL_METADATA"
            subnet_flow_logs_filter   = "false"
        }
    ]
}
# [END vpc_custom_create]
EOF

echo "${BLUE_TEXT}${BOLD_TEXT}⚙️ Initializing Terraform in the current directory...${RESET_FORMAT}"
echo

terraform init

echo "${GREEN_TEXT}${BOLD_TEXT}🚧 Applying Terraform configuration to create resources...${RESET_FORMAT}"
echo

terraform apply --auto-approve

echo "${RED_TEXT}${BOLD_TEXT}🧹 Destroying created resources to clean up...${RESET_FORMAT}"
echo

terraform destroy --auto-approve

echo "${YELLOW_TEXT}${BOLD_TEXT}🗑️ Removing the cloned Terraform module directory...${RESET_FORMAT}"
echo

rm -rd terraform-google-network -f

cd ~
rm -rd terraform-google-network -f

echo "${CYAN_TEXT}${BOLD_TEXT}📄 Creating main Terraform file for your new module...${RESET_FORMAT}"
echo

touch main.tf

echo "${MAGENTA_TEXT}${BOLD_TEXT}📁 Setting up directory for GCS static website bucket module...${RESET_FORMAT}"
echo

mkdir -p modules/gcs-static-website-bucket

cd modules/gcs-static-website-bucket

echo "${YELLOW_TEXT}${BOLD_TEXT}📄 Creating Terraform files for the module...${RESET_FORMAT}"
echo

touch website.tf variables.tf outputs.tf

echo "${GREEN_TEXT}${BOLD_TEXT}📝 Adding a README for your module...${RESET_FORMAT}"
echo

tee -a README.md <<EOF
# GCS static website bucket
This module provisions Cloud Storage buckets configured for static website hosting.
EOF

echo "${BLUE_TEXT}${BOLD_TEXT}📜 Adding license information...${RESET_FORMAT}"
echo

tee -a LICENSE <<EOF
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
        http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
EOF

echo "${YELLOW_TEXT}${BOLD_TEXT}🛠️ Defining the GCS bucket resource in Terraform...${RESET_FORMAT}"
echo

cat > website.tf <<EOF
resource "google_storage_bucket" "bucket" {
    name               = var.name
    project            = var.project_id
    location           = var.location
    storage_class      = var.storage_class
    labels             = var.labels
    force_destroy      = var.force_destroy
    uniform_bucket_level_access = true
    versioning {
        enabled = var.versioning
    }
    dynamic "retention_policy" {
        for_each = var.retention_policy == null ? [] : [var.retention_policy]
        content {
            is_locked        = var.retention_policy.is_locked
            retention_period = var.retention_policy.retention_period
        }
    }
    dynamic "encryption" {
        for_each = var.encryption == null ? [] : [var.encryption]
        content {
            default_kms_key_name = var.encryption.default_kms_key_name
        }
    }
    dynamic "lifecycle_rule" {
        for_each = var.lifecycle_rules
        content {
            action {
                type          = lifecycle_rule.value.action.type
                storage_class = lookup(lifecycle_rule.value.action, "storage_class", null)
            }
            condition {
                age                   = lookup(lifecycle_rule.value.condition, "age", null)
                created_before        = lookup(lifecycle_rule.value.condition, "created_before", null)
                with_state            = lookup(lifecycle_rule.value.condition, "with_state", null)
                matches_storage_class = lookup(lifecycle_rule.value.condition, "matches_storage_class", null)
                num_newer_versions    = lookup(lifecycle_rule.value.condition, "num_newer_versions", null)
            }
        }
    }
}
EOF

echo "${CYAN_TEXT}${BOLD_TEXT}📦 Defining input variables for your module...${RESET_FORMAT}"
echo

cat > variables.tf <<EOF
variable "name" {
    description = "The name of the bucket."
    type        = string
}
variable "project_id" {
    description = "The ID of the project to create the bucket in."
    type        = string
}
variable "location" {
    description = "The location of the bucket."
    type        = string
}
variable "storage_class" {
    description = "The Storage Class of the new bucket."
    type        = string
    default     = null
}
variable "labels" {
    description = "A set of key/value label pairs to assign to the bucket."
    type        = map(string)
    default     = null
}
variable "bucket_policy_only" {
    description = "Enables Bucket Policy Only access to a bucket."
    type        = bool
    default     = true
}
variable "versioning" {
    description = "While set to true, versioning is fully enabled for this bucket."
    type        = bool
    default     = true
}
variable "force_destroy" {
    description = "When deleting a bucket, this boolean option will delete all contained objects. If false, Terraform will fail to delete buckets which contain objects."
    type        = bool
    default     = true
}
variable "iam_members" {
    description = "The list of IAM members to grant permissions on the bucket."
    type = list(object({
        role   = string
        member = string
    }))
    default = []
}
variable "retention_policy" {
    description = "Configuration of the bucket's data retention policy for how long objects in the bucket should be retained."
    type = object({
        is_locked        = bool
        retention_period = number
    })
    default = null
}
variable "encryption" {
    description = "A Cloud KMS key that will be used to encrypt objects inserted into this bucket"
    type = object({
        default_kms_key_name = string
    })
    default = null
}
variable "lifecycle_rules" {
    description = "The bucket's Lifecycle Rules configuration."
    type = list(object({
        # Object with keys:
        # - type - The type of the action of this Lifecycle Rule. Supported values: Delete and SetStorageClass.
        # - storage_class - (Required if action type is SetStorageClass) The target Storage Class of objects affected by this Lifecycle Rule.
        action = any
        # Object with keys:
        # - age - (Optional) Minimum age of an object in days to satisfy this condition.
        # - created_before - (Optional) Creation date of an object in RFC 3339 (e.g. 2017-06-13) to satisfy this condition.
        # - with_state - (Optional) Match to live and/or archived objects. Supported values include: "LIVE", "ARCHIVED", "ANY".
        # - matches_storage_class - (Optional) Storage Class of objects to satisfy this condition. Supported values include: MULTI_REGIONAL, REGIONAL, NEARLINE, COLDLINE, STANDARD, DURABLE_REDUCED_AVAILABILITY.
        # - num_newer_versions - (Optional) Relevant only for versioned objects. The number of newer versions of an object to satisfy this condition.
        condition = any
    }))
    default = []
}
EOF

echo "${GREEN_TEXT}${BOLD_TEXT}📤 Defining outputs for your module...${RESET_FORMAT}"
echo

cat > outputs.tf <<EOF
output "bucket" {
    description = "The created storage bucket"
    value       = google_storage_bucket.bucket
}
EOF

cd ~

echo "${YELLOW_TEXT}${BOLD_TEXT}🛠️ Creating main Terraform file to use your new module...${RESET_FORMAT}"
echo

cat > main.tf <<EOF
module "gcs-static-website-bucket" {
    source = "./modules/gcs-static-website-bucket"
    name       = var.name
    project_id = var.project_id
    location   = "$REGION"
    lifecycle_rules = [{
        action = {
            type = "Delete"
        }
        condition = {
            age        = 365
            with_state = "ANY"
        }
    }]
}
EOF

echo "${CYAN_TEXT}${BOLD_TEXT}📤 Creating outputs file for your root module...${RESET_FORMAT}"
echo

cat > outputs.tf <<EOF
output "bucket-name" {
    description = "Bucket names."
    value       = "module.gcs-static-website-bucket.bucket"
}
EOF

echo "${MAGENTA_TEXT}${BOLD_TEXT}📦 Creating variables file for your root module...${RESET_FORMAT}"
echo

cat > variables.tf <<EOF
variable "project_id" {
    description = "The ID of the project in which to provision resources."
    type        = string
    default     = "$DEVSHELL_PROJECT_ID"
}
variable "name" {
    description = "Name of the buckets to create."
    type        = string
    default     = "$DEVSHELL_PROJECT_ID"
}
EOF

echo "${BLUE_TEXT}${BOLD_TEXT}⚙️ Initializing Terraform for your new setup...${RESET_FORMAT}"
echo

terraform init

echo "${GREEN_TEXT}${BOLD_TEXT}🚧 Applying Terraform configuration to provision your GCS bucket...${RESET_FORMAT}"
echo

terraform apply --auto-approve

cd ~
echo "${YELLOW_TEXT}${BOLD_TEXT}🪣 Creating a new Cloud Storage bucket using gsutil...${RESET_FORMAT}"
echo

gsutil mb gs://$DEVSHELL_PROJECT_ID

echo "${CYAN_TEXT}${BOLD_TEXT}🌐 Downloading sample website files for your bucket...${RESET_FORMAT}"
echo

curl https://raw.githubusercontent.com/hashicorp/learn-terraform-modules/master/modules/aws-s3-static-website-bucket/www/index.html > index.html
curl https://raw.githubusercontent.com/hashicorp/learn-terraform-modules/blob/master/modules/aws-s3-static-website-bucket/www/error.html > error.html

echo "${GREEN_TEXT}${BOLD_TEXT}📤 Uploading website files to your bucket...${RESET_FORMAT}"
echo

gsutil cp *.html gs://$DEVSHELL_PROJECT_ID

echo
echo "${RED}${BOLD}Congratulations${RESET}" "${WHITE}${BOLD}for${RESET}" "${GREEN}${BOLD}Completing the Lab !!!${RESET}"

echo "" 
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe to my Channel (Arcade With Us):${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://youtube.com/@arcadewithus_we?si=yeEby5M3k40gdX4l${RESET_FORMAT}"
echo
#-----------------------------------------------------end----------------------------------------------------------#
