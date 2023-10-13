###########################################################
# This file creates an event notificaiton resource instance
###########################################################


resource "ibm_resource_instance" "en_instance" {
  plan              = var.plan
  location          = var.region
  name              = var.name
  resource_group_id = var.resource_group_id
  tags              = var.resource_tags
  service           = "event-notifications"
}
