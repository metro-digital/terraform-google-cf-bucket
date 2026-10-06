# Copyright 2026 METRO Digital GmbH
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
  description = "Bucket name. Existing buckets must retain their current name."
  type        = string
  nullable    = false
}

variable "project_id" {
  description = "GCP project ID."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "The project ID must be 6 to 30 lowercase letters, digits, or hyphens, start with a letter and end with a letter or digit."
  }
}

variable "location" {
  description = "GCS location. Changing an existing bucket's location requires replacement."
  type        = string
  default     = "EU"
  nullable    = false
}

variable "storage_class" {
  description = "Bucket storage class. Specify the previous value explicitly when upgrading an existing bucket."
  type        = string
  default     = "STANDARD"
  nullable    = false

  validation {
    condition     = contains(["STANDARD", "NEARLINE", "COLDLINE", "ARCHIVE", "REGIONAL", "MULTI_REGIONAL", "DURABLE_REDUCED_AVAILABILITY"], var.storage_class)
    error_message = "Use a supported Google Cloud Storage class: STANDARD, NEARLINE, COLDLINE, ARCHIVE, REGIONAL, MULTI_REGIONAL or DURABLE_REDUCED_AVAILABILITY."
  }
}

variable "uniform_access" {
  description = "Enable uniform bucket-level access. Disabling it adds the Cloud Foundation exemption label."
  type        = bool
  default     = true
  nullable    = false
}

variable "lifecycle_rules" {
  description = "Lifecycle rules with typed actions and conditions. Numbers are expressed in days or version counts; matches_storage_class is a set of class names."
  type = set(object({
    action = object({
      type          = string
      storage_class = optional(string)
    })
    condition = object({
      age                   = optional(number)
      created_before        = optional(string)
      with_state            = optional(string)
      matches_storage_class = optional(set(string))
      num_newer_versions    = optional(number)
    })
  }))
  default  = []
  nullable = false

  validation {
    condition = alltrue([for rule in var.lifecycle_rules : (
      rule.action.type == "Delete" ? rule.action.storage_class == null : (
        rule.action.type == "SetStorageClass" && (rule.action.storage_class == null ? false :
        contains(["STANDARD", "NEARLINE", "COLDLINE", "ARCHIVE", "REGIONAL", "MULTI_REGIONAL", "DURABLE_REDUCED_AVAILABILITY"], rule.action.storage_class))
      )
    )])
    error_message = "Lifecycle actions must be Delete without storage_class, or SetStorageClass with a supported storage_class."
  }

  validation {
    condition = alltrue([for rule in var.lifecycle_rules : (
      (rule.condition.age == null ? true : rule.condition.age > 0 && floor(rule.condition.age) == rule.condition.age) &&
      (rule.condition.num_newer_versions == null ? true : rule.condition.num_newer_versions >= 1 && floor(rule.condition.num_newer_versions) == rule.condition.num_newer_versions) &&
      (rule.condition.with_state == null ? true : contains(["LIVE", "ARCHIVED", "ANY"], rule.condition.with_state)) &&
      (rule.condition.created_before == null ? true : can(regex("^[0-9]{4}-[0-9]{2}-[0-9]{2}$", rule.condition.created_before)) && can(formatdate("YYYY-MM-DD", "${rule.condition.created_before}T00:00:00Z"))) &&
      (rule.condition.matches_storage_class == null ? true : length(rule.condition.matches_storage_class) > 0 && alltrue([
        for storage_class in rule.condition.matches_storage_class : contains(["STANDARD", "NEARLINE", "COLDLINE", "ARCHIVE", "REGIONAL", "MULTI_REGIONAL", "DURABLE_REDUCED_AVAILABILITY"], storage_class)
      ]))
    )])
    error_message = "Lifecycle conditions require whole positive age, whole positive version count, a valid YYYY-MM-DD date, LIVE/ARCHIVED/ANY state, and nonempty supported storage-class sets."
  }

  validation {
    condition = alltrue([for rule in var.lifecycle_rules : anytrue([
      rule.condition.age != null,
      rule.condition.created_before != null,
      rule.condition.with_state != null,
      rule.condition.matches_storage_class != null,
      rule.condition.num_newer_versions != null,
    ])])
    error_message = "Each lifecycle rule must specify at least one condition."
  }
}

variable "versioning" {
  description = "Enable object versioning."
  type        = bool
  default     = false
  nullable    = false
}

variable "labels" {
  description = "Key/value labels assigned to the bucket."
  type        = map(string)
  default     = {}
  nullable    = false
}

variable "logging" {
  description = "Optional access and storage logging destination. Set null to omit logging; log_object_prefix is optional."
  type = object({
    log_bucket        = string
    log_object_prefix = optional(string)
  })
  default = null

  validation {
    condition     = var.logging == null ? true : try(length(trimspace(var.logging.log_bucket)) > 0, false)
    error_message = "Logging requires a nonempty log_bucket."
  }
}

variable "encryption" {
  description = "Optional bucket encryption configuration. Null uses Google-managed encryption by default. Enforcement controls encryption types for new objects; KMS keys require compatible location and storage service-agent access."
  type = object({
    default_kms_key_name = optional(string)
    google_managed_encryption_enforcement_config = optional(object({
      restriction_mode = string
    }))
    customer_managed_encryption_enforcement_config = optional(object({
      restriction_mode = string
    }))
    customer_supplied_encryption_enforcement_config = optional(object({
      restriction_mode = string
    }))
  })
  default = null

  validation {
    condition = var.encryption == null ? true : (
      var.encryption.default_kms_key_name == null ? true :
      can(regex("^projects/[^/[:space:]]+/locations/[^/[:space:]]+/keyRings/[^/[:space:]]+/cryptoKeys/[^/[:space:]]+$", var.encryption.default_kms_key_name))
    )
    error_message = "default_kms_key_name must be null or a full projects/PROJECT/locations/LOCATION/keyRings/KEY_RING/cryptoKeys/KEY resource name."
  }

  validation {
    condition = var.encryption == null ? true : alltrue([
      for config in [
        var.encryption.google_managed_encryption_enforcement_config,
        var.encryption.customer_managed_encryption_enforcement_config,
        var.encryption.customer_supplied_encryption_enforcement_config,
      ] : config == null ? true : try(contains(["FullyRestricted", "NotRestricted"], config.restriction_mode), false)
    ])
    error_message = "Encryption restriction_mode must be FullyRestricted or NotRestricted."
  }

  validation {
    condition = var.encryption == null ? true : !alltrue([
      for config in [
        var.encryption.google_managed_encryption_enforcement_config,
        var.encryption.customer_managed_encryption_enforcement_config,
        var.encryption.customer_supplied_encryption_enforcement_config,
      ] : config == null ? false : config.restriction_mode == "FullyRestricted"
    ])
    error_message = "At least one encryption type must remain allowed."
  }

  validation {
    condition = var.encryption == null ? true : (
      var.encryption.default_kms_key_name == null ? true : !(
        try(var.encryption.customer_managed_encryption_enforcement_config.restriction_mode, null) == "FullyRestricted" &&
        try(var.encryption.customer_supplied_encryption_enforcement_config.restriction_mode, null) == "FullyRestricted"
      )
    )
    error_message = "A default KMS key cannot be combined with restrictions on both customer-managed and customer-supplied encryption. Remove the default KMS key or allow one of these types."
  }
}

variable "public_access_prevention" {
  description = "Public access prevention: inherited follows organization policy; enforced prevents public access on this bucket."
  type        = string
  default     = "inherited"
  nullable    = false

  validation {
    condition     = contains(["inherited", "enforced"], var.public_access_prevention)
    error_message = "Public access prevention must be inherited or enforced."
  }
}

variable "purge_legacy_roles" {
  description = "Remove default project owner/editor/viewer principals from legacy roles. Explicit iam_bindings are retained."
  type        = bool
  default     = false
  nullable    = false
}

variable "iam_bindings" {
  description = "Authoritative bucket IAM bindings, keyed by role, with sets of members. The module replaces the entire bucket policy. Default legacy principals are added unless purge_legacy_roles is true."
  type        = map(set(string))
  default     = {}
  nullable    = false

  validation {
    condition = alltrue([for role, members in var.iam_bindings :
      can(regex("^(roles/[A-Za-z0-9_.]+|projects/[^/[:space:]]+/roles/[A-Za-z0-9_.]+|organizations/[0-9]+/roles/[A-Za-z0-9_.]+)$", role)) &&
      (members == null ? false : alltrue([for member in members : member != null]))
    ])
    error_message = "IAM keys must be predefined or project/organization custom role names; member sets and their elements must not be null."
  }
}

variable "soft_delete_retention_duration_seconds" {
  description = "Whole seconds of soft-delete retention: 604800 (7 days) through 7776000 (90 days), or 0 to disable."
  type        = number
  default     = 604800
  nullable    = false

  validation {
    condition     = floor(var.soft_delete_retention_duration_seconds) == var.soft_delete_retention_duration_seconds && (var.soft_delete_retention_duration_seconds == 0 || (var.soft_delete_retention_duration_seconds >= 604800 && var.soft_delete_retention_duration_seconds <= 7776000))
    error_message = "Soft-delete retention must be a whole number of seconds from 604800 to 7776000, or 0 to disable."
  }
}
