locals {
  name = "account-${var.environment}-monitor-trail"

  kms_key_id = length(var.kms_key_id) > 0 ? var.kms_key_id : join("", module.cloudtrail_kms.*.key_arn)

  tags = merge(
    {
      Terraform   = true
      Environment = var.environment
    },
    var.custom_tags
  )
}
