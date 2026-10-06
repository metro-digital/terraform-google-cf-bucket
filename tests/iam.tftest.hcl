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

run "default_legacy_policy" {
  command = plan

  assert {
    condition     = toset(one([for binding in data.google_iam_policy.bucket.binding : binding.members if binding.role == "roles/storage.legacyBucketOwner"])) == toset(["projectEditor:cf-unit-test", "projectOwner:cf-unit-test"])
    error_message = "Default membership must remain stable for legacyBucketOwner."
  }

  assert {
    condition     = toset(one([for binding in data.google_iam_policy.bucket.binding : binding.members if binding.role == "roles/storage.legacyBucketReader"])) == toset(["projectViewer:cf-unit-test"])
    error_message = "Default membership must remain stable for legacyBucketReader."
  }

  assert {
    condition     = length(one([for binding in data.google_iam_policy.bucket.binding : binding.members if binding.role == "roles/storage.legacyBucketWriter"])) == 0
    error_message = "Default membership must remain stable for legacyBucketWriter."
  }

  assert {
    condition     = toset(one([for binding in data.google_iam_policy.bucket.binding : binding.members if binding.role == "roles/storage.legacyObjectOwner"])) == toset(["projectEditor:cf-unit-test", "projectOwner:cf-unit-test"])
    error_message = "Default membership must remain stable for legacyObjectOwner."
  }

  assert {
    condition     = toset(one([for binding in data.google_iam_policy.bucket.binding : binding.members if binding.role == "roles/storage.legacyObjectReader"])) == toset(["projectViewer:cf-unit-test"])
    error_message = "Default membership must remain stable for legacyObjectReader."
  }

  assert {
    condition     = length(one([for binding in data.google_iam_policy.bucket.binding : binding.members if binding.role == "roles/storage.admin"])) == 0
    error_message = "Default membership must remain stable for admin."
  }

  assert {
    condition     = length(one([for binding in data.google_iam_policy.bucket.binding : binding.members if binding.role == "roles/storage.objectAdmin"])) == 0
    error_message = "Default membership must remain stable for objectAdmin."
  }

  assert {
    condition     = length(one([for binding in data.google_iam_policy.bucket.binding : binding.members if binding.role == "roles/storage.objectCreator"])) == 0
    error_message = "Default membership must remain stable for objectCreator."
  }

  assert {
    condition     = length(one([for binding in data.google_iam_policy.bucket.binding : binding.members if binding.role == "roles/storage.objectViewer"])) == 0
    error_message = "Default membership must remain stable for objectViewer."
  }
}

run "additional_members_with_defaults" {
  command = plan
  variables {
    additional_legacy_bucket_owners  = ["user:legacyBucketOwner@example.com"]
    additional_legacy_bucket_readers = ["user:legacyBucketReader@example.com"]
    additional_legacy_bucket_writers = ["user:legacyBucketWriter@example.com"]
    additional_legacy_object_owners  = ["user:legacyObjectOwner@example.com"]
    additional_legacy_object_readers = ["user:legacyObjectReader@example.com"]
    storage_admins                   = ["user:admin@example.com"]
    storage_object_admins            = ["user:objectAdmin@example.com"]
    storage_object_creators          = ["user:objectCreator@example.com"]
    storage_object_viewers           = ["user:objectViewer@example.com"]
  }

  assert {
    condition     = toset(one([for binding in data.google_iam_policy.bucket.binding : binding.members if binding.role == "roles/storage.legacyBucketOwner"])) == toset(["user:legacyBucketOwner@example.com", "projectEditor:cf-unit-test", "projectOwner:cf-unit-test"])
    error_message = "Requested members and default principals must be combined for legacyBucketOwner."
  }

  assert {
    condition     = toset(one([for binding in data.google_iam_policy.bucket.binding : binding.members if binding.role == "roles/storage.legacyBucketReader"])) == toset(["user:legacyBucketReader@example.com", "projectViewer:cf-unit-test"])
    error_message = "Requested members and default principals must be combined for legacyBucketReader."
  }

  assert {
    condition     = toset(one([for binding in data.google_iam_policy.bucket.binding : binding.members if binding.role == "roles/storage.legacyBucketWriter"])) == toset(["user:legacyBucketWriter@example.com"])
    error_message = "Requested members and default principals must be combined for legacyBucketWriter."
  }

  assert {
    condition     = toset(one([for binding in data.google_iam_policy.bucket.binding : binding.members if binding.role == "roles/storage.legacyObjectOwner"])) == toset(["user:legacyObjectOwner@example.com", "projectEditor:cf-unit-test", "projectOwner:cf-unit-test"])
    error_message = "Requested members and default principals must be combined for legacyObjectOwner."
  }

  assert {
    condition     = toset(one([for binding in data.google_iam_policy.bucket.binding : binding.members if binding.role == "roles/storage.legacyObjectReader"])) == toset(["user:legacyObjectReader@example.com", "projectViewer:cf-unit-test"])
    error_message = "Requested members and default principals must be combined for legacyObjectReader."
  }

  assert {
    condition     = toset(one([for binding in data.google_iam_policy.bucket.binding : binding.members if binding.role == "roles/storage.admin"])) == toset(["user:admin@example.com"])
    error_message = "Requested members and default principals must be combined for admin."
  }

  assert {
    condition     = toset(one([for binding in data.google_iam_policy.bucket.binding : binding.members if binding.role == "roles/storage.objectAdmin"])) == toset(["user:objectAdmin@example.com"])
    error_message = "Requested members and default principals must be combined for objectAdmin."
  }

  assert {
    condition     = toset(one([for binding in data.google_iam_policy.bucket.binding : binding.members if binding.role == "roles/storage.objectCreator"])) == toset(["user:objectCreator@example.com"])
    error_message = "Requested members and default principals must be combined for objectCreator."
  }

  assert {
    condition     = toset(one([for binding in data.google_iam_policy.bucket.binding : binding.members if binding.role == "roles/storage.objectViewer"])) == toset(["user:objectViewer@example.com"])
    error_message = "Requested members and default principals must be combined for objectViewer."
  }
}

run "purge_retains_explicit_members" {
  command = plan
  variables {
    purge_legacy_roles               = true
    additional_legacy_bucket_owners  = ["user:legacyBucketOwner@example.com"]
    additional_legacy_bucket_readers = ["user:legacyBucketReader@example.com"]
    additional_legacy_bucket_writers = ["user:legacyBucketWriter@example.com"]
    additional_legacy_object_owners  = ["user:legacyObjectOwner@example.com"]
    additional_legacy_object_readers = ["user:legacyObjectReader@example.com"]
    storage_admins                   = ["user:admin@example.com"]
    storage_object_admins            = ["user:objectAdmin@example.com"]
    storage_object_creators          = ["user:objectCreator@example.com"]
    storage_object_viewers           = ["user:objectViewer@example.com"]
  }

  assert {
    condition     = toset(one([for binding in data.google_iam_policy.bucket.binding : binding.members if binding.role == "roles/storage.legacyBucketOwner"])) == toset(["user:legacyBucketOwner@example.com"])
    error_message = "Purging must retain only caller-specified membership for legacyBucketOwner."
  }

  assert {
    condition     = toset(one([for binding in data.google_iam_policy.bucket.binding : binding.members if binding.role == "roles/storage.legacyBucketReader"])) == toset(["user:legacyBucketReader@example.com"])
    error_message = "Purging must retain only caller-specified membership for legacyBucketReader."
  }

  assert {
    condition     = toset(one([for binding in data.google_iam_policy.bucket.binding : binding.members if binding.role == "roles/storage.legacyBucketWriter"])) == toset(["user:legacyBucketWriter@example.com"])
    error_message = "Purging must retain only caller-specified membership for legacyBucketWriter."
  }

  assert {
    condition     = toset(one([for binding in data.google_iam_policy.bucket.binding : binding.members if binding.role == "roles/storage.legacyObjectOwner"])) == toset(["user:legacyObjectOwner@example.com"])
    error_message = "Purging must retain only caller-specified membership for legacyObjectOwner."
  }

  assert {
    condition     = toset(one([for binding in data.google_iam_policy.bucket.binding : binding.members if binding.role == "roles/storage.legacyObjectReader"])) == toset(["user:legacyObjectReader@example.com"])
    error_message = "Purging must retain only caller-specified membership for legacyObjectReader."
  }

  assert {
    condition     = toset(one([for binding in data.google_iam_policy.bucket.binding : binding.members if binding.role == "roles/storage.admin"])) == toset(["user:admin@example.com"])
    error_message = "Purging must retain only caller-specified membership for admin."
  }

  assert {
    condition     = toset(one([for binding in data.google_iam_policy.bucket.binding : binding.members if binding.role == "roles/storage.objectAdmin"])) == toset(["user:objectAdmin@example.com"])
    error_message = "Purging must retain only caller-specified membership for objectAdmin."
  }

  assert {
    condition     = toset(one([for binding in data.google_iam_policy.bucket.binding : binding.members if binding.role == "roles/storage.objectCreator"])) == toset(["user:objectCreator@example.com"])
    error_message = "Purging must retain only caller-specified membership for objectCreator."
  }

  assert {
    condition     = toset(one([for binding in data.google_iam_policy.bucket.binding : binding.members if binding.role == "roles/storage.objectViewer"])) == toset(["user:objectViewer@example.com"])
    error_message = "Purging must retain only caller-specified membership for objectViewer."
  }
}

run "purge_all_legacy_defaults" {
  command = plan
  variables {
    purge_legacy_roles = true
  }

  assert {
    condition     = alltrue([for binding in data.google_iam_policy.bucket.binding : length(binding.members) == 0])
    error_message = "Purging without additional members must remove all default principals."
  }
}

run "compact_modern_members" {
  command = plan
  variables {
    storage_admins          = ["", "user:member@example.com"]
    storage_object_admins   = ["", "user:member@example.com"]
    storage_object_creators = ["", "user:member@example.com"]
    storage_object_viewers  = ["", "user:member@example.com"]
  }

  assert {
    condition     = toset(one([for binding in data.google_iam_policy.bucket.binding : binding.members if binding.role == "roles/storage.admin"])) == toset(["user:member@example.com"])
    error_message = "Empty modern-role members must be removed."
  }

  assert {
    condition     = toset(one([for binding in data.google_iam_policy.bucket.binding : binding.members if binding.role == "roles/storage.objectAdmin"])) == toset(["user:member@example.com"])
    error_message = "Empty modern-role members must be removed."
  }

  assert {
    condition     = toset(one([for binding in data.google_iam_policy.bucket.binding : binding.members if binding.role == "roles/storage.objectCreator"])) == toset(["user:member@example.com"])
    error_message = "Empty modern-role members must be removed."
  }

  assert {
    condition     = toset(one([for binding in data.google_iam_policy.bucket.binding : binding.members if binding.role == "roles/storage.objectViewer"])) == toset(["user:member@example.com"])
    error_message = "Empty modern-role members must be removed."
  }
}

run "authoritative_policy_wiring" {
  command = apply

  assert {
    condition     = google_storage_bucket_iam_policy.bucket.bucket == output.name && google_storage_bucket_iam_policy.bucket.policy_data == data.google_iam_policy.bucket.policy_data
    error_message = "The whole-policy resource must use the requested bucket and composed policy."
  }
}
