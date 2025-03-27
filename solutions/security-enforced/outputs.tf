##############################################################################
# Outputs
##############################################################################

output "event_notification_instance_name" {
  description = "Event Notification name"
  value       = module.event_notifications.event_notification_instance_name
}

output "crn" {
  description = "Event Notification crn"
  value       = module.event_notifications.crn
}

output "guid" {
  description = "Event Notification guid"
  value       = module.event_notifications.guid
}

output "service_credentials_json" {
  description = "Service credentials json map"
  value       = module.event_notifications.service_credentials_json
  sensitive   = true
}

output "service_credentials_object" {
  description = "Service credentials object"
  value       = module.event_notifications.service_credentials_object
  sensitive   = true
}

output "service_credential_secrets" {
  description = "Service credential secrets"
  value       = module.event_notifications.service_credential_secrets
}

output "service_credential_secret_groups" {
  description = "Service credential secret groups"
  value       = module.event_notifications.service_credential_secret_groups
}
