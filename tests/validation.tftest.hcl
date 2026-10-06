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

mock_provider "google" {
  source = "./tests/mocks"
}

variables {
  name       = "cf-unit-test-bucket"
  project_id = "cf-unit-test"
}

run "project_id_minimum" {
  command = plan
  variables {
    project_id = "abcdef"
  }

  assert {
    condition     = output.project == "abcdef"
    error_message = "Valid project-ID boundaries must be accepted."
  }
}

run "project_id_maximum" {
  command = plan
  variables {
    project_id = "abbbbbbbbbbbbbbbbbbbbbbbbbbbb1"
  }

  assert {
    condition     = output.project == "abbbbbbbbbbbbbbbbbbbbbbbbbbbb1"
    error_message = "Valid project-ID boundaries must be accepted."
  }
}

run "project_id_too_short" {
  command = plan
  variables {
    project_id = "abcde"
  }
  expect_failures = [var.project_id]
}

run "project_id_too_long" {
  command = plan
  variables {
    project_id = "abbbbbbbbbbbbbbbbbbbbbbbbbbbbb1"
  }
  expect_failures = [var.project_id]
}

run "project_id_trailing_hyphen" {
  command = plan
  variables {
    project_id = "valid-project-"
  }
  expect_failures = [var.project_id]
}

run "project_id_trailing_invalid_character" {
  command = plan
  variables {
    project_id = "valid-project!"
  }
  expect_failures = [var.project_id]
}

run "project_id_uppercase" {
  command = plan
  variables {
    project_id = "Valid-project"
  }
  expect_failures = [var.project_id]
}

run "project_id_leading_digit" {
  command = plan
  variables {
    project_id = "1valid-project"
  }
  expect_failures = [var.project_id]
}

run "empty_logging" {
  command = plan
  variables {
    logging = { log_bucket = " " }
  }
  expect_failures = [var.logging]
}

run "invalid_kms_key" {
  command = plan
  variables {
    encryption = { default_kms_key_name = "some-key" }
  }
  expect_failures = [var.encryption]
}

run "invalid_storage_class" {
  command = plan
  variables {
    storage_class = "INVALID"
  }
  expect_failures = [var.storage_class]
}

run "invalid_public_access" {
  command = plan
  variables {
    public_access_prevention = "disabled"
  }
  expect_failures = [var.public_access_prevention]
}

run "negative_soft_delete" {
  command = plan
  variables {
    soft_delete_retention_duration_seconds = -1
  }
  expect_failures = [var.soft_delete_retention_duration_seconds]
}

run "soft_delete_below_minimum" {
  command = plan
  variables {
    soft_delete_retention_duration_seconds = 604799
  }
  expect_failures = [var.soft_delete_retention_duration_seconds]
}

run "soft_delete_above_maximum" {
  command = plan
  variables {
    soft_delete_retention_duration_seconds = 7776001
  }
  expect_failures = [var.soft_delete_retention_duration_seconds]
}

run "fractional_soft_delete" {
  command = plan
  variables {
    soft_delete_retention_duration_seconds = 604800.5
  }
  expect_failures = [var.soft_delete_retention_duration_seconds]
}

run "invalid_iam_role" {
  command = plan
  variables {
    iam_bindings = { "storage.objectViewer" = ["user:test@example.com"] }
  }
  expect_failures = [var.iam_bindings]
}

run "null_iam_members" {
  command = plan
  variables {
    iam_bindings = { "roles/storage.objectViewer" = null }
  }
  expect_failures = [var.iam_bindings]
}

run "null_iam_member" {
  command = plan
  variables {
    iam_bindings = { "roles/storage.objectViewer" = [null] }
  }
  expect_failures = [var.iam_bindings]
}

run "invalid_lifecycle_action" {
  command = plan
  variables {
    lifecycle_rules = [{ action = { type = "Archive" }, condition = { age = 7 } }]
  }
  expect_failures = [var.lifecycle_rules]
}

run "transition_without_class" {
  command = plan
  variables {
    lifecycle_rules = [{ action = { type = "SetStorageClass" }, condition = { age = 7 } }]
  }
  expect_failures = [var.lifecycle_rules]
}

run "invalid_transition_class" {
  command = plan
  variables {
    lifecycle_rules = [{ action = { type = "SetStorageClass", storage_class = "INVALID" }, condition = { age = 7 } }]
  }
  expect_failures = [var.lifecycle_rules]
}

run "delete_with_class" {
  command = plan
  variables {
    lifecycle_rules = [{ action = { type = "Delete", storage_class = "NEARLINE" }, condition = { age = 7 } }]
  }
  expect_failures = [var.lifecycle_rules]
}

run "empty_lifecycle_condition" {
  command = plan
  variables {
    lifecycle_rules = [{ action = { type = "Delete" }, condition = {} }]
  }
  expect_failures = [var.lifecycle_rules]
}

run "negative_age" {
  command = plan
  variables {
    lifecycle_rules = [{ action = { type = "Delete" }, condition = { age = -1 } }]
  }
  expect_failures = [var.lifecycle_rules]
}

run "fractional_age" {
  command = plan
  variables {
    lifecycle_rules = [{ action = { type = "Delete" }, condition = { age = 1.5 } }]
  }
  expect_failures = [var.lifecycle_rules]
}

run "zero_version_count" {
  command = plan
  variables {
    lifecycle_rules = [{ action = { type = "Delete" }, condition = { num_newer_versions = 0 } }]
  }
  expect_failures = [var.lifecycle_rules]
}

run "fractional_version_count" {
  command = plan
  variables {
    lifecycle_rules = [{ action = { type = "Delete" }, condition = { num_newer_versions = 1.5 } }]
  }
  expect_failures = [var.lifecycle_rules]
}

run "invalid_lifecycle_state" {
  command = plan
  variables {
    lifecycle_rules = [{ action = { type = "Delete" }, condition = { with_state = "DELETED" } }]
  }
  expect_failures = [var.lifecycle_rules]
}

run "invalid_lifecycle_date" {
  command = plan
  variables {
    lifecycle_rules = [{ action = { type = "Delete" }, condition = { created_before = "2025-13-01" } }]
  }
  expect_failures = [var.lifecycle_rules]
}

run "invalid_date_format" {
  command = plan
  variables {
    lifecycle_rules = [{ action = { type = "Delete" }, condition = { created_before = "2025-1-1" } }]
  }
  expect_failures = [var.lifecycle_rules]
}

run "empty_matching_classes" {
  command = plan
  variables {
    lifecycle_rules = [{ action = { type = "Delete" }, condition = { matches_storage_class = [] } }]
  }
  expect_failures = [var.lifecycle_rules]
}

run "invalid_matching_class" {
  command = plan
  variables {
    lifecycle_rules = [{ action = { type = "Delete" }, condition = { matches_storage_class = ["INVALID"] } }]
  }
  expect_failures = [var.lifecycle_rules]
}


run "zero_age_condition" {
  command = plan
  variables {
    lifecycle_rules = [{ action = { type = "Delete" }, condition = { age = 0 } }]
  }
  expect_failures = [var.lifecycle_rules]
}

run "invalid_google_managed_restriction" {
  command = plan
  variables { encryption = { google_managed_encryption_enforcement_config = { restriction_mode = "Restricted" } } }
  expect_failures = [var.encryption]
}

run "invalid_customer_managed_restriction" {
  command = plan
  variables { encryption = { customer_managed_encryption_enforcement_config = { restriction_mode = "Restricted" } } }
  expect_failures = [var.encryption]
}

run "invalid_customer_supplied_restriction" {
  command = plan
  variables { encryption = { customer_supplied_encryption_enforcement_config = { restriction_mode = "Restricted" } } }
  expect_failures = [var.encryption]
}

run "null_encryption_restriction_mode" {
  command = plan
  variables { encryption = { google_managed_encryption_enforcement_config = { restriction_mode = null } } }
  expect_failures = [var.encryption]
}

run "all_encryption_types_restricted" {
  command = plan
  variables {
    encryption = {
      google_managed_encryption_enforcement_config    = { restriction_mode = "FullyRestricted" }
      customer_managed_encryption_enforcement_config  = { restriction_mode = "FullyRestricted" }
      customer_supplied_encryption_enforcement_config = { restriction_mode = "FullyRestricted" }
    }
  }
  expect_failures = [var.encryption]
}

run "kms_with_customer_encryption_restricted" {
  command = plan
  variables {
    encryption = {
      default_kms_key_name                            = "projects/cf-unit-test/locations/eu/keyRings/test/cryptoKeys/bucket"
      customer_managed_encryption_enforcement_config  = { restriction_mode = "FullyRestricted" }
      customer_supplied_encryption_enforcement_config = { restriction_mode = "FullyRestricted" }
    }
  }
  expect_failures = [var.encryption]
}

run "empty_kms_key" {
  command = plan
  variables { encryption = { default_kms_key_name = "" } }
  expect_failures = [var.encryption]
}

run "kms_key_version_path" {
  command = plan
  variables { encryption = { default_kms_key_name = "projects/cf-unit-test/locations/eu/keyRings/test/cryptoKeys/bucket/cryptoKeyVersions/1" } }
  expect_failures = [var.encryption]
}
