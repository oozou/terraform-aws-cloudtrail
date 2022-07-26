module "hub_cloudtrail" {
  source = "../../"

  prefix       = var.prefix
  environment  = var.environment
  account_mode = "hub"

  spoke_account_ids = []
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

  tags = var.custom_tags
}
