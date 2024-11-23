##############################################################################
# Resource group
##############################################################################

module "resource_group" {
  source  = "terraform-ibm-modules/resource-group/ibm"
  version = "1.1.6"
  # if an existing resource group is not set (null) create a new one using prefix
  resource_group_name          = var.resource_group == null ? "${var.prefix}-resource-group" : null
  existing_resource_group_name = var.resource_group
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

module "cbr_vpc_zone" {
  source           = "terraform-ibm-modules/cbr/ibm//modules/cbr-zone-module"
  version          = "1.29.0"
  name             = "${var.prefix}-VPC-network-zone"
  zone_description = "CBR Network zone representing VPC"
  account_id       = data.ibm_iam_account_settings.iam_account_settings.account_id
  addresses = [{
    type  = "vpc",
    value = ibm_is_vpc.example_vpc.crn
  }]
}

module "cbr_zone_schematics" {
  source           = "terraform-ibm-modules/cbr/ibm//modules/cbr-zone-module"
  version          = "1.29.0"
  name             = "${var.prefix}-schematics-zone"
  zone_description = "CBR Network zone containing Schematics"
  account_id       = data.ibm_iam_account_settings.iam_account_settings.account_id
  addresses = [{
    type = "serviceRef",
    ref = {
      account_id   = data.ibm_iam_account_settings.iam_account_settings.account_id
      service_name = "schematics"
    }
  }]
}

##############################################################################
# Create COS Instance
##############################################################################

locals {
  bucket_name       = "cos-bucket"
  kms_instance_guid = element(split(":", var.existing_kms_instance_crn), length(split(":", var.existing_kms_instance_crn)) - 3)
  root_key_id       = element(split(":", var.root_key_crn), length(split(":", var.root_key_crn)) - 1)
}

module "cos" {
  source              = "terraform-ibm-modules/cos/ibm//modules/fscloud"
  version             = "8.15.1"
  resource_group_id   = module.resource_group.resource_group_id
  create_cos_instance = true
  cos_instance_name   = "${var.prefix}-cos"
  cos_plan            = "standard"
  bucket_configs = [{
    access_tags                   = []
    add_bucket_name_suffix        = true
    bucket_name                   = local.bucket_name
    kms_encryption_enabled        = true
    kms_guid                      = local.kms_instance_guid
    kms_key_crn                   = var.root_key_crn
    skip_iam_authorization_policy = false
    management_endpoint_type      = "private"
    storage_class                 = "smart"
    region_location               = var.region
    force_delete                  = true
  }]
}

##############################################################################
# Create Event Notifications Instance
##############################################################################

module "event_notification" {
  source                    = "../../modules/fscloud"
  resource_group_id         = module.resource_group.resource_group_id
  name                      = "${var.prefix}-en-fs"
  existing_kms_instance_crn = var.existing_kms_instance_crn
  root_key_id               = local.root_key_id
  kms_endpoint_url          = var.kms_endpoint_url
  tags                      = var.resource_tags

  # Map of name, role for service credentials that you want to create for the event notification
  service_credential_names = {
    "en_manager" : "Manager",
    "en_writer" : "Writer",
    "en_reader" : "Reader",
    "en_channel_editor" : "Channel Editor",
    "en_device_manager" : "Device Manager",
    "en_event_source_manager" : "Event Source Manager",
    "en_event_notifications_publisher" : "Event Notification Publisher",
    "en_status_reporter" : "Status Reporter",
    "en_email_sender" : "Email Sender",
    "en_custom_email_status_reporter" : "Custom Email Status Reporter",
  }
  region = var.region
  # COS Related
  cos_bucket_name         = module.cos.buckets[local.bucket_name].bucket_name
  cos_instance_id         = module.cos.cos_instance_crn
  skip_en_cos_auth_policy = false
  cos_endpoint            = "https://${module.cos.buckets[local.bucket_name].s3_endpoint_private}"
  cbr_rules = [
    {
      description      = "${var.prefix}-event notification access from vpc and schematics"
      enforcement_mode = "enabled"
      account_id       = data.ibm_iam_account_settings.iam_account_settings.account_id
      rule_contexts = [{
        attributes = [
          {
            "name" : "endpointType",
            "value" : "private"
          },
          {
            name  = "networkZoneId"
            value = module.cbr_vpc_zone.zone_id
        }]
        }, {
        attributes = [
          {
            "name" : "endpointType",
            "value" : "private"
          },
          {
            name  = "networkZoneId"
            value = module.cbr_zone_schematics.zone_id
        }]
      }]
    }
  ]
}
