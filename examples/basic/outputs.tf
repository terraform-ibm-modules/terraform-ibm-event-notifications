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
