##############################################################################
# Outputs
##############################################################################

output "event_notification_instance_name" {
  description = "Event Notification name"
  value       = var.existing_en_instance_crn == null ? module.event_notifications[0].event_notification_instance_name : data.ibm_resource_instance.existing_en_instance[0].name
}

output "crn" {
  description = "Event Notification crn"
  value       = local.use_existing_en_instance ? var.existing_en_instance_crn : module.event_notifications[0].crn
}

output "guid" {
  description = "Event Notification guid"
  value       = local.eventnotification_guid
}

output "service_credentials_json" {
  description = "Service credentials json map"
  value       = local.use_existing_en_instance ? null : module.event_notifications[0].service_credentials_json
  sensitive   = true
}

output "service_credentials_object" {
  description = "Service credentials object"
  value       = local.use_existing_en_instance ? null : module.event_notifications[0].service_credentials_object
  sensitive   = true
}

output "service_credential_secrets" {
  description = "Service credential secrets"
  value       = length(local.service_credential_secrets) > 0 ? module.secrets_manager_service_credentials[0].secrets : null
}

output "service_credential_secret_groups" {
  description = "Service credential secret groups"
  value       = length(local.service_credential_secrets) > 0 ? module.secrets_manager_service_credentials[0].secret_groups : null
}
