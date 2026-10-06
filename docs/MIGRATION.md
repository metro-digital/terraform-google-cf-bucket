# Migration Instructions

**Table of Contents**

<!-- mdformat-toc start --slug=github --no-anchors --maxlevel=6 --minlevel=2 -->

- [`v2` Release](#v2-release)
  - [Changed Inputs and Defaults](#changed-inputs-and-defaults)
  - [Logging and Encryption](#logging-and-encryption)
  - [Lifecycle Rules](#lifecycle-rules)
  - [IAM Bindings](#iam-bindings)
  - [Upgrade Procedure](#upgrade-procedure)

<!-- mdformat-toc end -->

## `v2` Release

Review the [CHANGELOG] before upgrading from v1. The sections below explain the input and default
changes, and how to review the upgrade plan.

Version 2 keeps the resource addresses `google_storage_bucket.bucket` and
`google_storage_bucket_iam_policy.bucket`, and retains all five existing outputs. Keep the calling
module's name and its bucket name, project and location unchanged when upgrading. The module itself
requires no state moves or imports.

The module still requires Terraform `>= 1.3`. Supported Google provider versions are `>= 7.26` and
`< 9.0`, covering majors 7 and 8. Unit tests require Terraform `>= 1.7`; consumers do not need to
upgrade to that version just to use the module.

### Changed Inputs and Defaults

| v1                                                 | v2                                              | Migration                                                                          |
| -------------------------------------------------- | ----------------------------------------------- | ---------------------------------------------------------------------------------- |
| `storage_class` defaults to `REGIONAL`             | Defaults to `STANDARD`                          | Explicitly set the existing class to preserve behavior.                            |
| `logging = [{ ... }]`                              | `logging = { ... }`                             | Unwrap the single object; use `null` instead of `[]` to disable.                   |
| `encryption = ["KEY"]`                             | `encryption = { default_kms_key_name = "KEY" }` | Unwrap the key into a typed object; use `null` instead of `[]` to omit encryption. |
| Lifecycle `action` and `condition` are string maps | Typed objects with optional attributes          | Supply numeric age/version counts and a set/list of matching storage classes.      |
| Individual IAM role lists                          | `iam_bindings = { "ROLE" = ["MEMBER"] }`        | Move every supplied role list to its corresponding role key.                       |
| Unbounded Google provider constraint               | `>= 7.26, < 9.0`                                | Upgrade providers below 7.26.0; use supported major 7 or 8.                        |

Bucket location (`EU`), uniform access (`true`), versioning (`false`), public access prevention
(`inherited`), seven-day soft delete and legacy-principal defaults are unchanged. Existing outputs
remain `name`, `project`, `location`, `storage_class` and `versioning`; the shape of the
`versioning` output is unchanged.

### Logging and Encryption

See [Bucket encryption](ENCRYPTION.md) for policy choices and KMS prerequisites.

Before:

```hcl
logging = [{
  log_bucket        = "audit-log-bucket"
  log_object_prefix = "state/"
}]
encryption = ["projects/PROJECT/locations/eu/keyRings/RING/cryptoKeys/KEY"]
```

After:

```hcl
logging = {
  log_bucket        = "audit-log-bucket"
  log_object_prefix = "state/"
}
encryption = {
  default_kms_key_name = "projects/PROJECT/locations/eu/keyRings/RING/cryptoKeys/KEY"
}
```

The logging prefix remains optional. Both inputs default to `null`. The module does not grant KMS
permissions or create the destination logging bucket: retain those existing configurations and use a
key in a compatible location.

Encryption also supports optional `google_managed_encryption_enforcement_config`,
`customer_managed_encryption_enforcement_config` and
`customer_supplied_encryption_enforcement_config` objects, each containing `restriction_mode`
(`NotRestricted` or `FullyRestricted`). These fields require Google provider 7.26.0 or newer;
upgrade the provider lock file with `terraform init -upgrade`. Provider 5.x, 6.x and 7.x below
7.26.0 are no longer supported. The provider's `effective_time` remains computed and is not an
input.

Google-managed encryption remains the recommended default. No restrictions are enabled
automatically. See the root README for a Google-managed-only policy. Enforcement applies to new
objects and can reject uploads that previously worked; existing objects are unaffected. Preserve the
same key when migrating a KMS configuration. Before restricting both customer-controlled encryption
types, remove any default KMS key; at least one encryption type must remain allowed.

### Lifecycle Rules

See [Object lifecycle rules](LIFECYCLE_RULES.md) for matching and deletion behavior.

Before:

```hcl
lifecycle_rules = [{
  action = { type = "SetStorageClass", storage_class = "NEARLINE" }
  condition = { age = "7", matches_storage_class = "STANDARD,REGIONAL" }
}]
```

After:

```hcl
lifecycle_rules = [{
  action = { type = "SetStorageClass", storage_class = "NEARLINE" }
  condition = { age = 7, matches_storage_class = ["STANDARD", "REGIONAL"] }
}]
```

Supported condition attributes remain `age`, `created_before`, `with_state`, `matches_storage_class`
and `num_newer_versions`. Omitted attributes remain unset. Each rule must have at least one
condition. Actions must be `Delete` without a storage class, or `SetStorageClass` with a supported
class.

Age and version count must be positive whole numbers. For zero-day lifecycle behavior, use another
supported condition. Dates must be valid `YYYY-MM-DD` values, states must be `LIVE`, `ARCHIVED` or
`ANY`, and matching class sets must be nonempty. Soft-delete retention must now be a whole number of
seconds in the existing range, or zero to disable it. See
[Soft deletion and recovery](SOFT_DELETION.md) for policy changes and recovery behavior. Project
IDs, storage classes, KMS key names and IAM role names are also validated earlier during planning.

### IAM Bindings

Move each old input to the following key in `iam_bindings`:

| Removed input                      | Role key                           |
| ---------------------------------- | ---------------------------------- |
| `additional_legacy_bucket_owners`  | `roles/storage.legacyBucketOwner`  |
| `additional_legacy_bucket_readers` | `roles/storage.legacyBucketReader` |
| `additional_legacy_bucket_writers` | `roles/storage.legacyBucketWriter` |
| `additional_legacy_object_owners`  | `roles/storage.legacyObjectOwner`  |
| `additional_legacy_object_readers` | `roles/storage.legacyObjectReader` |
| `storage_admins`                   | `roles/storage.admin`              |
| `storage_object_admins`            | `roles/storage.objectAdmin`        |
| `storage_object_creators`          | `roles/storage.objectCreator`      |
| `storage_object_viewers`           | `roles/storage.objectViewer`       |

For example:

```hcl
iam_bindings = {
  "roles/storage.admin"        = ["group:admins@example.com"]
  "roles/storage.objectViewer" = ["group:readers@example.com"]
}
```

Additional predefined roles and custom roles are supported. Custom keys have the form
`projects/PROJECT/roles/ROLE` or `organizations/NUMBER/roles/ROLE`.

The module still replaces the **entire bucket policy**. Include every intended bucket grant and
avoid concurrent bucket-policy, binding or member resources managing the same policy. Duplicate and
empty members are removed, and empty bindings are omitted.

Keep the existing `purge_legacy_roles` value. When false, project owners/editors are added to legacy
owner roles and project viewers to legacy reader roles, even if a corresponding map entry is empty.
When true, these defaults are removed; explicitly supplied legacy members remain. Purging with an
empty map clears all bucket-level bindings managed by this module.

### Upgrade Procedure

1. Record the existing module inputs and review all intended bucket IAM grants.
1. Keep the same module name, bucket name, project and location. Explicitly retain the previous
   storage class and `purge_legacy_roles` setting.
1. Convert inputs using the mappings above and select module version `2.0.0` after publication. For
   a pre-release review, use the local v2 checkout as source.
1. Initialize with a supported provider version, then run `terraform plan` against the existing
   state. Review the plan before applying: expect no bucket replacement and no unintended changes to
   lifecycle rules, encryption or IAM membership.
1. Apply only after reviewing the actual consumer plan. Retain the version pin and migration notes
   in the consumer repository.

The committed migration tests assert the expected bucket configuration and IAM membership for
migrated inputs, with and without legacy-principal purging. They do not verify a live Google
API/state upgrade. Resource-address stability avoids a module-induced state move; it does not
guarantee an unchanged plan when inputs, defaults or provider versions are changed at the same time.

[changelog]: ./CHANGELOG.md
