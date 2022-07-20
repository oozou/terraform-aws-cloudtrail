# terraform-aws-cloudtrail

## Usage

**HUB Account**

```terraform
module "hub_cloudtrail" {
  source = "git@github.com:oozou/terraform-aws-cloudtrail.git?ref=<ref_id>"

  prefix       = "<customer_name>"
  environment  = "devops"
  account_mode = "hub"

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

  enable_cloudwatch_log_metric_filters = ["authorization_failures"] # SELECT THE DEFUALT SETTING
  additional_cloudwatch_log_metric_filters = {
    authorization_failures = { # SAME KEY WILL OVERRIDE THE DEFAULT ONE
      comparison_operator = ">="
      threshold           = "50"
      evaluation_periods  = "1"
      period              = "300"
      pattern             = "{ ($.errorCode = \"*UnauthorizedOperation\") || ($.errorCode = \"AccessDenied*\") }"
      alarm_actions       = []
    }
    custome_metric_filter = {
      comparison_operator = ">="
      threshold           = "10"
      evaluation_periods  = "1"
      period              = "60"
      pattern             = "<pattern>"
      alarm_actions       = ["arn:aws:sns:ap-southeast-1:557291035693:alarm"]
    }
  }

  tags = var.generics_info["custom_tags"]
}

```

**SPOKE Account**

```terraform
module "spoke_cloudtrail" {
  source = "git@github.com:oozou/terraform-aws-cloudtrail.git?ref=<ref_id>"

  prefix = "<customer_name>"
  environment = "dev"
  tags = {
    "Workspace" = "<workspace_name>"
  }
  account_mode = "spoke"

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

| Name                                                                      | Version  |
|---------------------------------------------------------------------------|----------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws)                   | >= 4.0.0 |

## Providers

| Name                                              | Version |
|---------------------------------------------------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 4.22.0  |

## Modules

| Name                                                                                                    | Source                                              | Version                  |
|---------------------------------------------------------------------------------------------------------|-----------------------------------------------------|--------------------------|
| <a name="module_alarm"></a> [alarm](#module\_alarm)                                                     | git@github.com:oozou/terraform-aws-cloudwatch-alarm | feature/cloudwatch-alarm |
| <a name="module_centralize_log_bucket"></a> [centralize\_log\_bucket](#module\_centralize\_log\_bucket) | git@github.com:oozou/terraform-aws-s3               | v1.0.4                   |
| <a name="module_cloudtrail_kms"></a> [cloudtrail\_kms](#module\_cloudtrail\_kms)                        | git@github.com:oozou/terraform-aws-kms-key.git      | v1.0.0                   |

## Resources

| Name                                                                                                                                              | Type        |
|---------------------------------------------------------------------------------------------------------------------------------------------------|-------------|
| [aws_cloudtrail.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudtrail)                                     | resource    |
| [aws_cloudwatch_log_group.trail_log](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group)            | resource    |
| [aws_cloudwatch_log_metric_filter.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_metric_filter) | resource    |
| [aws_iam_policy.cloudtrail_put_log_cw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy)                    | resource    |
| [aws_iam_role.cloudtrail_put_log_cw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role)                        | resource    |
| [aws_caller_identity.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity)                        | data source |
| [aws_iam_policy_document.kms_cloudtrail](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document)      | data source |
| [aws_iam_policy_document.s3_cloudtrail](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document)       | data source |
| [aws_region.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region)                                          | data source |

## Inputs

| Name                                                                                                                                                               | Description                                                                                                                                                                                          | Type                                                                                                                                                                                                                            | Default | Required |
|--------------------------------------------------------------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|---------|:--------:|
| <a name="input_account_mode"></a> [account\_mode](#input\_account\_mode)                                                                                           | Account mode for provision cloudtrail, if account\_mode is hub, will provision S3, KMS, CloudTrail. if account\_mode is spoke, will provision only CloudTrail                                        | `string`                                                                                                                                                                                                                        | n/a     |   yes    |
| <a name="input_additional_cloudwatch_log_metric_filters"></a> [additional\_cloudwatch\_log\_metric\_filters](#input\_additional\_cloudwatch\_log\_metric\_filters) | (optional) Additional cloudwatch log filter                                                                                                                                                          | `any`                                                                                                                                                                                                                           | `{}`    |    no    |
| <a name="input_centralize_trail_bucket_lifecycle_rule"></a> [centralize\_trail\_bucket\_lifecycle\_rule](#input\_centralize\_trail\_bucket\_lifecycle\_rule)       | List of lifecycle rules to transition the data. Leave empty to disable this feature. storage\_class can be STANDARD\_IA, ONEZONE\_IA, INTELLIGENT\_TIERING, GLACIER, or DEEP\_ARCHIVE                | <pre>list(object({<br>    id = string<br><br>    transition = list(object({<br>      days          = number<br>      storage_class = string<br>    }))<br><br>    expiration_days = number<br>  }))</pre>                       | `[]`    |    no    |
| <a name="input_centralize_trail_bucket_name"></a> [centralize\_trail\_bucket\_name](#input\_centralize\_trail\_bucket\_name)                                       | S3 bucket for store Cloudtrail log (long terms), leave this default if account\_mode is hub. If account\_mode is SPOKE, please provide centrailize S3 bucket name (hub).                             | `string`                                                                                                                                                                                                                        | `""`    |    no    |
| <a name="input_cloudwatch_log_retention_in_days"></a> [cloudwatch\_log\_retention\_in\_days](#input\_cloudwatch\_log\_retention\_in\_days)                         | (optional) describe your variable                                                                                                                                                                    | `number`                                                                                                                                                                                                                        | `365`   |    no    |
| <a name="input_default_alarm_actions"></a> [default\_alarm\_actions](#input\_default\_alarm\_actions)                                                              | The list of actions to execute when this alarm transitions into an ALARM state from any other state. Each action is specified as an Amazon Resource Name (ARN).                                      | `list(string)`                                                                                                                                                                                                                  | `[]`    |    no    |
| <a name="input_enable_cloudwatch_log_metric_filters"></a> [enable\_cloudwatch\_log\_metric\_filters](#input\_enable\_cloudwatch\_log\_metric\_filters)             | (optional) list of metrics filter to enable                                                                                                                                                          | `list(string)`                                                                                                                                                                                                                  | `[]`    |    no    |
| <a name="input_enable_log_file_validation"></a> [enable\_log\_file\_validation](#input\_enable\_log\_file\_validation)                                             | Specifies whether log file integrity validation is enabled. Creates signed digest for validated contents of logs                                                                                     | `bool`                                                                                                                                                                                                                          | `true`  |    no    |
| <a name="input_enable_logging"></a> [enable\_logging](#input\_enable\_logging)                                                                                     | Enable logging for the trail                                                                                                                                                                         | `bool`                                                                                                                                                                                                                          | `true`  |    no    |
| <a name="input_environment"></a> [environment](#input\_environment)                                                                                                | Environment name used as environment resources name.                                                                                                                                                 | `string`                                                                                                                                                                                                                        | n/a     |   yes    |
| <a name="input_event_selector"></a> [event\_selector](#input\_event\_selector)                                                                                     | Specifies an event selector for enabling data event logging. See: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudtrail#event_selector for details on this variable | <pre>list(object({<br>    include_management_events = bool<br>    read_write_type           = string<br><br>    data_resource = list(object({<br>      type   = string<br>      values = list(string)<br>    }))<br>  }))</pre> | `[]`    |    no    |
| <a name="input_include_global_service_events"></a> [include\_global\_service\_events](#input\_include\_global\_service\_events)                                    | Specifies whether the trail is publishing events from global services such as IAM to the log files                                                                                                   | `bool`                                                                                                                                                                                                                          | `true`  |    no    |
| <a name="input_is_cloudtrail_encrypted"></a> [is\_cloudtrail\_encrypted](#input\_is\_cloudtrail\_encrypted)                                                        | Whether Cloudtrail encryption enable or not.                                                                                                                                                         | `bool`                                                                                                                                                                                                                          | `true`  |    no    |
| <a name="input_is_create_monitor_trail"></a> [is\_create\_monitor\_trail](#input\_is\_create\_monitor\_trail)                                                      | Whether to create monitor trails.                                                                                                                                                                    | `bool`                                                                                                                                                                                                                          | `true`  |    no    |
| <a name="input_is_multi_region_trail"></a> [is\_multi\_region\_trail](#input\_is\_multi\_region\_trail)                                                            | Specifies whether the trail is created in the current region or in all regions                                                                                                                       | `bool`                                                                                                                                                                                                                          | `true`  |    no    |
| <a name="input_kms_key_id"></a> [kms\_key\_id](#input\_kms\_key\_id)                                                                                               | The ARN for the KMS encryption key. Leave this default if account\_mode is hub. If account\_mode is SPOKE, please provide centrailize kms key arn (hub).                                             | `string`                                                                                                                                                                                                                        | `""`    |    no    |
| <a name="input_prefix"></a> [prefix](#input\_prefix)                                                                                                               | The prefix name of customer to be displayed in AWS console and resource                                                                                                                              | `string`                                                                                                                                                                                                                        | n/a     |   yes    |
| <a name="input_spoke_account_ids"></a> [spoke\_account\_ids](#input\_spoke\_account\_ids)                                                                          | Spoke account Ids, if mode is hub.                                                                                                                                                                   | `list(string)`                                                                                                                                                                                                                  | `[]`    |    no    |
| <a name="input_tags"></a> [tags](#input\_tags)                                                                                                                     | Tags to add more; default tags contian {terraform=true, environment=var.environment}                                                                                                                 | `map(string)`                                                                                                                                                                                                                   | `{}`    |    no    |

## Outputs

| Name                                                                                                       | Description    |
|------------------------------------------------------------------------------------------------------------|----------------|
| <a name="output_centralize_bucket_arn"></a> [centralize\_bucket\_arn](#output\_centralize\_bucket\_arn)    | S3 Bucket ARN  |
| <a name="output_centralize_bucket_name"></a> [centralize\_bucket\_name](#output\_centralize\_bucket\_name) | S3 Bucket Name |
| <a name="output_centralize_key_arn"></a> [centralize\_key\_arn](#output\_centralize\_key\_arn)             | KMS key arn    |
| <a name="output_centralize_key_id"></a> [centralize\_key\_id](#output\_centralize\_key\_id)                | KMS key id     |
| <a name="output_cloudtrail_arn"></a> [cloudtrail\_arn](#output\_cloudtrail\_arn)                           | S3 Bucket ARN  |
| <a name="output_cloudtrail_id"></a> [cloudtrail\_id](#output\_cloudtrail\_id)                              | S3 Bucket Id   |
<!-- END_TF_DOCS -->
