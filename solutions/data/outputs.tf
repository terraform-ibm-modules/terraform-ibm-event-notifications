##############################################################################
# Outputs
##############################################################################

##############################################################################
# Outputs include in this should reflect exactly the same outputs, of the
# same type and same sensitivity as the standard solution ../standard
##############################################################################
output "event_notification_instance_name" {
  description = "Event Notification name"
  value       = data.ibm_resource_instance.existing_instance.name
}

output "crn" {
  description = "Event Notification crn"
  value       = data.ibm_resource_instance.existing_instance.crn
}

output "guid" {
  description = "Event Notification guid"
  value       = data.ibm_resource_instance.existing_instance.guid
}

output "service_credentials_json" {
  description = "Service credentials json map"
  value       = null
  sensitive   = true
}

output "service_credentials_object" {
  description = "Service credentials object"
  value       = null
  sensitive   = true
}
