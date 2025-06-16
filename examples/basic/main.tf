##############################################################################
# Resource group
##############################################################################

module "resource_group" {
  source  = "terraform-ibm-modules/resource-group/ibm"
  version = "1.2.1"
  # if an existing resource group is not set (null) create a new one using prefix
  resource_group_name          = var.resource_group == null ? "${var.prefix}-resource-group" : null
  existing_resource_group_name = var.resource_group
}

##############################################################################
# Events-notification-instance
##############################################################################

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
