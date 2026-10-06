# Contributing

This document provides guidelines for contributing to this [terraform] module. When contributing to
this repository, please first discuss the change you wish to make via issue with the owners of this
repository before making a change.

## Pull Request Process

1. Update the README.md with details of changes to the interface.
1. Use [Conventional Commits] for commit messages. Mark incompatible changes with `!` and a
   `BREAKING CHANGE:` footer describing the migration. Release-please determines the next
   [SemVer](https://semver.org/) version from these messages.
1. You may merge the Pull Request in once you have the sign-off of one other developer, or if you do
   not have permission to do that, you may request a reviewer to merge it for you.

## Dependencies

The following dependencies must be installed on the development system:

- [pre-commit framework][pcf]
  - [pre-commit git hooks for terraform][pcf-tf]
    - [Trivy]
    - [tflint]
  - [mdformat] and its configured plugins
- [terraform-docs]
- Node.js and npm for commitlint
- Terraform

## Generating Documentation for inputs and outputs

The Inputs and Outputs tables in `docs/TERRAFORM.md` are automatically generated from the module
variables and outputs using `.terraform-docs.yaml`. The README links to this reference. These tables
must be refreshed if the module interfaces are changed.

### Execution

Documentation is updated when running the pre-commit hooks: `pre-commit run -a`

## Installing and Running Hooks

Install both the source checks and commit-message hook:

```sh
pre-commit install
pre-commit run --all-files
```

The configuration installs `pre-commit` and `commit-msg` hooks. Commitlint validates Conventional
Commits locally and in the pull-request workflow. Signed Dependabot commits and its standard
dependency-bump messages are accepted.

Update hook versions while retaining immutable commit references with:

```sh
pre-commit autoupdate --freeze
```

Dependabot checks GitHub Actions and pre-commit dependencies daily. Security updates and ordinary
version updates are grouped separately for each ecosystem. Review these updates and run the checks
before merging.

## Terraform Regression Tests

Run the credential-free mocked suite with Terraform 1.7 or later:

```sh
terraform init -backend=false -input=false
terraform test
```

The test runner needs a newer Terraform version than the module's existing 1.3 runtime minimum
because provider mocking was introduced in Terraform 1.7. Provider plugins are still downloaded
during initialization, but every test uses a mocked Google provider and creates no cloud resources.

The suite covers defaults and outputs, labels, lifecycle rules, logging, encryption, public-access
prevention, soft-delete boundaries, legacy and modern IAM bindings, and invalid inputs. Migration
tests assert documented migrated configurations against explicit expected bucket settings and IAM
memberships.

Most scenarios use a mocked plan. One mocked apply verifies the IAM resource's policy wiring after
resolving its dependency on bucket creation. IAM assertions inspect configured data-source bindings:
the mock returns fixed policy JSON and does not test Google's policy serialization or API behavior.
State-backed upgrade plans and real integration checks remain separate from these regression tests.

To run a single test file:

```sh
terraform test -filter=tests/iam.tftest.hcl
```

## Compatibility CI and Reporting

`terraform-test` discovers the latest stable patch of every Terraform minor series from 1.7 onward,
excluding prereleases, and crosses them with the latest Google provider 7.x and 8.x releases. One
additional job uses the oldest tested Terraform series and Google 7.26.0 to verify the published
provider minimum. A separate initialization/validation job checks the module on Terraform 1.3.10
with Google 7.26.0; it does not run the newer mocked test language. The Google Beta provider is not
used by this module.

Each job creates a temporary provider override and initializes with `-upgrade`, then runs recursive
formatting, module validation and the full mocked suite. Exact installed versions and outcomes are
written to job summaries and artifacts. The reporting validator accepts canonical provider-major
identifiers independently of the matrix so adding a major does not break the trusted publisher on
`main`.

`terraform-test-comment` runs trusted code from the default branch after the test workflow
completes. It validates artifacts, creates or updates one bot comment, and skips outdated PR commits
and run attempts. Partial reruns replace only their own results. The publisher becomes active once
its workflow and scripts reach `main`; it cannot publish this refactor's initial pre-merge results.

`Pipeline Status` aggregates check runs and commit statuses. After verifying the workflow on GitHub,
configure branch protection to require `pipeline-status`. Repository settings and end-to-end
workflow execution are maintainer release checks.

## Releases

Release-please runs after pushes to `main`. It opens a draft release pull request with the version
manifest and `docs/CHANGELOG.md` updates. A maintainer reviews and merges that pull request to
publish the GitHub release and `v`-prefixed version tag.

The initial manifest starts at `1.3.0`, the existing `v1.3.0` tag. The bootstrap SHA points to that
tag so the first automated release considers subsequent commits. The breaking feature commit
advances the release to `2.0.0`. Its `Release-As: 2.0.0` footer explicitly selects that version for
the first automated release. Keep both the `BREAKING CHANGE:` and `Release-As: 2.0.0` footers in the
merged commit, including when squash merging. Subsequent commits should use normal
conventional-commit versioning without repeating this release override. Keep the manifest at `1.3.0`
until release-please updates it in the release PR. The README usage constraint uses the built-in
Terraform README updater: keep its version line in the exact form `version = "~> 2.0"`, with a
single space around `=`. A release of `2.5.0` updates this to `~> 2.5`. The public Registry example
uses a generic `extra-files` entry instead. It uses a two-component constraint (`~> 2.0`) and the
`x-release-please-major` annotation so it accepts all releases within the major version and advances
only when a new major version is released.

The workflow uses `GITHUB_TOKEN`. Repository Actions settings must allow GitHub Actions to create
pull requests. Events created with this token do not start other workflows, so release pull requests
may need a maintainer-triggered check run.

Before publishing v2, review `docs/MIGRATION.md`, ensure all required checks pass, and compare a
real consumer's existing state with the migrated configuration. The plan must retain bucket
identity/location and intended IAM grants without a bucket replacement. The mocked migration tests
check expected configuration, not Google API behavior or a live state transition. Review the
generated changelog and proposed 2.0.0 version, merge the release PR, then confirm the version tag,
GitHub release and Terraform Registry publication.

## Documentation Formatting and Security Checks

mdformat formats Markdown and updates marked tables of contents. Generated `docs/TERRAFORM.md` and
the release-managed `docs/CHANGELOG.md` are excluded.

Trivy scans Terraform configuration for misconfigurations through pre-commit. `.trivyignore`
excludes only the check requiring customer-managed encryption keys, because this module recommends
Google-managed encryption and supports custom keys as an explicit option. The bucket resource
locally excludes the versioning check because versioning is an explicit caller choice and soft
deletion provides default recovery. Review any additional exclusions before adding them.

The Google provider metadata in `versions.tf` identifies the module and version. Release-please
updates the metadata version automatically through its `terraform-module` updater for `versions.tf`.
The README uses the built-in README updater; the example annotation uses a generic extra-file.

[conventional commits]: https://www.conventionalcommits.org/en/v1.0.0/
[mdformat]: https://github.com/hukkin/mdformat
[pcf]: https://pre-commit.com/
[pcf-tf]: https://github.com/antonbabenko/pre-commit-terraform
[terraform]: https://terraform.io/
[terraform-docs]: https://terraform-docs.io/
[tflint]: https://github.com/terraform-linters/tflint
[trivy]: https://github.com/aquasecurity/trivy
