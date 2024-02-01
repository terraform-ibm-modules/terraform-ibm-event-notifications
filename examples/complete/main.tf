##############################################################################
# Resource group
##############################################################################

module "resource_group" {
  source  = "terraform-ibm-modules/resource-group/ibm"
  version = "1.1.4"
  # if an existing resource group is not set (null) create a new one using prefix
  resource_group_name          = var.resource_group == null ? "${var.prefix}-resource-group" : null
  existing_resource_group_name = var.resource_group
}

##############################################################################
# Key Protect All Inclusive
##############################################################################

locals {
  key_ring_name = "en-key-ring"
  key_name      = "${var.prefix}-en"
}
module "key_protect_all_inclusive" {
  source                    = "terraform-ibm-modules/key-protect-all-inclusive/ibm"
  version                   = "4.6.0"
  resource_group_id         = module.resource_group.resource_group_id
  region                    = var.region
  key_protect_instance_name = "${var.prefix}-kp"
  resource_tags             = var.resource_tags
  keys = [{
    key_ring_name = "en-key-ring"
    keys = [{
      key_name = "${var.prefix}-en"
    }]
  }]
}

##############################################################################
# Get Cloud Account ID
##############################################################################

data "ibm_iam_account_settings" "iam_account_settings" {
}

##############################################################################
# VPC
##############################################################################
resource "ibm_is_vpc" "example_vpc" {
  name           = "${var.prefix}-vpc"
  resource_group = module.resource_group.resource_group_id
  tags           = var.resource_tags
}

resource "ibm_is_subnet" "testacc_subnet" {
  name                     = "${var.prefix}-subnet"
  vpc                      = ibm_is_vpc.example_vpc.id
  zone                     = "${var.region}-1"
  total_ipv4_address_count = 256
  resource_group           = module.resource_group.resource_group_id
}

##############################################################################
# Create CBR Zone
##############################################################################

module "cbr_zone" {
  source           = "terraform-ibm-modules/cbr/ibm//modules/cbr-zone-module"
  version          = "1.18.0"
  name             = "${var.prefix}-VPC-network-zone"
  zone_description = "CBR Network zone representing VPC"
  account_id       = data.ibm_iam_account_settings.iam_account_settings.account_id
  addresses = [{
    type  = "vpc",
    value = ibm_is_vpc.example_vpc.crn
  }]
}

module "event_notification" {
  source                    = "../../"
  resource_group_id         = module.resource_group.resource_group_id
  name                      = "${var.prefix}-en"
  kms_encryption_enabled    = true
  existing_kms_instance_crn = module.key_protect_all_inclusive.key_protect_id
  root_key_id               = module.key_protect_all_inclusive.keys["${local.key_ring_name}.${local.key_name}"].key_id
  kms_endpoint_url          = module.key_protect_all_inclusive.kp_public_endpoint
  tags                      = var.resource_tags
  service_endpoints         = "public"
  service_credential_names  = var.service_credential_names
  region                    = var.region
  cbr_rules = [
    {
      description      = "${var.prefix}-event notification access only from vpc"
      enforcement_mode = "report"
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
