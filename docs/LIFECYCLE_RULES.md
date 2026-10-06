# Object lifecycle rules

[Back to the module](../README.md) | [Soft deletion](SOFT_DELETION.md)

`lifecycle_rules` defaults to an empty set. The module adds no automatic deletion or storage-class
transitions. Choose rules around the workload's recovery and retention requirements.

## Rule structure

Each rule contains an `action` and a `condition` object. Supported actions are `Delete` and
`SetStorageClass`. A transition requires `action.storage_class`; a deletion must omit it.

| Supported condition     | Meaning                                             | Module validation                       |
| ----------------------- | --------------------------------------------------- | --------------------------------------- |
| `age`                   | Days since object creation                          | Positive whole number; zero is rejected |
| `created_before`        | Objects created before the specified UTC date       | Valid `YYYY-MM-DD` calendar date        |
| `with_state`            | Live objects, noncurrent versions, or either        | `LIVE`, `ARCHIVED`, or `ANY`            |
| `matches_storage_class` | Objects in any listed storage class                 | Nonempty set of supported classes       |
| `num_newer_versions`    | Minimum number of newer versions of the same object | Positive whole number                   |

At least one condition is required. Conditions within a rule are combined with AND; matching any
deletion rule can trigger deletion. Rule order is not a priority mechanism. When deletion and
transition both qualify, deletion takes precedence. Lifecycle processing is asynchronous, and an old
configuration can remain active for up to 24 hours after a change.
[Google lifecycle documentation](https://cloud.google.com/storage/docs/lifecycle).

## Delete old live objects

For a workload whose live objects may be deleted after 30 days:

```hcl
lifecycle_rules = [{
  action = { type = "Delete" }
  condition = {
    age        = 30
    with_state = "LIVE"
  }
}]
```

This applies to existing matching objects as well as future uploads. With object versioning enabled,
deleting a live object makes it noncurrent; it does not clean up all retained versions. Soft
deletion can add another recovery period after an object version is deleted. See
[Soft deletion](SOFT_DELETION.md).

## Clean up noncurrent versions

This example enables versioning and makes a noncurrent version eligible for deletion once it has at
least three newer versions:

```hcl
versioning = true
lifecycle_rules = [{
  action = { type = "Delete" }
  condition = {
    with_state         = "ARCHIVED"
    num_newer_versions = 3
  }
}]
```

This is eligibility for asynchronous cleanup, not an immediate limit on the number of stored
versions. `age` measures time since creation, not time since a version became noncurrent. Disabling
versioning does not remove already retained noncurrent versions.
[Object Versioning documentation](https://cloud.google.com/storage/docs/object-versioning).

## Transition storage classes

This example moves Standard objects to Nearline after 30 days, then moves Nearline objects to
Coldline after 90 days from their original creation:

```hcl
lifecycle_rules = [
  {
    action = { type = "SetStorageClass", storage_class = "NEARLINE" }
    condition = { age = 30, matches_storage_class = ["STANDARD"] }
  },
  {
    action = { type = "SetStorageClass", storage_class = "COLDLINE" }
    condition = { age = 90, matches_storage_class = ["NEARLINE"] }
  },
]
```

The module validates class names, not every source-to-target transition. Verify the transition is
supported and assess retrieval and minimum-storage-duration costs for the workload.
[Supported transitions](https://cloud.google.com/storage/docs/lifecycle#change_an_objects_storage_class).

## Checks and limits

Typed numbers and class sets replace v1 string maps. Validation catches missing conditions,
malformed dates, unsupported states/classes and invalid action/class combinations. It does not prove
that a rule is appropriate for the data, detect every overlap, or inspect objects already in the
bucket.

Only the conditions in the table are supported. Provider features such as prefix filters, time since
becoming noncurrent, and multipart-upload cleanup are not exposed by this module. Do not add
unsupported fields: Terraform's object type conversion can discard extra attributes instead of
rejecting them.

For example, `with_state = "ANY"` alone is valid but can select every object. Test deletion rules on
disposable data before applying them to a production bucket. Retention policies and object holds can
delay deletion; the module does not configure those features. See
[migration instructions](MIGRATION.md).
