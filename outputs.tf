##############################################################################
# Outputs
##############################################################################

output "event_notification_instance_name" {
  description = "The name of the Event Notifications instance."
  value       = ibm_resource_instance.en_instance.name
}

output "crn" {
  description = "The Event Notifications instance CRN."
  value       = ibm_resource_instance.en_instance.crn
}

output "account_id" {
  description = "The Event Notifications account ID."
  value       = local.account_id
}

output "guid" {
  description = "The globally unique identifier of the Event Notifications instance."
  value       = ibm_resource_instance.en_instance.guid
}

output "service_credentials_json" {
  description = "The service credentials JSON map."
  value       = local.service_credentials_json
  sensitive   = true
}

output "service_credentials_object" {
  description = "The service credentials object."
  value       = local.service_credentials_object
  sensitive   = true
}

output "en_private_endpoint" {
  description = "Instance private endpoint URL"
  value       = local.en_private_endpoint
}

output "en_public_endpoint" {
  description = "Instance public endpoint URL"
  value       = local.en_public_endpoint
}
