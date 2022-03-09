# terraform-aws-cloudtrail

## Usage

**HUB Account**

```terraform
module "hub_cloudtrail" {
  source = "git@github.com:oozou/terraform-aws-cloudtrail.git?ref=<ref_id>"

  environment = "devops"
  tags = {
    "Workspace" = "<workspace_name>"
  }
  account_mode = "HUB"

  spoke_account_ids = [
    "<spoke_account_id_1>",
    "<spoke_account_id_2>",
    "<spoke_account_id_3>"
  ]

  event_selector = [{
    data_resource = [
      {
        type   = "AWS::S3::Object"
        values = ["arn:aws:s3:::"]
      },
      {
        type   = "AWS::Lambda::Function"
        values = ["arn:aws:lambda"]
      }
    ]
    include_management_events = true
    read_write_type           = "All"
  }]

  centralize_trail_bucket_lifecycle_rule = [
    {
      id = "TrailLogLifecyclePolicy"
      transition = [
        {
          days          = 31
          storage_class = "STANDARD_IA"
        },
        {
          days          = 366
          storage_class = "GLACIER"
        }
      ]
      expiration_days = 3660
    }
  ]
}
```

**SPOKE Account**

```terraform
module "spoke_cloudtrail" {
  source = "git@github.com:oozou/terraform-aws-cloudtrail.git?ref=<ref_id>"

  environment = "dev"
  tags = {
    "Workspace" = "<workspace_name>"
  }
  account_mode = "SPOKE"

  centralize_trail_bucket_name = "<hub_centralize_trail_logs_bucket_name>"
  kms_key_id                           = "<hub_centralize_trail_kms_arn>"

  event_selector = [{
    data_resource = [
      {
        type   = "AWS::S3::Object"
        values = ["arn:aws:s3:::"]
      },
      {
        type   = "AWS::Lambda::Function"
        values = ["arn:aws:lambda"]
      }
    ]
    include_management_events = true
    read_write_type           = "All"
  }]
}
```

<!-- BEGIN_TF_DOCS -->

## Requirements

| Name                                                                     | Version  |
| ------------------------------------------------------------------------ | -------- |
| <a name="requirement_terraform"></a> [terraform](#requirement_terraform) | >= 1.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement_aws)                   | >= 4.0.0 |

## Providers

| Name                                             | Version |
| ------------------------------------------------ | ------- |
| <a name="provider_aws"></a> [aws](#provider_aws) | 4.3.0   |

## Modules

| Name                                                                                               | Source                                         | Version |
| -------------------------------------------------------------------------------------------------- | ---------------------------------------------- | ------- |
| <a name="module_centralize_log_bucket"></a> [centralize_log_bucket](#module_centralize_log_bucket) | git@github.com:oozou/terraform-aws-s3          | v1.0.1  |
| <a name="module_cloudtrail_kms"></a> [cloudtrail_kms](#module_cloudtrail_kms)                      | git@github.com:oozou/terraform-aws-kms-key.git | v0.0.2  |

## Resources

| Name                                                                                                                                         | Type        |
| -------------------------------------------------------------------------------------------------------------------------------------------- | ----------- |
| [aws_cloudtrail.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudtrail)                                | resource    |
| [aws_cloudwatch_log_group.trail_log](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group)       | resource    |
| [aws_iam_policy.cloudtrail_put_log_cw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy)               | resource    |
| [aws_iam_role.cloudtrail_put_log_cw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role)                   | resource    |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity)                | data source |
| [aws_iam_policy_document.kms_cloudtrail](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.s3_cloudtrail](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document)  | data source |

## Inputs

| Name                                                                                                                                                | Description                                                                                                                                                                                          | Type                                                                                                                                                                                         | Default | Required |
| --------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------- | :------: |
| <a name="input_account_mode"></a> [account_mode](#input_account_mode)                                                                               | Account mode for provision cloudtrail, if account_mode is HUB, will provision S3, KMS, CloudTrail. if account_mode is SPOKE, will provision only CloudTrail                                          | `string`                                                                                                                                                                                     | n/a     |   yes    |
| <a name="input_centralize_trail_bucket_lifecycle_rule"></a> [centralize_trail_bucket_lifecycle_rule](#input_centralize_trail_bucket_lifecycle_rule) | List of lifecycle rules to transition the data. Leave empty to disable this feature. storage_class can be STANDARD_IA, ONEZONE_IA, INTELLIGENT_TIERING, GLACIER, or DEEP_ARCHIVE                     | <pre>list(object({<br> id = string<br><br> transition = list(object({<br> days = number<br> storage_class = string<br> }))<br><br> expiration_days = number<br> }))</pre>                    | `[]`    |    no    |
| <a name="input_centralize_trail_bucket_name"></a> [centralize_trail_bucket_name](#input_centralize_trail_bucket_name)                               | S3 bucket for store Cloudtrail log (long terms), leave this default if account_mode is HUB. If account_mode is SPOKE, please provide centrailize S3 bucket name (HUB).                               | `string`                                                                                                                                                                                     | `""`    |    no    |
| <a name="input_cloudtrail_encrypted"></a> [cloudtrail_encrypted](#input_cloudtrail_encrypted)                                                       | Whether Cloudtrail encryption enable or not.                                                                                                                                                         | `bool`                                                                                                                                                                                       | `true`  |    no    |
| <a name="input_enable_log_file_validation"></a> [enable_log_file_validation](#input_enable_log_file_validation)                                     | Specifies whether log file integrity validation is enabled. Creates signed digest for validated contents of logs                                                                                     | `bool`                                                                                                                                                                                       | `true`  |    no    |
| <a name="input_enable_logging"></a> [enable_logging](#input_enable_logging)                                                                         | Enable logging for the trail                                                                                                                                                                         | `bool`                                                                                                                                                                                       | `true`  |    no    |
| <a name="input_environment"></a> [environment](#input_environment)                                                                                  | Environment name used as environment resources name.                                                                                                                                                 | `string`                                                                                                                                                                                     | n/a     |   yes    |
| <a name="input_event_selector"></a> [event_selector](#input_event_selector)                                                                         | Specifies an event selector for enabling data event logging. See: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudtrail#event_selector for details on this variable | <pre>list(object({<br> include_management_events = bool<br> read_write_type = string<br><br> data_resource = list(object({<br> type = string<br> values = list(string)<br> }))<br> }))</pre> | `[]`    |    no    |
| <a name="input_include_global_service_events"></a> [include_global_service_events](#input_include_global_service_events)                            | Specifies whether the trail is publishing events from global services such as IAM to the log files                                                                                                   | `bool`                                                                                                                                                                                       | `true`  |    no    |
| <a name="input_is_create_monitor_trail"></a> [is_create_monitor_trail](#input_is_create_monitor_trail)                                              | Whether to create monitor trails.                                                                                                                                                                    | `bool`                                                                                                                                                                                       | `true`  |    no    |
| <a name="input_is_multi_region_trail"></a> [is_multi_region_trail](#input_is_multi_region_trail)                                                    | Specifies whether the trail is created in the current region or in all regions                                                                                                                       | `bool`                                                                                                                                                                                       | `true`  |    no    |
| <a name="input_kms_key_id"></a> [kms_key_id](#input_kms_key_id)                                                                                     | The ARN for the KMS encryption key. Leave this default if account_mode is HUB. If account_mode is SPOKE, please provide centrailize kms key arn (HUB).                                               | `string`                                                                                                                                                                                     | `""`    |    no    |
| <a name="input_spoke_account_ids"></a> [spoke_account_ids](#input_spoke_account_ids)                                                                | Spoke account Ids, if mode is hub.                                                                                                                                                                   | `list(string)`                                                                                                                                                                               | `[]`    |    no    |
| <a name="input_tags"></a> [tags](#input_tags)                                                                                                       | Tags to add more; default tags contian {terraform=true, environment=var.environment}                                                                                                                 | `map(string)`                                                                                                                                                                                | `{}`    |    no    |

## Outputs

| Name                                                                                                  | Description    |
| ----------------------------------------------------------------------------------------------------- | -------------- |
| <a name="output_centralize_bucket_arn"></a> [centralize_bucket_arn](#output_centralize_bucket_arn)    | S3 Bucket ARN  |
| <a name="output_centralize_bucket_name"></a> [centralize_bucket_name](#output_centralize_bucket_name) | S3 Bucket Name |
| <a name="output_centralize_key_arn"></a> [centralize_key_arn](#output_centralize_key_arn)             | KMS key arn    |
| <a name="output_centralize_key_id"></a> [centralize_key_id](#output_centralize_key_id)                | KMS key id     |
| <a name="output_cloudtrail_arn"></a> [cloudtrail_arn](#output_cloudtrail_arn)                         | S3 Bucket ARN  |
| <a name="output_cloudtrail_id"></a> [cloudtrail_id](#output_cloudtrail_id)                            | S3 Bucket Id   |

<!-- END_TF_DOCS -->
