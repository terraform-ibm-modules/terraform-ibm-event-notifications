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

# The output `crn_list_object` is needed to map EN as a dependency in Cloud Logs DA, for more information refer this - https://github.ibm.com/GoldenEye/issues/issues/14014
output "crn_list_object" {
  description = "A list of objects containing the CRN of the Event Notifications instance"
  value       = [{ crn = module.event_notifications.crn }]
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

output "en_private_endpoint" {
  description = "Event Notifications instance private endpoint URL"
  value       = module.event_notifications.en_private_endpoint
}
