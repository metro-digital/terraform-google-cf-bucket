# Cloud Foundation GCS bucket module

[FAQ] | [CONTRIBUTING] | [CHANGELOG] | [MIGRATION]

This module allows you to create and manage a Google Cloud Storage bucket.

**Table of Contents**

<!-- mdformat-toc start --slug=github --no-anchors --maxlevel=6 --minlevel=2 -->

- [Compatibility](#compatibility)
- [What the Module Adds Compared to the Resource](#what-the-module-adds-compared-to-the-resource)
  - [Defaults and Explicit Configuration](#defaults-and-explicit-configuration)
  - [Validation and IAM Behavior](#validation-and-iam-behavior)
- [Usage](#usage)
- [Encryption](#encryption)
- [Lifecycle Rules](#lifecycle-rules)
- [Soft Deletion](#soft-deletion)
- [IAM Policy Ownership](#iam-policy-ownership)
- [Tests and CI](#tests-and-ci)
- [License](#license)

<!-- mdformat-toc end -->

## Compatibility

This module requires [terraform] >= 1.3 and `hashicorp/google` `>= 7.26, < 9.0`. Google provider
majors 7 and 8 are covered by the compatibility test matrix. Running the mocked test suite requires
Terraform >= 1.7.

Version 2 changes the input interface and defaults. Follow the [migration guide][migration] before
upgrading an existing bucket.

## What the Module Adds Compared to the Resource

The module exposes a selected, typed interface to `google_storage_bucket`, manages the bucket IAM
policy, and validates configuration combinations. The comparison below uses the
[Google provider resource defaults](https://github.com/hashicorp/terraform-provider-google/blob/v7.26.0/website/docs/r/storage_bucket.html.markdown)
from the minimum supported provider version.

### Defaults and Explicit Configuration

| Setting                     | Direct resource                                      | Module                                                                      |
| --------------------------- | ---------------------------------------------------- | --------------------------------------------------------------------------- |
| Uniform bucket-level access | Defaults to `false`                                  | Defaults to `true`, disabling ACL-based access                              |
| Location                    | Required, with no default                            | Defaults to `EU`                                                            |
| Project                     | Can inherit the provider's project                   | Requires an explicit `project_id`                                           |
| Soft deletion               | An omitted block preserves the server-side policy    | Always configures a retention period; defaults to `604800` seconds (7 days) |
| Versioning                  | Optional block; new buckets have versioning disabled | Always configures `enabled`; defaults to `false`                            |

Explicit configuration matters when adopting an existing bucket. In particular, the module's default
can replace an existing soft-delete retention period with seven days or disable existing versioning.
Supply the intended values and review the plan before applying.

Other defaults follow the resource's normal behavior: `storage_class = "STANDARD"`,
`public_access_prevention = "inherited"`, no lifecycle rules, no logging destination, and no custom
encryption key or encryption enforcement restrictions. Google-managed encryption remains the default
for new buckets. `force_destroy` is not exposed and remains `false`; this is not complete protection
against deleting an empty bucket.

### Validation and IAM Behavior

- Encryption checks key-name format, allowed restriction modes, restrictions blocking every
  encryption type, and conflicting default-key restrictions.
- Lifecycle checks action/class combinations, nonempty conditions, whole positive ages and version
  counts, valid dates, states and storage classes. The module supports a subset of the resource's
  lifecycle fields.
- Soft-delete retention must be whole seconds within 7 to 90 days, or `0` to disable. Project IDs,
  logging destinations and IAM role names are also validated.
- A separate IAM resource owns the entire bucket policy. The module explicitly merges legacy project
  principals unless `purge_legacy_roles = true`, removes empty bindings and deduplicates members.
  Inherited project and organization grants remain outside this policy's scope.
- Setting `uniform_access = false` adds the Cloud Foundation exemption label
  `cf_no_require_bucket_policy_only = "true"`.

These checks validate configuration, not live permissions, KMS availability or workload retention
requirements. See the feature guides below and
[Module safeguards and possible extensions](docs/BUCKET_FEATURES.md) for details.

## Usage

```hcl
module "tf-state-bucket" {
  source  = "metro-digital/cf-bucket/google"
  version = "~> 2.0"

  project_id     = "metro-cf-example-ex1-e8v"
  name           = "tf-state-metro-cf-example-ex1-e8v"
  location       = "EU"
  storage_class  = "STANDARD"
  uniform_access = true
  versioning     = true

  lifecycle_rules = [{
    action    = { type = "Delete" }
    condition = { num_newer_versions = 30 }
  }]

  iam_bindings = {
    "roles/storage.objectViewer" = ["group:readers@example.com"]
  }

  # Optional singleton inputs:
  # logging = { log_bucket = "audit-log-bucket", log_object_prefix = "state/" }
  # encryption = { default_kms_key_name = "projects/PROJECT/locations/eu/keyRings/RING/cryptoKeys/KEY" }
}
```

The example targets the forthcoming v2 release. For local development, use
`source = "./path/to/terraform-google-cf-bucket"` and omit `version`. A public Registry example is
available in [examples/basic](examples/basic).

> [!TIP]
> A detailed description of input variables and output values can be found
> [here](./docs/TERRAFORM.md).

## Encryption

Google-managed encryption is recommended and is the default for new buckets when `encryption` is
omitted. The typed encryption object can set a default KMS key or restrict allowed encryption types.
Validation catches malformed key names and conflicting restrictions.

See [Bucket encryption](docs/ENCRYPTION.md) for Google-managed-only and KMS examples, prerequisites,
validation limits and effects on existing objects.

## Lifecycle Rules

No lifecycle rules are enabled by default. Typed rules support deletion and storage-class
transitions with validated conditions. Choosing a rule's scope and retention period remains the
caller's responsibility.

See [Object lifecycle rules](docs/LIFECYCLE_RULES.md) for examples and the interaction with object
versioning, soft deletion and storage costs.

## Soft Deletion

The module retains soft-deleted data for seven days by default. Retention must be whole seconds
between 7 and 90 days, or zero to disable it.

See [Soft deletion and recovery](docs/SOFT_DELETION.md) for recovery-window choices, policy changes,
cost considerations and interaction with lifecycle rules.

## IAM Policy Ownership

This module owns the **entire bucket IAM policy**. Grants managed outside the module are replaced;
put every intended bucket binding in `iam_bindings` and avoid managing the same policy with other
bucket IAM resources.

By default, the module adds project owner/editor principals to legacy owner roles and project
viewers to legacy reader roles. `purge_legacy_roles = true` removes these defaults while retaining
explicitly supplied bindings. Empty bindings are omitted and duplicate members are removed.

See [Module safeguards and possible extensions](docs/BUCKET_FEATURES.md) for the checks already
provided by v2 and recommendations for future module features.

## Tests and CI

Pull requests run formatting, initialization, validation and the mocked suite across Google provider
majors 7–8, with a separate minimum-provider check at 7.26.0. Tests create no cloud resources.
Results appear in job summaries and, after the publisher is merged into `main`, one updated PR
comment.

See [CONTRIBUTING] for local commands, CI details and the release process.

## License

This project is licensed under the terms of the [Apache License 2.0](LICENSE)

This [terraform] module depends on providers from HashiCorp, Inc. which are licensed under MPL-2.0.
You can obtain the respective source code for these provider here:

- [`hashicorp/google`](https://github.com/hashicorp/terraform-provider-google)

[changelog]: ./docs/CHANGELOG.md
[contributing]: ./docs/CONTRIBUTING.md
[faq]: ./docs/FAQ.md
[migration]: ./docs/MIGRATION.md
[terraform]: https://terraform.io/
