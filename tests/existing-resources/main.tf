module "resource_group" {
  source                       = "terraform-ibm-modules/resource-group/ibm"
  version                      = "1.1.6"
  resource_group_name          = var.resource_group == null ? "${var.prefix}-resource-group" : null
  existing_resource_group_name = var.resource_group
}

module "event_notification" {
  source                  = "../../"
  resource_group_id       = module.resource_group.resource_group_id
  name                    = "${var.prefix}-en"
  tags                    = var.resource_tags
  plan                    = "lite"
  service_endpoints       = "public"
  region                  = var.region
  cos_integration_enabled = false
}

module "cos" {
  source                 = "terraform-ibm-modules/cos/ibm"
  version                = "8.20.2"
  resource_group_id      = module.resource_group.resource_group_id
  region                 = var.region
  cos_instance_name      = "${var.prefix}-cos"
  cos_tags               = var.resource_tags
  bucket_name            = "${var.prefix}-bucket"
  retention_enabled      = false
  kms_encryption_enabled = false
}
