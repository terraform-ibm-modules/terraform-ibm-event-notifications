##############################################################################
# Outputs
##############################################################################

output "event_notification_instance_name" {
  description = "Event Notification name"
  value       = var.existing_en_instance_crn == null ? module.event_notifications[0].event_notification_instance_name : data.ibm_resource_instance.existing_en[0].name
}

output "crn" {
  description = "Event Notification crn"
  value       = var.existing_en_instance_crn == null ? module.event_notifications[0].crn : var.existing_en_instance_crn
}

output "guid" {
  description = "Event Notification guid"
  value       = var.existing_en_instance_crn == null ? module.event_notifications[0].guid : local.existing_en_guid
}

output "service_credentials_json" {
  description = "Service credentials json map"
  value       = var.existing_en_instance_crn == null ? module.event_notifications[0].service_credentials_json : null
  sensitive   = true
}

output "service_credentials_object" {
  description = "Service credentials object"
  value       = var.existing_en_instance_crn == null ? module.event_notifications[0].service_credentials_object : null
  sensitive   = true
}

output "service_credential_secrets" {
  description = "Service credential secrets"
  value       = module.secrets_manager_service_credentials.secrets
}

output "service_credential_secret_groups" {
  description = "Service credential secret groups"
  value       = module.secrets_manager_service_credentials.secret_groups
}
