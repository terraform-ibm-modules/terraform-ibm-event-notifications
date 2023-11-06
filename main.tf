###########################################################
# This file creates an event notificaiton resource instance
###########################################################
locals {
  # tflint-ignore: terraform_unused_declarations
  validate_kms_plan = var.kms_encryption_enabled && var.plan != "standard" ? tobool("kms encryption is only supported for standard plan") : true
  # tflint-ignore: terraform_unused_declarations
  validate_kms_values = !var.kms_encryption_enabled && (var.existing_kms_instance_crn != null || var.root_key_id != null) ? tobool("When passing values for var.existing_kms_instance_crn or/and var.root_key_id, you must set var.kms_encryption_enabled to true. Otherwise unset them to use default encryption") : true
  # tflint-ignore: terraform_unused_declarations
  validate_kms_vars = var.kms_encryption_enabled && (var.existing_kms_instance_crn == null || var.root_key_id == null) ? tobool("When setting var.kms_encryption_enabled to true, a value must be passed for var.existing_kms_instance_crn and var.root_key_id") : true

  # Determine what KMS service is being used for encryption
  kms_service = var.existing_kms_instance_crn != null ? (
    can(regex(".*kms.*", var.existing_kms_instance_crn)) ? "kms" : (
      can(regex(".*hs-crypto.*", var.existing_kms_instance_crn)) ? "hs-crypto" : null
    )
  ) : null
}

resource "ibm_resource_instance" "en_instance" {
  plan              = var.plan
  location          = var.region
  name              = var.name
  resource_group_id = var.resource_group_id
  tags              = var.tags
  service           = "event-notifications"

  parameters = {
    service-endpoints = var.service_endpoints
  }
}

#############################################################################
# Event Notification KMS integration
#############################################################################

locals {
  en_integration_id = [
    for integrations in data.ibm_en_integrations.en_integrations.integrations :
    integrations.id if integrations.type == local.kms_service
  ]
}
data "ibm_en_integrations" "en_integrations" {
  instance_guid = ibm_resource_instance.en_instance.guid
}

resource "ibm_en_integration" "en_kms_integration" {
  count          = var.kms_encryption_enabled == false || var.skip_iam_authorization_policy ? 0 : 1
  instance_guid  = ibm_resource_instance.en_instance.guid
  integration_id = local.en_integration_id[0]
  type           = local.kms_service
  metadata {
    endpoint    = var.kms_endpoint == "public" ? "https://${var.kms_region}.kms.cloud.ibm.com" : "https://private.${var.kms_region}.kms.cloud.ibm.com"
    crn         = var.existing_kms_instance_crn
    root_key_id = var.root_key_id
  }
}

##############################################################################
# IAM Authorization Policy
##############################################################################

locals {
  existing_kms_instance_guid = element(split(":", var.existing_kms_instance_crn), length(split(":", var.existing_kms_instance_crn)) - 3)
}

# Create IAM Authorization Policies to allow event notification to access kms for the encryption key
resource "ibm_iam_authorization_policy" "kms_policy" {
  count                       = var.kms_encryption_enabled == false || var.skip_iam_authorization_policy ? 0 : 1
  source_service_name         = "event-notifications"
  source_resource_instance_id = ibm_resource_instance.en_instance.guid
  target_service_name         = local.kms_service
  target_resource_instance_id = local.existing_kms_instance_guid
  roles                       = ["Reader"]
  description                 = "Allow all Event Notification instances in the resource group ${var.resource_group_id} to read from the ${local.kms_service} instance GUID ${var.existing_kms_instance_crn}"
}

# workaround for https://github.com/IBM-Cloud/terraform-provider-ibm/issues/4478
resource "time_sleep" "wait_for_authorization_policy" {
  depends_on = [ibm_iam_authorization_policy.kms_policy]

  create_duration = "30s"
}

##############################################################################
# Context Based Restrictions
##############################################################################
module "cbr_rule" {
  count            = length(var.cbr_rules) > 0 ? length(var.cbr_rules) : 0
  source           = "terraform-ibm-modules/cbr/ibm//modules/cbr-rule-module"
  version          = "1.15.1"
  rule_description = var.cbr_rules[count.index].description
  enforcement_mode = var.cbr_rules[count.index].enforcement_mode
  rule_contexts    = var.cbr_rules[count.index].rule_contexts
  resources = [{
    attributes = [
      {
        name     = "accountId"
        value    = var.cbr_rules[count.index].account_id
        operator = "stringEquals"
      },
      {
        name     = "serviceInstance"
        value    = ibm_resource_instance.en_instance.guid
        operator = "stringEquals"
      },
      {
        name     = "serviceName"
        value    = "event-notifications"
        operator = "stringEquals"
      }
    ]
  }]
}

resource "ibm_resource_key" "service_credentials" {
  for_each             = var.service_credential_names
  name                 = each.key
  role                 = each.value
  resource_instance_id = ibm_resource_instance.en_instance.id
}

locals {
  service_credentials_json = length(var.service_credential_names) > 0 ? {
    for service_credential in ibm_resource_key.service_credentials :
    service_credential["name"] => service_credential["credentials_json"]
  } : null

  service_credentials_object = length(var.service_credential_names) > 0 ? {
    credentials = {
      for service_credential in ibm_resource_key.service_credentials :
      service_credential["name"] => service_credential["credentials"]
    }
  } : null
}
