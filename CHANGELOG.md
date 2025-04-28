# Change Log

All notable changes to this module will be documented in this file.

## [v1.0.8] - 2025-04-28

### Changed

- Update KMS module condition

## [v1.0.7] - 2022-09-22

### Changed

- Update source, version for module `cloudtrail_kms`, `alarm` and `centralize_log_bucket` to public registry

## [v1.0.6] - 2022-07-27

### Changed

- In DenyNonSSLRequests policies, we update to `<s3_arn>` and `<s3_arn>/*` for best practice when hardening policies enable.
- Update module `centralize_log_bucket` from version v1.1.1 to v1.1.2

## [v1.0.5] - 2022-07-26

### Changed

- Update module `centralize_log_bucket` to version v1.1.1 due to s3 security issue

## [v1.0.4] - 2022-07-26

### Changed

- Rename `data.aws_region` from `current` to `this`
- Rename `var.cloudtrail_encrypted` to `is_cloudtrail_encrypted`
- For s3 module `centralize_log_bucket`, policy is updated to force SSL connection of trail

### Added

- Add example for simple usage
- Add `var.enable_cloudwatch_log_metric_filters` to enable default metric filter value
    - Add `local.metric_filters` to enable default metric filter value
    - Add `var.additional_cloudwatch_log_metric_filters` to override or add additional custom metric filter
    - Add cloudwatch alarm action `var.default_alarm_actions` to override all actions for all metric filter


## [v1.0.3] - 2022-07-18

### Changed

- change kms policy for support another region

## [v1.0.2] - 2022-07-12

### Changed

- module s3 version from `1.0.1` to `1.0.4` to remove deprecated-variable

## [v1.0.1] - 2022-06-30

### Added

- support log retension
- fix kms-security-issue


## [v1.0.0] - 2022-03-17

### Added

- init terraform-aws-cloudtrail module
