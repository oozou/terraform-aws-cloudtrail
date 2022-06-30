/* -------------------------------------------------------------------------- */
/*                                   AWS_KMS                                  */
/* -------------------------------------------------------------------------- */
module "cloudtrail_kms" {
  count = 1 - local.account_mode

  source      = "git@github.com:oozou/terraform-aws-kms-key.git?ref=v1.0.0"
  key_type    = "service"
  description = "Used to encrypt data in for account centralize monitor trail"
  prefix      = var.prefix
  name        = "account-trail"
  environment = "centralize"

  additional_policies = [data.aws_iam_policy_document.kms_cloudtrail[count.index].json]

  tags = var.tags
}
