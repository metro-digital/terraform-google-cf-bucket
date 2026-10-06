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

run "multiple_logging" {
  command = plan
  variables {
    logging = [{ log_bucket = "logs-a" }, { log_bucket = "logs-b" }]
  }
  expect_failures = [var.logging]
}

run "multiple_encryption" {
  command = plan
  variables {
    encryption = ["projects/test/locations/eu/keyRings/test/cryptoKeys/a", "projects/test/locations/eu/keyRings/test/cryptoKeys/b"]
  }
  expect_failures = [var.encryption]
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
