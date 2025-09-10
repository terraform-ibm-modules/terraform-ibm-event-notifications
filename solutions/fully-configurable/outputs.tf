##############################################################################
# Outputs
##############################################################################

output "event_notification_instance_name" {
  description = "Event Notification name"
  value       = var.existing_event_notifications_instance_crn == null ? module.event_notifications[0].event_notification_instance_name : data.ibm_resource_instance.existing_en_instance[0].name
}

# The output `crn_list_object` is needed to map EN as a dependency in Cloud Logs DA, for more information refer this - https://github.ibm.com/GoldenEye/issues/issues/14014
output "crn_list_object" {
  description = "A list of objects containing the CRN of the Event Notifications instance"
  value       = local.use_existing_en_instance ? [{ crn = var.existing_event_notifications_instance_crn }] : [{ crn = module.event_notifications[0].crn }]
}

output "crn" {
  description = "Event Notification crn"
  value       = local.use_existing_en_instance ? var.existing_event_notifications_instance_crn : module.event_notifications[0].crn
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

output "event_notifications_private_endpoint" {
  description = "Event Notifications instance private endpoint URL"
  value       = local.use_existing_en_instance ? null : module.event_notifications[0].event_notifications_private_endpoint
}

output "event_notifications_public_endpoint" {
  description = "Event Notifications instance public endpoint URL"
  value       = local.use_existing_en_instance ? null : module.event_notifications[0].event_notifications_public_endpoint
}
