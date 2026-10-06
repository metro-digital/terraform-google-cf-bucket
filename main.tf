# Copyright 2024 METRO Digital GmbH
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

# Object versioning is an explicit caller choice; soft deletion provides default recovery.
#trivy:ignore:GCP-0078
resource "google_storage_bucket" "bucket" {
  provider                    = google
  name                        = var.name
  project                     = var.project_id
  location                    = var.location
  storage_class               = var.storage_class
  labels                      = local.labels
  uniform_bucket_level_access = var.uniform_access

  dynamic "lifecycle_rule" {
    for_each = var.lifecycle_rules

    content {
      action {
        type          = lifecycle_rule.value.action.type
        storage_class = lifecycle_rule.value.action.storage_class
      }
      condition {
        age                   = lifecycle_rule.value.condition.age
        created_before        = lifecycle_rule.value.condition.created_before
        with_state            = lifecycle_rule.value.condition.with_state
        matches_storage_class = lifecycle_rule.value.condition.matches_storage_class
        num_newer_versions    = lifecycle_rule.value.condition.num_newer_versions
      }
    }
  }

  versioning {
    enabled = var.versioning
  }

  dynamic "logging" {
    for_each = var.logging == null ? [] : [var.logging]
    content {
      log_bucket        = logging.value.log_bucket
      log_object_prefix = logging.value.log_object_prefix
    }
  }

  dynamic "encryption" {
    for_each = var.encryption == null ? [] : [var.encryption]
    content {
      default_kms_key_name = encryption.value.default_kms_key_name

      dynamic "google_managed_encryption_enforcement_config" {
        for_each = encryption.value.google_managed_encryption_enforcement_config == null ? [] : [encryption.value.google_managed_encryption_enforcement_config]
        content {
          restriction_mode = google_managed_encryption_enforcement_config.value.restriction_mode
        }
      }

      dynamic "customer_managed_encryption_enforcement_config" {
        for_each = encryption.value.customer_managed_encryption_enforcement_config == null ? [] : [encryption.value.customer_managed_encryption_enforcement_config]
        content {
          restriction_mode = customer_managed_encryption_enforcement_config.value.restriction_mode
        }
      }

      dynamic "customer_supplied_encryption_enforcement_config" {
        for_each = encryption.value.customer_supplied_encryption_enforcement_config == null ? [] : [encryption.value.customer_supplied_encryption_enforcement_config]
        content {
          restriction_mode = customer_supplied_encryption_enforcement_config.value.restriction_mode
        }
      }
    }
  }

  soft_delete_policy {
    retention_duration_seconds = var.soft_delete_retention_duration_seconds
  }

  public_access_prevention = var.public_access_prevention
}
