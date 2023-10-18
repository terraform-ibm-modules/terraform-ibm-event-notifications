##############################################################################
# Resource group
##############################################################################

module "resource_group" {
  source  = "terraform-ibm-modules/resource-group/ibm"
  version = "1.0.6"
  # if an existing resource group is not set (null) create a new one using prefix
  resource_group_name          = var.resource_group == null ? "${var.prefix}-resource-group" : null
  existing_resource_group_name = var.resource_group
}

module "key_protect_all_inclusive" {
  source                    = "terraform-ibm-modules/key-protect-all-inclusive/ibm"
  version                   = "4.2.0"
  resource_group_id         = module.resource_group.resource_group_id
  region                    = var.region
  key_protect_instance_name = "${var.prefix}-kp"
  resource_tags             = var.tags
  key_map                   = { "en" = ["${var.prefix}-en"] }
}

##############################################################################
# Get Cloud Account ID
##############################################################################

data "ibm_iam_account_settings" "iam_account_settings" {
}

##############################################################################
# VPC
##############################################################################

module "vpc" {
  source            = "terraform-ibm-modules/landing-zone-vpc/ibm"
  version           = "7.3.1"
  resource_group_id = module.resource_group.resource_group_id
  region            = var.region
  prefix            = var.prefix
  name              = "vpc"
  tags              = var.tags
}

##############################################################################
# Create CBR Zone
##############################################################################

module "cbr_zone" {
  source           = "terraform-ibm-modules/cbr/ibm//modules/cbr-zone-module"
  version          = "1.15.1"
  name             = "${var.prefix}-VPC-network-zone"
  zone_description = "CBR Network zone representing VPC"
  account_id       = data.ibm_iam_account_settings.iam_account_settings.account_id
  addresses = [{
    type  = "vpc",
    value = module.vpc.vpc_crn,
  }]
}

module "event_notification" {
  source                     = "../../"
  resource_group_id          = module.resource_group.resource_group_id
  name                       = "${var.prefix}-en"
  kms_encryption_enabled     = true
  kms_key_crn                = module.key_protect_all_inclusive.keys["en.${var.prefix}-en"].crn
  existing_kms_instance_guid = module.key_protect_all_inclusive.key_protect_guid
  tags                       = var.tags
  service_endpoints          = "public"
  cbr_rules = [
    {
      description      = "${var.prefix}-event notification access only from vpc"
      enforcement_mode = "enabled"
      account_id       = data.ibm_iam_account_settings.iam_account_settings.account_id
      rule_contexts = [{
        attributes = [
          {
            "name" : "endpointType",
            "value" : "public"
          },
          {
            name  = "networkZoneId"
            value = module.cbr_zone.zone_id
        }]
      }]
    }
  ]
}
