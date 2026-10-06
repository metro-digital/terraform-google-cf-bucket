# Soft deletion and recovery

[Back to the module](../README.md) | [Lifecycle rules](LIFECYCLE_RULES.md)

The module explicitly configures seven days of soft-delete retention by default. Soft deletion
provides a recovery window after deletion; lifecycle rules select when to delete data. Neither
setting replaces a workload's recovery process.

## Configure the recovery window

The input is `soft_delete_retention_duration_seconds`:

| Value                      | Result                                     |
| -------------------------- | ------------------------------------------ |
| Omitted, or `604800`       | Seven days, the module default             |
| `604800` through `7776000` | Retain deleted data for 7 through 90 days  |
| `0`                        | Disable soft deletion for future deletions |

For a 14-day recovery window:

```hcl
soft_delete_retention_duration_seconds = 14 * 24 * 60 * 60
```

For disposable data that can be regenerated and needs no deletion recovery:

```hcl
soft_delete_retention_duration_seconds = 0
```

The module rejects null, fractional, negative and out-of-range values. It does not decide which
recovery period is suitable for the workload. The explicit default also means this module does not
defer retention selection to a bucket-creation default supplied through organization tags.

## What changes to the policy affect

The retention duration in effect when data is deleted determines its recovery window. Changing the
duration, including disabling soft deletion, does not shorten the window for data already
soft-deleted. Soft-deleted objects cannot be read normally; they must be restored before use.
Storage charges continue during the recovery window.
[Google soft-delete documentation](https://cloud.google.com/storage/docs/soft-delete).

Keep the default for valuable data unless a different recovery requirement has been established.
High-churn temporary data can accumulate substantial retained storage; choose `0` deliberately for
genuinely disposable workloads.

## How lifecycle rules and versioning interact

| Configuration                                                                  | Result of a lifecycle `Delete` action                                                                         |
| ------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------- |
| Versioning disabled, soft deletion enabled                                     | Object becomes soft-deleted                                                                                   |
| Versioning enabled, action targets a live object                               | Object becomes noncurrent                                                                                     |
| Versioning enabled, action targets a noncurrent version, soft deletion enabled | Version becomes soft-deleted                                                                                  |
| Soft deletion disabled                                                         | A deleted version has no soft-delete recovery window; versioning may still retain a live object as noncurrent |

Lifecycle rules cannot permanently delete or change the storage class of objects already
soft-deleted. To clean up noncurrent versions, configure an explicit rule for them; a live-object
rule alone is insufficient.
[Lifecycle interaction](https://cloud.google.com/storage/docs/soft-delete#interactions_with_other_products_and_features).

## Recovery and retention are separate concerns

The module configures a policy; it does not perform restores or test recovery. Establish permissions
and a recovery procedure using Google's
[object restore guide](https://cloud.google.com/storage/docs/use-soft-deleted-objects) and
[bucket restore guide](https://cloud.google.com/storage/docs/use-soft-deleted-buckets).

A bucket retention policy or object hold prevents deletion until its requirements are satisfied.
Soft deletion starts after an eligible deletion. The module does not expose retention policies or
holds. Soft deletion also does not prevent a Terraform destroy attempt or replace Terraform deletion
protection.
