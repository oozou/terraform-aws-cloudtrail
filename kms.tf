/* -------------------------------------------------------------------------- */
/*                                   AWS_KMS                                  */
/* -------------------------------------------------------------------------- */
module "cloudtrail_kms" {
  source  = "oozou/kms-key/aws"
  version = "1.0.0"

  count = var.kms_key_id == "" ? 1 - local.account_mode : 0

  key_type    = "service"
  description = "Used to encrypt data in for account centralize monitor trail"
  prefix      = var.prefix
  name        = "account-trail"
  environment = "centralize"

  additional_policies = [data.aws_iam_policy_document.kms_cloudtrail[count.index].json]

  tags = var.tags
}
