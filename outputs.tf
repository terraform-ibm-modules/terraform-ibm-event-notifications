##############################################################################
# Outputs
##############################################################################

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

output "datablock" {
  value       = data.ibm_resource_instance.en_ins.guid
  description = "datablock"
}

output "instance_name" {
  value       = var.name
  description = "instance_name"
}

output "inte_id" {
  value       = data.ibm_en_integrations.en_integrations.integrations
  description = "Integration ID"
}
