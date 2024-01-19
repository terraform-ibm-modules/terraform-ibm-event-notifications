##############################################################################
# Outputs
##############################################################################

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
