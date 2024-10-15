########################################################################################################################
# Outputs
########################################################################################################################

output "resource_group_id" {
  description = "The id of the resource group where resources are created"
  value       = module.resource_group.resource_group_id
}

output "resource_group_name" {
  description = "The name of the resource group where resources are created"
  value       = module.resource_group.resource_group_name
}

output "event_notification_instance_name" {
  description = "Event Notification name"
  value       = module.event_notification.event_notification_instance_name
}

output "event_notification_instance_crn" {
  description = "Event notification instance crn"
  value       = module.event_notification.crn
}

output "event_notification_instance_guid" {
  description = "Event Notification guid"
  value       = module.event_notification.guid
}

output "cos_crn" {
  description = "COS CRN"
  value       = module.cos.cos_instance_crn
}

output "bucket_name" {
  description = "COS bucket name"
  value       = module.cos.bucket_name
}

output "s3_endpoint_direct_url" {
  description = "COS bucket name"
  value       = "https://${module.cos.s3_endpoint_direct}"
}
