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
