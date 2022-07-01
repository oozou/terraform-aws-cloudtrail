/* -------------------------------------------------------------------------- */
/*                                  GENERICS                                  */
/* -------------------------------------------------------------------------- */
variable "prefix" {
  description = "The prefix name of customer to be displayed in AWS console and resource"
  type        = string
}

variable "environment" {
  description = "Environment name used as environment resources name."
  type        = string
}

variable "tags" {
  description = "Tags to add more; default tags contian {terraform=true, environment=var.environment}"
  type        = map(string)
  default     = {}
}

/* -------------------------------------------------------------------------- */
/*                           CloudTrail Rule                                  */
/* -------------------------------------------------------------------------- */
variable "is_create_monitor_trail" {
  description = "Whether to create monitor trails."
  type        = bool
  default     = true
}

variable "cloudwatch_log_retention_in_days" {
  description = "(optional) describe your variable"
  type        = number
  default     = 365
}

variable "additional_cloudwatch_log_metric_filters" {
  description = "(optional) Additional cloudwatch log filter"
  type        = any
  default     = {}
}

variable "enable_cloudwatch_log_metric_filters" {
  description = "(optional) list of metrics filter to enable"
  type        = list(string)
  default     = []
  validation {
    condition = alltrue([
      for value in var.enable_cloudwatch_log_metric_filters : contains(
        [
          "authorization_failures",
          "cloudtrail_changes",
          "config_activity",
          "console_signin_failures",
          "console_signin_without_mfa",
          "deleted_kms_cmk_activity",
          "gateway_changes",
          "iam_policy_changes",
          "network_acl_events",
          "root_account_usage",
          "s3_bucket_activity",
          "security_group_events",
          "vpc_changes",
          "vpc_route_table_changes"
        ],
        value
      )
    ])
    error_message = "The given value is not valid choice."
  }
}

variable "default_alarm_actions" {
  description = "The list of actions to execute when this alarm transitions into an ALARM state from any other state. Each action is specified as an Amazon Resource Name (ARN)."
  type        = list(string)
  default     = []
}

variable "cloudtrail_encrypted" {
  description = "Whether Cloudtrail encryption enable or not."
  type        = bool
  default     = true
}

variable "centralize_trail_bucket_name" {
  description = "S3 bucket for store Cloudtrail log (long terms), leave this default if account_mode is hub. If account_mode is SPOKE, please provide centrailize S3 bucket name (hub)."
  type        = string
  default     = ""
}

variable "kms_key_id" {
  description = "The ARN for the KMS encryption key. Leave this default if account_mode is hub. If account_mode is SPOKE, please provide centrailize kms key arn (hub)."
  type        = string
  default     = ""
}

variable "enable_log_file_validation" {
  description = "Specifies whether log file integrity validation is enabled. Creates signed digest for validated contents of logs"
  type        = bool
  default     = true
}

variable "is_multi_region_trail" {
  description = "Specifies whether the trail is created in the current region or in all regions"
  type        = bool
  default     = true
}

variable "include_global_service_events" {
  description = "Specifies whether the trail is publishing events from global services such as IAM to the log files"
  type        = bool
  default     = true
}

variable "enable_logging" {
  description = "Enable logging for the trail"
  type        = bool
  default     = true
}

variable "event_selector" {
  description = "Specifies an event selector for enabling data event logging. See: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudtrail#event_selector for details on this variable"
  type = list(object({
    include_management_events = bool
    read_write_type           = string

    data_resource = list(object({
      type   = string
      values = list(string)
    }))
  }))
  default = []
}

/* -------------------------------------------------------------------------- */
/*                            Account Configuration                           */
/* -------------------------------------------------------------------------- */
variable "account_mode" {
  description = "Account mode for provision cloudtrail, if account_mode is hub, will provision S3, KMS, CloudTrail. if account_mode is spoke, will provision only CloudTrail"
  type        = string
  validation {
    condition     = contains(["hub", "spoke"], var.account_mode)
    error_message = "Valid values for account_mode are hub and spoke."
  }
}

variable "spoke_account_ids" {
  description = "Spoke account Ids, if mode is hub."
  type        = list(string)
  default     = []
}

/* -------------------------------------------------------------------------- */
/*                                  S3 Bucket                                 */
/* -------------------------------------------------------------------------- */

variable "centralize_trail_bucket_lifecycle_rule" {
  description = "List of lifecycle rules to transition the data. Leave empty to disable this feature. storage_class can be STANDARD_IA, ONEZONE_IA, INTELLIGENT_TIERING, GLACIER, or DEEP_ARCHIVE"
  type = list(object({
    id = string

    transition = list(object({
      days          = number
      storage_class = string
    }))

    expiration_days = number
  }))
  default = []
}
