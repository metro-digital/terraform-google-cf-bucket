# Copyright 2021 METRO Digital GmbH
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

variable "name" {
  description = "Bucket name"
  type        = string
}

variable "project_id" {
  description = "GCP project ID"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,30}[a-z0-9]", var.project_id))
    error_message = "The ID of the project. It must be 6 to 30 lowercase letters, digits, or hyphens. It must start with a letter. Trailing hyphens are prohibited."
  }
}
variable "location" {
  description = "The GCS location - see https://cloud.google.com/storage/docs/bucket-locations"
  type        = string
  default     = "EU"
}

variable "storage_class" {
  description = "Bucket's Storage Class"
  type        = string
  default     = "REGIONAL"
}

variable "uniform_access" {
  description = "Enables Uniform bucket-level access to a bucket"
  type        = bool
  default     = true
}

variable "lifecycle_rules" {
  description = <<-EOD
    List of lifecycle rules to configure. Format is the same as described in provider documentation https://www.terraform.io/docs/providers/google/r/storage_bucket.html#lifecycle_rule except condition.matches_storage_class should be a comma delimited string.
    
    Set of objects:
      action:
        map
          * type - The type of the action of this Lifecycle Rule. Supported values: Delete and SetStorageClass.
          * storage_class - (Required if action type is SetStorageClass) The target Storage Class of objects affected by this Lifecycle Rule.

      condition:
        map:
          * age - (Optional) Minimum age of an object in days to satisfy this condition.
          * created_before - (Optional) Creation date of an object in RFC 3339 (e.g. 2017-06-13) to satisfy this condition.
          * with_state - (Optional) Match to live and/or archived objects. Supported values include: "LIVE", "ARCHIVED", "ANY".
          * matches_storage_class - (Optional) Comma delimited string for storage class of objects to satisfy this condition. Supported values include: MULTI_REGIONAL, REGIONAL, NEARLINE, COLDLINE, STANDARD, DURABLE_REDUCED_AVAILABILITY.
          * num_newer_versions - (Optional) Relevant only for versioned objects. The number of newer versions of an object to satisfy this condition.

    Examples:
    ```
    lifecycle_rules = [
      {
        action = {
          type          = "SetStorageClass"
          storage_class = "NEARLINE"
        },
        condition = {
          age                   = "7"
          matches_storage_class = "REGIONAL"
        }
      },
      {
        action = {
          type          = "SetStorageClass"
          storage_class = "COLDLINE"
        },
        condition = {
          age                   = "30"
          matches_storage_class = "NEARLINE"
        }
      },
    ]
    ```
  EOD
  type = set(object({
    action    = map(string)
    condition = map(string)
  }))
  default = []
}

variable "versioning" {
  description = "Enable Versioning"
  type        = bool
  default     = false
}

variable "labels" {
  description = "A set of key/value label pairs to assign to the bucket"
  type        = map(string)
  default     = {}
}

variable "logging" {
  description = <<-EOD
    Bucket's Access & Storage Logs configuration

    The logging block supports:
      * log_bucket - (Required) The bucket that will receive log objects.
      * log_object_prefix - (Optional, Computed) The object prefix for log objects. If it's not provided, by default GCS sets this to this bucket's name.

    Example:
    ```
    logging = [{
      log_bucket        = "some-bucket-to-log-into"
      log_object_prefix = "my-prefix"
    }]
    ```
  EOD
  type = set(object({
    log_bucket        = string
    log_object_prefix = optional(string)
  }))
  validation {
    condition     = length(var.logging) == 1 || length(var.logging) == 0
    error_message = "Only one logging configuration per bucket is possible."
  }
  default = []
}

variable "encryption" {
  description = "Bucket's encryption configuration. Please provide the id of a Cloud KMS key that will be used to encrypt objects inserted into this bucket, if no encryption method is specified. You must pay attention to whether the crypto key is available in the location that this bucket is created in"
  type        = list(string)
  validation {
    condition     = length(var.encryption) == 1 || length(var.encryption) == 0
    error_message = "Only one encryption configuration per bucket is possible."
  }
  default = []
}

/**************************************************************************************************/
/*                                                                                                */
/* IAM                                                                                            */
/*                                                                                                */
/**************************************************************************************************/
variable "storage_admins" {
  type        = list(string)
  description = "list of users with role roles/storage.admin on project level"
  default     = []
}

variable "storage_object_admins" {
  type        = list(string)
  description = "list of users with role roles/storage.objectAdmin on project level"
  default     = []
}

variable "storage_object_creators" {
  type        = list(string)
  description = "list of users with role roles/storage.objectCreator on project level"
  default     = []
}

variable "storage_object_viewers" {
  type        = list(string)
  description = "list of users with role roles/storage.objectViewer on project level"
  default     = []
}

