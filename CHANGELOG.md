# Change Log

All notable changes to this module will be documented in this file.

## [1.0.4] - 2022-07-20

### Changed

- Add `var.enable_cloudwatch_log_metric_filters` to enable default metric filter value
    - Add `local.metric_filters` to enable default metric filter value
    - Add `var.additional_cloudwatch_log_metric_filters` to override or add additional custom metric filter
    - Add cloudwatch alarm action `var.default_alarm_actions` to override all actions for all metric filter
- Rename `data.aws_region` from `current` to `this`
