##############################################################################
# Outputs
##############################################################################

output "resource_group_name" {
  description = "Resource group name"
  value       = module.resource_group.resource_group_name
}

output "resource_group_id" {
  description = "Resource group ID"
  value       = module.resource_group.resource_group_id
}

output "crn" {
  description = "Event notification instance crn"
  value       = module.event_notification.crn
}

output "guid" {
  description = "Event Notification guid"
  value       = module.event_notification.guid
}

output "service_credentials_json" {
  description = "Service credentials json map"
  value       = module.event_notification.service_credentials_json
  sensitive   = true
}

output "service_credentials_object" {
  description = "Service credentials json object"
  value       = module.event_notification.service_credentials_object
  sensitive   = true
}

output "output_en_id" {
  value       = module.event_notification.datablock
  description = "output_en_id"
}

output "instance_name" {
  value       = module.event_notification.instance_name
  description = "instance_name"
}

output "int_id" {
  value       = module.event_notification.inte_id
  description = "Integration ID"
}
