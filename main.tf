/* -------------------------------------------------------------------------- */
/*                    Cloudtrail access CloudWatch role                       */
/* -------------------------------------------------------------------------- */
#CloudTrail Policy to push log to loggroup
resource "aws_iam_policy" "cloudtrail_put_log_cw" {
  count       = var.is_create_monitor_trail ? 1 : 0
  name        = "${local.name}-pushlog-policy"
  description = "${local.name}-pushlog-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Effect" = "Allow"
        "Action" = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        "Resource" = "*"
      },
    ]
  })
  tags = merge(local.tags, { Name = "${local.name}-pushlog-policy" })
}
#CloudTrail Role
resource "aws_iam_role" "cloudtrail_put_log_cw" {
  count               = var.is_create_monitor_trail ? 1 : 0
  name                = "${local.name}-role"
  managed_policy_arns = [aws_iam_policy.cloudtrail_put_log_cw[count.index].arn]
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : [
            "cloudtrail.amazonaws.com"
          ]
        },
        "Action" : [
          "sts:AssumeRole"
        ]
      }
    ]
  })

  tags = merge(local.tags, { Name = "${local.name}-role" })
}

/* -------------------------------------------------------------------------- */
/*                           CloudWatch logs group                            */
/* -------------------------------------------------------------------------- */
#CloudWatch Log group for CloudTrail
resource "aws_cloudwatch_log_group" "trail_log" {
  count             = var.is_create_monitor_trail ? 1 : 0
  name              = "/aws/cloudtrail/${local.name}"
  retention_in_days = var.cloudwatch_log_retention_in_days
  kms_key_id        = local.kms_key_id

  tags = merge(local.tags, { Name = "/aws/cloudtrail/${local.name}" })
}

module "alarm" {
  source  = "oozou/cloudwatch-alarm/aws"
  version = "1.0.0"

  for_each = var.is_create_monitor_trail ? toset(local.enable_cloudwatch_log_metric_filters) : toset([])

  prefix      = var.prefix
  environment = var.environment
  name        = format("trail-%s", replace(each.key, "_", "-"))

  comparison_operator = local.comparison_operators[lookup(local.metric_filters[each.key], "comparison_operator", null)]
  evaluation_periods  = lookup(local.metric_filters[each.key], "evaluation_periods", null)
  metric_name         = format("%s-%s-metric", local.name, replace(each.key, "_", "-"))
  namespace           = lookup(local.metric_filters[each.key], "namespace", "CloudTrailMetrics")
  period              = lookup(local.metric_filters[each.key], "period", null)
  statistic           = lookup(local.metric_filters[each.key], "statistic", "Sum")
  threshold           = lookup(local.metric_filters[each.key], "threshold", null)

  alarm_actions = lookup(local.metric_filters[each.key], "alarm_actions", var.default_alarm_actions)

  tags = var.tags
}

resource "aws_cloudwatch_log_metric_filter" "this" {
  for_each = var.is_create_monitor_trail ? toset(local.enable_cloudwatch_log_metric_filters) : toset([])

  name           = format("%s-%s-filter", local.name, replace(each.key, "_", "-"))
  pattern        = lookup(local.metric_filters[each.key], "pattern", null)
  log_group_name = aws_cloudwatch_log_group.trail_log[0].name

  metric_transformation {
    name      = format("%s-%s-metric", local.name, replace(each.key, "_", "-"))
    namespace = lookup(local.metric_filters[each.key], "namespace", "CloudTrailMetrics")
    value     = lookup(local.metric_filters[each.key], "metric_transformation_value", "1")
  }
}

/* -------------------------------------------------------------------------- */
/*                           CloudTrail Rule                                  */
/* -------------------------------------------------------------------------- */
resource "aws_cloudtrail" "this" {
  count = var.is_create_monitor_trail ? 1 : 0

  name                          = "${local.name}-${data.aws_caller_identity.this.account_id}"
  s3_bucket_name                = local.account_mode == 0 && var.centralize_trail_bucket_name == "" ? module.centralize_log_bucket[count.index].bucket_name : var.centralize_trail_bucket_name
  include_global_service_events = var.include_global_service_events
  cloud_watch_logs_group_arn    = "${aws_cloudwatch_log_group.trail_log[count.index].arn}:*"
  cloud_watch_logs_role_arn     = aws_iam_role.cloudtrail_put_log_cw[count.index].arn
  enable_log_file_validation    = var.enable_log_file_validation
  kms_key_id                    = var.is_cloudtrail_encrypted ? local.kms_key_id : null
  is_multi_region_trail         = var.is_multi_region_trail
  enable_logging                = var.enable_logging
  dynamic "event_selector" {
    for_each = var.event_selector
    content {
      include_management_events = lookup(event_selector.value, "include_management_events", null)
      read_write_type           = lookup(event_selector.value, "read_write_type", null)
      dynamic "data_resource" {
        for_each = lookup(event_selector.value, "data_resource", [])
        content {
          type   = data_resource.value.type
          values = data_resource.value.values
        }
      }
    }
  }

  tags = merge(local.tags, { Name = "${local.name}-${data.aws_caller_identity.this.account_id}" })
}
