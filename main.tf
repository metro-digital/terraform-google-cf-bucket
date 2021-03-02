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
        storage_class = lookup(lifecycle_rule.value.action, "storage_class", null)
      }
      condition {
        age                   = lookup(lifecycle_rule.value.condition, "age", null)
        created_before        = lookup(lifecycle_rule.value.condition, "created_before", null)
        with_state            = lookup(lifecycle_rule.value.condition, "with_state", null)
        matches_storage_class = contains(keys(lifecycle_rule.value.condition), "matches_storage_class") ? split(",", lifecycle_rule.value.condition["matches_storage_class"]) : null
        num_newer_versions    = lookup(lifecycle_rule.value.condition, "num_newer_versions", null)
      }
    }
  }

  versioning {
    enabled = var.versioning
  }

  dynamic "logging" {
    for_each = var.logging
    content {
      log_bucket        = logging.value.log_bucket
      log_object_prefix = lookup(logging.value, "log_object_prefix", null)
    }
  }

  dynamic "encryption" {
    for_each = var.encryption
    content {
      default_kms_key_name = encryption.value.default_kms_key_name
    }
  }
}
