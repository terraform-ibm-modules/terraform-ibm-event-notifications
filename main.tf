###########################################################
# This file creates an event notificaiton resource instance
###########################################################
locals {
  # tflint-ignore: terraform_unused_declarations
  validate_kms_plan = var.kms_encryption_enabled && var.plan != "standard" ? tobool("kms encryption is only supported for standard plan") : true
  # tflint-ignore: terraform_unused_declarations
  validate_kms_values = !var.kms_encryption_enabled && var.kms_key_crn != null ? tobool("When passing values for var.kms_key_crn, you must set var.kms_encryption_enabled to true. Otherwise unset them to use default encryption") : true
  # tflint-ignore: terraform_unused_declarations
  validate_kms_vars = var.kms_encryption_enabled && var.kms_key_crn == null ? tobool("When setting var.kms_encryption_enabled to true, a value must be passed for var.kms_key_crn and/or var.backup_encryption_key_crn") : true
  # tflint-ignore: terraform_unused_declarations
  validate_auth_policy = var.kms_encryption_enabled && var.skip_iam_authorization_policy == false && var.existing_kms_instance_guid == null ? tobool("When var.skip_iam_authorization_policy is set to false, and var.kms_encryption_enabled to true, a value must be passed for var.existing_kms_instance_guid in order to create the auth policy.") : true

  # Determine what KMS service is being used for encryption
  kms_service = var.kms_key_crn != null ? (
    can(regex(".*kms.*", var.kms_key_crn)) ? "kms" : (
      can(regex(".*hs-crypto.*", var.kms_key_crn)) ? "hs-crypto" : null
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
    kms_key_crn       = var.kms_key_crn
  }
}

##############################################################################
# IAM Authorization Policy
##############################################################################

# Create IAM Authorization Policies to allow event notification to access kms for the encryption key
resource "ibm_iam_authorization_policy" "kms_policy" {
  count                       = var.kms_encryption_enabled == false || var.skip_iam_authorization_policy ? 0 : 1
  source_service_name         = "event-notifications"
  source_resource_group_id    = var.resource_group_id
  target_service_name         = local.kms_service
  target_resource_instance_id = var.existing_kms_instance_guid
  roles                       = ["Reader"]
  description                 = "Allow all Event Notification instances in the resource group ${var.resource_group_id} to read from the ${local.kms_service} instance GUID ${var.existing_kms_instance_guid}"
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
