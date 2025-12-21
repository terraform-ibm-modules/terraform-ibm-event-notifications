module "resource_group" {
  source                       = "terraform-ibm-modules/resource-group/ibm"
  version                      = "1.4.7"
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
  version                = "10.7.6"
  resource_group_id      = module.resource_group.resource_group_id
  region                 = var.region
  cos_instance_name      = "${var.prefix}-cos"
  cos_tags               = var.resource_tags
  bucket_name            = "${var.prefix}-bucket"
  retention_enabled      = false
  kms_encryption_enabled = false
}

module "cloud_monitoring" {
  source            = "terraform-ibm-modules/cloud-monitoring/ibm"
  version           = "1.12.6"
  resource_group_id = module.resource_group.resource_group_id
  region            = var.region
  resource_tags     = var.resource_tags
  instance_name     = "${var.prefix}-cloud-monitoring"
}

module "kms_key" {
  source          = "terraform-ibm-modules/kms-key/ibm"
  version         = "1.4.17"
  kms_instance_id = "crn:v1:bluemix:public:hs-crypto:us-south:a/abac0df06b644a9cabc6e44f55b3880e:e6dce284-e80f-46e1-a3c1-830f7adff7a9::"
  key_name        = "${var.prefix}-root-key"
  force_delete    = true # Setting it to true for testing purpose
}
