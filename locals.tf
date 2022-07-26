# locals for using as references.
locals {
  #spoke = 1, hub = 0
  account_mode = var.account_mode != "hub" ? 1 : 0

  name = "${var.prefix}-${var.environment}-trail"

  account_ids = concat(var.spoke_account_ids, [data.aws_caller_identity.this.account_id])

  policy_identifiers = [for account in local.account_ids : join("", ["arn:aws:iam::", account, ":root"])]

  kms_key_id = var.kms_key_id != "" ? var.kms_key_id : join("", module.cloudtrail_kms.*.key_arn)

  centralize_log_bucket_arn = var.centralize_trail_bucket_name == "" ? try(module.centralize_log_bucket[0].bucket_arn, "") : join("", ["arn:aws:s3:::", var.centralize_trail_bucket_name])

  tags = merge(
    {
      Terraform   = true
      Environment = var.environment
    },
    var.tags
  )
}

# preflight locals for checking valid input variables.
locals {
  #spoke check
  check_kms_key_spoke_empty   = local.account_mode == 1 && var.kms_key_id == "" ? file("If account_mode is spoke, kms_key_id must not be empty.") : null
  check_s3_bucket_spoke_empty = local.account_mode == 1 && var.centralize_trail_bucket_name == "" ? file("If account_mode is spoke, centralize_trail_bucket_name must not be empty.") : null
  #hub check
  check_kms_key_hub_not_empty   = local.account_mode == 0 && var.kms_key_id != "" ? file("If account_mode is hub, kms_key_id must be empty.") : null
  check_s3_bucket_hub_not_empty = local.account_mode == 0 && var.centralize_trail_bucket_name != "" ? file("If account_mode is hub, centralize_trail_bucket_name must be empty.") : null
}

# Operator
locals {
  comparison_operators = {
    ">=" = "GreaterThanOrEqualToThreshold",
    ">"  = "GreaterThanThreshold",
    "<"  = "LessThanThreshold",
    "<=" = "LessThanOrEqualToThreshold",
  }
}

locals {
  enable_cloudwatch_log_metric_filters = length(var.additional_cloudwatch_log_metric_filters) == 0 ? var.enable_cloudwatch_log_metric_filters : concat(var.enable_cloudwatch_log_metric_filters, keys(var.additional_cloudwatch_log_metric_filters))
  metric_filters = merge(
    {
      authorization_failures = {
        comparison_operator = ">="
        threshold           = "5"
        evaluation_periods  = "1"
        period              = "300"
        pattern             = "{ ($.errorCode = \"*UnauthorizedOperation\") || ($.errorCode = \"AccessDenied*\") }"
        alarm_actions       = []
      }
      cloudtrail_changes = {
        comparison_operator = ">="
        threshold           = "5"
        evaluation_periods  = "1"
        period              = "300"
        pattern             = "{ ($.eventName = CreateTrail) || ($.eventName = UpdateTrail) || ($.eventName = DeleteTrail) || ($.eventName = StartLogging) || ($.eventName = StopLogging) }"
        alarm_actions       = []
      }
      config_activity = {
        comparison_operator = ">="
        threshold           = "5"
        evaluation_periods  = "1"
        period              = "300"
        pattern             = "{ ($.eventSource = config.amazonaws.com) && (($.eventName = StopConfigurationRecorder)||($.eventName = DeleteDeliveryChannel)||($.eventName = PutDeliveryChannel)||($.eventName = PutConfigurationRecorder)) }"
        alarm_actions       = []
      }
      console_signin_failures = {
        comparison_operator = ">="
        threshold           = "5"
        evaluation_periods  = "1"
        period              = "300"
        pattern             = "{ ($.eventName = ConsoleLogin) && ($.errorMessage = \"Failed authentication\") }"
        alarm_actions       = []
      }
      console_signin_without_mfa = {
        comparison_operator = ">="
        threshold           = "1"
        evaluation_periods  = "1"
        period              = "300"
        pattern             = "{ ($.eventName = \"ConsoleLogin\") && ($.additionalEventData.MFAUsed != \"Yes\") }"
        alarm_actions       = []
      }
      deleted_kms_cmk_activity = {
        comparison_operator = ">="
        threshold           = "5"
        evaluation_periods  = "1"
        period              = "300"
        pattern             = "{ ($.eventSource = kms.amazonaws.com) && (($.eventName= DisableKey) || ($.eventName= ScheduleKeyDeletion))}"
        alarm_actions       = []
      }
      gateway_changes = {
        comparison_operator = ">="
        threshold           = "5"
        evaluation_periods  = "1"
        period              = "300"
        pattern             = "{ ($.eventName = CreateCustomerGateway) || ($.eventName = DeleteCustomerGateway) || ($.eventName = AttachInternetGateway) || ($.eventName = CreateInternetGateway) || ($.eventName = DeleteInternetGateway) || ($.eventName = DetachInternetGateway) }"
        alarm_actions       = []
      }
      iam_policy_changes = {
        comparison_operator = ">="
        threshold           = "5"
        evaluation_periods  = "1"
        period              = "300"
        pattern             = "{($.eventName=DeleteGroupPolicy)||($.eventName=DeleteRolePolicy)||($.eventName=DeleteUserPolicy)||($.eventName=PutGroupPolicy)||($.eventName=PutRolePolicy)||($.eventName=PutUserPolicy)||($.eventName=CreatePolicy)||($.eventName=DeletePolicy)||($.eventName=CreatePolicyVersion)||($.eventName=DeletePolicyVersion)||($.eventName=AttachRolePolicy)||($.eventName=DetachRolePolicy)||($.eventName=AttachUserPolicy)||($.eventName=DetachUserPolicy)||($.eventName=AttachGroupPolicy)||($.eventName=DetachGroupPolicy)}"
        alarm_actions       = []
      }
      network_acl_events = {
        comparison_operator = ">="
        threshold           = "5"
        evaluation_periods  = "1"
        period              = "300"
        pattern             = "{ ($.eventName = CreateNetworkAcl) || ($.eventName = CreateNetworkAclEntry) || ($.eventName = DeleteNetworkAcl) || ($.eventName = DeleteNetworkAclEntry) || ($.eventName = ReplaceNetworkAclEntry) || ($.eventName = ReplaceNetworkAclAssociation) }"
        alarm_actions       = []
      }
      root_account_usage = {
        comparison_operator = ">="
        threshold           = "5"
        evaluation_periods  = "1"
        period              = "300"
        pattern             = "{ $.userIdentity.type = \"Root\" && $.userIdentity.invokedBy NOT EXISTS && $.eventType != \"AwsServiceEvent\" }"
        alarm_actions       = []
      }
      s3_bucket_activity = {
        comparison_operator = ">="
        threshold           = "5"
        evaluation_periods  = "1"
        period              = "300"
        pattern             = "{ ($.eventSource = s3.amazonaws.com) && (($.eventName = PutBucketAcl) || ($.eventName = PutBucketPolicy) || ($.eventName = PutBucketCors) || ($.eventName = PutBucketLifecycle) || ($.eventName = PutBucketReplication) || ($.eventName = DeleteBucketPolicy) || ($.eventName = DeleteBucketCors) || ($.eventName = DeleteBucketLifecycle) || ($.eventName = DeleteBucketReplication)) }"
        alarm_actions       = []
      }
      security_group_events = {
        comparison_operator = ">="
        threshold           = "5"
        evaluation_periods  = "1"
        period              = "300"
        pattern             = "{ ($.eventName = AuthorizeSecurityGroupIngress) || ($.eventName = AuthorizeSecurityGroupEgress) || ($.eventName = RevokeSecurityGroupIngress) || ($.eventName = RevokeSecurityGroupEgress) || ($.eventName = CreateSecurityGroup) || ($.eventName = DeleteSecurityGroup) }"
        alarm_actions       = []
      }
      vpc_changes = {
        comparison_operator = ">="
        threshold           = "5"
        evaluation_periods  = "1"
        period              = "300"
        pattern             = "{ ($.eventName = CreateVpc) || ($.eventName = DeleteVpc) || ($.eventName = ModifyVpcAttribute) || ($.eventName = AcceptVpcPeeringConnection) || ($.eventName = CreateVpcPeeringConnection) || ($.eventName = DeleteVpcPeeringConnection) || ($.eventName = RejectVpcPeeringConnection) || ($.eventName = AttachClassicLinkVpc) || ($.eventName = DetachClassicLinkVpc) || ($.eventName = DisableVpcClassicLink) || ($.eventName = EnableVpcClassicLink) }"
        alarm_actions       = []
      }
      vpc_route_table_changes = {
        comparison_operator = ">="
        threshold           = "5"
        evaluation_periods  = "1"
        period              = "300"
        pattern             = "{ ($.eventName = CreateRoute) || ($.eventName = CreateRouteTable) || ($.eventName = ReplaceRoute) || ($.eventName = ReplaceRouteTableAssociation) || ($.eventName = DeleteRouteTable) || ($.eventName = DeleteRoute) || ($.eventName = DisassociateRouteTable) }"
        alarm_actions       = []
      }
    },
    var.additional_cloudwatch_log_metric_filters
  )
}
