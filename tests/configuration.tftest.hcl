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

run "logging_with_prefix" {
  command = plan
  variables {
    logging = { log_bucket = "cf-logs", log_object_prefix = "audit/" }
  }

  assert {
    condition     = one(google_storage_bucket.bucket.logging).log_bucket == "cf-logs" && one(google_storage_bucket.bucket.logging).log_object_prefix == "audit/"
    error_message = "Logging destination and prefix must be forwarded."
  }
}

run "logging_without_prefix" {
  command = plan
  variables {
    logging = { log_bucket = "cf-logs" }
  }

  assert {
    condition     = one(google_storage_bucket.bucket.logging).log_bucket == "cf-logs"
    error_message = "Logging must accept an omitted optional prefix."
  }
}

run "encryption_default_key" {
  command = plan
  variables {
    encryption = { default_kms_key_name = "projects/cf-unit-test/locations/eu/keyRings/test/cryptoKeys/bucket" }
  }

  assert {
    condition     = one(google_storage_bucket.bucket.encryption).default_kms_key_name == "projects/cf-unit-test/locations/eu/keyRings/test/cryptoKeys/bucket"
    error_message = "The encryption input must accept a KMS key string."
  }
}

run "lifecycle_rules" {
  command = plan
  variables {
    versioning = true
    lifecycle_rules = [
      { action = { type = "Delete" }, condition = { num_newer_versions = 30, with_state = "ARCHIVED" } },
      { action = { type = "SetStorageClass", storage_class = "NEARLINE" }, condition = { age = 7, created_before = "2025-01-01", matches_storage_class = ["STANDARD", "REGIONAL"], with_state = "LIVE" } }
    ]
  }

  assert {
    condition     = length(google_storage_bucket.bucket.lifecycle_rule) == 2
    error_message = "Both lifecycle rules must be emitted."
  }

  assert {
    condition     = length([for rule in google_storage_bucket.bucket.lifecycle_rule : rule if one(rule.action).type == "Delete" && one(rule.condition).num_newer_versions == 30 && one(rule.condition).with_state == "ARCHIVED"]) == 1
    error_message = "Deletion must retain the version count and archived state."
  }

  assert {
    condition     = length([for rule in google_storage_bucket.bucket.lifecycle_rule : rule if one(rule.action).type == "SetStorageClass" && one(rule.action).storage_class == "NEARLINE" && one(rule.condition).age == 7 && one(rule.condition).created_before == "2025-01-01" && one(rule.condition).with_state == "LIVE" && toset(one(rule.condition).matches_storage_class) == toset(["STANDARD", "REGIONAL"])]) == 1
    error_message = "Transitions must convert string numbers and comma-separated classes."
  }
}

run "soft_delete_disabled" {
  command = plan
  variables {
    soft_delete_retention_duration_seconds = 0
  }

  assert {
    condition     = one(google_storage_bucket.bucket.soft_delete_policy).retention_duration_seconds == 0
    error_message = "Soft-delete configuration must accept the boundary value."
  }
}

run "soft_delete_minimum" {
  command = plan
  variables {
    soft_delete_retention_duration_seconds = 604800
  }

  assert {
    condition     = one(google_storage_bucket.bucket.soft_delete_policy).retention_duration_seconds == 604800
    error_message = "Soft-delete configuration must accept the boundary value."
  }
}

run "soft_delete_maximum" {
  command = plan
  variables {
    soft_delete_retention_duration_seconds = 7776000
  }

  assert {
    condition     = one(google_storage_bucket.bucket.soft_delete_policy).retention_duration_seconds == 7776000
    error_message = "Soft-delete configuration must accept the boundary value."
  }
}

run "public_access_enforced" {
  command = plan
  variables {
    public_access_prevention = "enforced"
  }

  assert {
    condition     = google_storage_bucket.bucket.public_access_prevention == "enforced"
    error_message = "Public-access enforcement must reach the bucket."
  }
}

run "explicit_null_optional_blocks" {
  command = plan
  variables {
    logging    = null
    encryption = null
  }

  assert {
    condition     = length(google_storage_bucket.bucket.logging) == 0 && length(google_storage_bucket.bucket.encryption) == 0
    error_message = "Null inputs must omit optional blocks."
  }
}

run "empty_encryption_object" {
  command = plan
  variables { encryption = {} }
  assert {
    condition     = length(google_storage_bucket.bucket.encryption) == 1 && one(google_storage_bucket.bucket.encryption).default_kms_key_name == null && length(one(google_storage_bucket.bucket.encryption).google_managed_encryption_enforcement_config) == 0 && length(one(google_storage_bucket.bucket.encryption).customer_managed_encryption_enforcement_config) == 0 && length(one(google_storage_bucket.bucket.encryption).customer_supplied_encryption_enforcement_config) == 0
    error_message = "An empty encryption object must not add a default key or enforcement rules."
  }
}

run "google_managed_fullyrestricted" {
  command = plan
  variables {
    encryption = { google_managed_encryption_enforcement_config = { restriction_mode = "FullyRestricted" } }
  }
  assert {
    condition     = one(one(google_storage_bucket.bucket.encryption).google_managed_encryption_enforcement_config).restriction_mode == "FullyRestricted" && length(one(google_storage_bucket.bucket.encryption).customer_managed_encryption_enforcement_config) == 0 && length(one(google_storage_bucket.bucket.encryption).customer_supplied_encryption_enforcement_config) == 0
    error_message = "The selected restriction must be forwarded without adding other enforcement blocks."
  }
}

run "google_managed_notrestricted" {
  command = plan
  variables {
    encryption = { google_managed_encryption_enforcement_config = { restriction_mode = "NotRestricted" } }
  }
  assert {
    condition     = one(one(google_storage_bucket.bucket.encryption).google_managed_encryption_enforcement_config).restriction_mode == "NotRestricted" && length(one(google_storage_bucket.bucket.encryption).customer_managed_encryption_enforcement_config) == 0 && length(one(google_storage_bucket.bucket.encryption).customer_supplied_encryption_enforcement_config) == 0
    error_message = "The selected restriction must be forwarded without adding other enforcement blocks."
  }
}

run "customer_managed_fullyrestricted" {
  command = plan
  variables {
    encryption = { customer_managed_encryption_enforcement_config = { restriction_mode = "FullyRestricted" } }
  }
  assert {
    condition     = one(one(google_storage_bucket.bucket.encryption).customer_managed_encryption_enforcement_config).restriction_mode == "FullyRestricted" && length(one(google_storage_bucket.bucket.encryption).google_managed_encryption_enforcement_config) == 0 && length(one(google_storage_bucket.bucket.encryption).customer_supplied_encryption_enforcement_config) == 0
    error_message = "The selected restriction must be forwarded without adding other enforcement blocks."
  }
}

run "customer_managed_notrestricted" {
  command = plan
  variables {
    encryption = { customer_managed_encryption_enforcement_config = { restriction_mode = "NotRestricted" } }
  }
  assert {
    condition     = one(one(google_storage_bucket.bucket.encryption).customer_managed_encryption_enforcement_config).restriction_mode == "NotRestricted" && length(one(google_storage_bucket.bucket.encryption).google_managed_encryption_enforcement_config) == 0 && length(one(google_storage_bucket.bucket.encryption).customer_supplied_encryption_enforcement_config) == 0
    error_message = "The selected restriction must be forwarded without adding other enforcement blocks."
  }
}

run "customer_supplied_fullyrestricted" {
  command = plan
  variables {
    encryption = { customer_supplied_encryption_enforcement_config = { restriction_mode = "FullyRestricted" } }
  }
  assert {
    condition     = one(one(google_storage_bucket.bucket.encryption).customer_supplied_encryption_enforcement_config).restriction_mode == "FullyRestricted" && length(one(google_storage_bucket.bucket.encryption).google_managed_encryption_enforcement_config) == 0 && length(one(google_storage_bucket.bucket.encryption).customer_managed_encryption_enforcement_config) == 0
    error_message = "The selected restriction must be forwarded without adding other enforcement blocks."
  }
}

run "customer_supplied_notrestricted" {
  command = plan
  variables {
    encryption = { customer_supplied_encryption_enforcement_config = { restriction_mode = "NotRestricted" } }
  }
  assert {
    condition     = one(one(google_storage_bucket.bucket.encryption).customer_supplied_encryption_enforcement_config).restriction_mode == "NotRestricted" && length(one(google_storage_bucket.bucket.encryption).google_managed_encryption_enforcement_config) == 0 && length(one(google_storage_bucket.bucket.encryption).customer_managed_encryption_enforcement_config) == 0
    error_message = "The selected restriction must be forwarded without adding other enforcement blocks."
  }
}

run "google_managed_only" {
  command = plan
  variables {
    encryption = {
      google_managed_encryption_enforcement_config    = { restriction_mode = "NotRestricted" }
      customer_managed_encryption_enforcement_config  = { restriction_mode = "FullyRestricted" }
      customer_supplied_encryption_enforcement_config = { restriction_mode = "FullyRestricted" }
    }
  }
  assert {
    condition     = one(one(google_storage_bucket.bucket.encryption).google_managed_encryption_enforcement_config).restriction_mode == "NotRestricted" && one(one(google_storage_bucket.bucket.encryption).customer_managed_encryption_enforcement_config).restriction_mode == "FullyRestricted" && one(one(google_storage_bucket.bucket.encryption).customer_supplied_encryption_enforcement_config).restriction_mode == "FullyRestricted"
    error_message = "The policy must allow exactly the selected encryption type. Google-managed-only must work without a KMS key."
  }
}

run "customer_managed_only" {
  command = plan
  variables {
    encryption = {
      google_managed_encryption_enforcement_config    = { restriction_mode = "FullyRestricted" }
      customer_managed_encryption_enforcement_config  = { restriction_mode = "NotRestricted" }
      customer_supplied_encryption_enforcement_config = { restriction_mode = "FullyRestricted" }
    }
  }
  assert {
    condition     = one(one(google_storage_bucket.bucket.encryption).google_managed_encryption_enforcement_config).restriction_mode == "FullyRestricted" && one(one(google_storage_bucket.bucket.encryption).customer_managed_encryption_enforcement_config).restriction_mode == "NotRestricted" && one(one(google_storage_bucket.bucket.encryption).customer_supplied_encryption_enforcement_config).restriction_mode == "FullyRestricted"
    error_message = "The policy must allow exactly the selected encryption type. Google-managed-only must work without a KMS key."
  }
}

run "customer_supplied_only" {
  command = plan
  variables {
    encryption = {
      google_managed_encryption_enforcement_config    = { restriction_mode = "FullyRestricted" }
      customer_managed_encryption_enforcement_config  = { restriction_mode = "FullyRestricted" }
      customer_supplied_encryption_enforcement_config = { restriction_mode = "NotRestricted" }
    }
  }
  assert {
    condition     = one(one(google_storage_bucket.bucket.encryption).google_managed_encryption_enforcement_config).restriction_mode == "FullyRestricted" && one(one(google_storage_bucket.bucket.encryption).customer_managed_encryption_enforcement_config).restriction_mode == "FullyRestricted" && one(one(google_storage_bucket.bucket.encryption).customer_supplied_encryption_enforcement_config).restriction_mode == "NotRestricted"
    error_message = "The policy must allow exactly the selected encryption type. Google-managed-only must work without a KMS key."
  }
}

run "kms_with_explicit_permissions" {
  command = plan
  variables {
    encryption = {
      default_kms_key_name                            = "projects/cf-unit-test/locations/eu/keyRings/test/cryptoKeys/bucket"
      customer_managed_encryption_enforcement_config  = { restriction_mode = "NotRestricted" }
      customer_supplied_encryption_enforcement_config = { restriction_mode = "FullyRestricted" }
    }
  }
  assert {
    condition     = one(google_storage_bucket.bucket.encryption).default_kms_key_name == "projects/cf-unit-test/locations/eu/keyRings/test/cryptoKeys/bucket" && one(one(google_storage_bucket.bucket.encryption).customer_managed_encryption_enforcement_config).restriction_mode == "NotRestricted" && one(one(google_storage_bucket.bucket.encryption).customer_supplied_encryption_enforcement_config).restriction_mode == "FullyRestricted"
    error_message = "A default KMS key and compatible enforcement settings must be preserved together."
  }
}
