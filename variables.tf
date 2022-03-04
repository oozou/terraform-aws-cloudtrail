/* -------------------------------------------------------------------------- */
/*                                  GENERICS                                  */
/* -------------------------------------------------------------------------- */
variable "environment" {
  description = "Environment name used as environment resources name."
  type        = string
}

variable "custom_tags" {
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

variable "cloudtrail_encrypted" {
  description = "Whether Cloudtrail encryption enable or not."
  type        = bool
  default     = true
}

variable "centralize_trail_logging_bucket_name" {
  description = "S3 bucket for store Cloudtrail log (long terms)"
  type        = string
}

variable "kms_key_id" {
  description = "The ARN for the KMS encryption key. If creating an encrypted, set this to the destination KMS ARN. If cloudtrail_encrypted is set to true and kms_key_id is not specified terraform will create new kms to be used."
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

