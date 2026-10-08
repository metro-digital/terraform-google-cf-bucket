# Changelog

## [2.0.0](https://github.com/metro-digital/terraform-google-cf-bucket/compare/v1.3.0...v2.0.0) (2026-10-08)


### ⚠ BREAKING CHANGES

* Replace encryption lists with a nullable object containing optional default_kms_key_name and encryption enforcement configurations. Replace logging collections with a nullable object, lifecycle string maps with typed conditions and individual IAM role inputs with iam_bindings. Storage class now defaults to STANDARD; explicitly retain the previous class when upgrading. Google providers below 7.26.0 are no longer supported.

### Features

* refactor bucket module for v2 ([bf1224b](https://github.com/metro-digital/terraform-google-cf-bucket/commit/bf1224b0003de4a2cb920fd6cbe9b4150cb1a6db))


### Bug Fixes

* introduce regression tests and correct bucket inputs ([7c9b79f](https://github.com/metro-digital/terraform-google-cf-bucket/commit/7c9b79ff63183ac632805f0dbb5927dc7b7fec29))

## Changelog

Versioned entries are generated when release-please creates a release pull request.

For the upcoming v2 upgrade, see the [migration instructions](MIGRATION.md#v2-release).
Existing version tags are available on [GitHub](https://github.com/metro-digital/terraform-google-cf-bucket/tags).
