##############################################################################
# Outputs
##############################################################################

output "event_notification_instance_name" {
  description = "Event Notification name"
  value       = ibm_resource_instance.en_instance.name
}
output "crn" {
  description = "Event Notification crn"
  value       = ibm_resource_instance.en_instance.crn
}

output "guid" {
  description = "Event Notification guid"
  value       = ibm_resource_instance.en_instance.guid
}

output "service_credentials_json" {
  description = "Service credentials json map"
  value       = local.service_credentials_json
  sensitive   = true
}

output "service_credentials_object" {
  description = "Service credentials object"
  value       = local.service_credentials_object
  sensitive   = true
}
