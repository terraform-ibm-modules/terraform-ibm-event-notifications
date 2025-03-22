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
  version                   = "4.21.2"
  resource_group_id         = module.resource_group.resource_group_id
  region                    = var.region
  key_protect_instance_name = "${var.prefix}-kp"
  resource_tags             = var.resource_tags
  keys = [{
    key_ring_name = local.key_ring_name
    keys = [{
      key_name     = local.key_name
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
  version                = "8.21.2"
  resource_group_id      = module.resource_group.resource_group_id
  region                 = var.region
  cos_instance_name      = "${var.prefix}-cos"
  cos_tags               = var.resource_tags
  bucket_name            = local.bucket_name
  retention_enabled      = false # disable retention for test environments - enable for stage/prod
  kms_encryption_enabled = false
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
  access_tags               = var.access_tags
  service_endpoints         = "public"
  service_credential_names  = var.service_credential_names
  region                    = var.region
  # COS Related
  cos_integration_enabled = true
  cos_bucket_name         = module.cos.bucket_name
  cos_instance_id         = module.cos.cos_instance_crn
  cos_endpoint            = "https://${module.cos.s3_endpoint_public}"
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
