##############################################################################
# Outputs
##############################################################################

output "event_notification_instance_name" {
  description = "Event Notification name"
  value       = local.use_existing_en_instance ? data.ibm_database.existing_en_instance[0].name : module.event_notifications[0].name
}

output "crn" {
  description = "Event Notification crn"
  value       = local.use_existing_en_instance ? var.existing_en_instance_crn : module.event_notifications[0].crn
}

output "guid" {
  description = "Event Notification guid"
  value       = local.eventnotification_guid
}

output "hostname" {
  description = "Event Notification instance hostname"
  value       = local.use_existing_en_instance ? data.ibm_database_connection.existing_connection[0].https[0].hosts[0].hostname : module.event_notifications[0].hostname
}

output "port" {
  description = "Event Notifications instance port"
  value       = local.use_existing_en_instance ? data.ibm_database_connection.existing_connection[0].https[0].hosts[0].port : module.event_notifications[0].port
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
