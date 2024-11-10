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
# Key Protect All Inclusive
##############################################################################

locals {
  key_ring_name = "en-key-ring"
  key_name      = "${var.prefix}-en"
}

module "key_protect_all_inclusive" {
  source                    = "terraform-ibm-modules/kms-all-inclusive/ibm"
  version                   = "4.16.8"
  resource_group_id         = module.resource_group.resource_group_id
  region                    = var.region
  key_protect_instance_name = "${var.prefix}-kp"
  resource_tags             = var.resource_tags
  keys = [{
    key_ring_name         = "en-key-ring"
    force_delete_key_ring = true
    keys = [{
      key_name     = "${var.prefix}-en"
      force_delete = true
    }]
  }]
}

##############################################################################
# Create Cloud Object Storage instance and a bucket
##############################################################################

locals {
  bucket_name = "${var.prefix}-bucket"
}

module "cos" {
  source                 = "terraform-ibm-modules/cos/ibm"
  version                = "8.14.3"
  resource_group_id      = module.resource_group.resource_group_id
  region                 = var.region
  cos_instance_name      = "${var.prefix}-cos"
  cos_tags               = var.resource_tags
  bucket_name            = local.bucket_name
  retention_enabled      = false # disable retention for test environments - enable for stage/prod
  kms_encryption_enabled = false
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
  version          = "1.28.1"
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
  version          = "1.28.1"
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

#############################################################################
# Create EN instance, destination, topic and subscription
##############################################################################

module "event_notification" {
  source                    = "../../"
  resource_group_id         = module.resource_group.resource_group_id
  name                      = "${var.prefix}-en"
  kms_encryption_enabled    = true
  existing_kms_instance_crn = module.key_protect_all_inclusive.key_protect_id
  root_key_id               = module.key_protect_all_inclusive.keys["${local.key_ring_name}.${local.key_name}"].key_id
  kms_endpoint_url          = module.key_protect_all_inclusive.kms_public_endpoint
  tags                      = var.resource_tags
  service_endpoints         = "public"
  service_credential_names  = var.service_credential_names
  region                    = var.region
  # COS Related
  cos_integration_enabled = true
  cos_bucket_name         = module.cos.bucket_name
  cos_instance_id         = module.cos.cos_instance_crn
  cos_endpoint            = "https://${module.cos.s3_endpoint_public}"
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
            value = module.cbr_vpc_zone.zone_id
        }]
        }, {
        attributes = [
          {
            "name" : "endpointType",
            "value" : "public"
          },
          {
            name  = "networkZoneId"
            value = module.cbr_zone_schematics.zone_id
        }]
      }]
    }
  ]
}

resource "ibm_en_destination_webhook" "webhook_destination" {
  instance_guid         = module.event_notification.guid
  name                  = "${var.prefix}-webhook-destination"
  type                  = "webhook"
  collect_failed_events = false
  description           = "Destination webhook for event notification"
  config {
    params {
      verb = "POST"
      url  = "https://testwebhook.com"
      custom_headers = {
        "authorization" = "authorization"
      }
      sensitive_headers = ["authorization"]
    }
  }
}

resource "ibm_en_topic" "webhook_topic" {
  instance_guid = module.event_notification.guid
  name          = "${var.prefix}-e2e-topic"
  description   = "Topic for EN events routing"
}

resource "ibm_en_subscription_webhook" "webhook_subscription" {
  instance_guid  = module.event_notification.guid
  name           = "${var.prefix}-webhook-subscription"
  description    = "The webhook subscription"
  destination_id = ibm_en_destination_webhook.webhook_destination.destination_id
  topic_id       = ibm_en_topic.webhook_topic.topic_id
  attributes {
    signing_enabled = true
  }
}
