# Financial Services Cloud Profile

This is a profile for Event Notifications that meets Financial Services Cloud requirements.
It has been scanned by [IBM Code Risk Analyzer (CRA)](https://cloud.ibm.com/docs/code-risk-analyzer-cli-plugin?topic=code-risk-analyzer-cli-plugin-cra-cli-plugin#terraform-command) and meets all applicable goals.

### Usage

```hcl
module "event_notification" {
  source                    = "terraform-ibm-modules/event-notifications//ibm/modules/fscloud"
  version                   = "X.X.X" # Replace "X.X.X" with a release version to lock into a specific release
  resource_group_id         = "a8cff104f1764e98aac9ab879198230a" # pragma: allowlist secret
  name                      = "event-notification-fs"
  existing_kms_instance_crn = "crn:v1:bluemix:public:hs-crypto:us-south:a/abac0df06b644a9cabc6e44f55b3880e:e6dce284-e80f-46e1-a3c1-830f7adff7a9::"
  root_key_id               = "76170fae-4e0c-48c3-8ebe-326059ebb533"
  kms_endpoint_url          = "https://api.private.us-south.hs-crypto.cloud.ibm.com:8992"
  tags                      = ["dev", "qa"]

  # Map of name, role for service credentials that you want to create for the event notification
  service_credential_names  = {
    "en_manager" : "Manager",
    "en_writer" : "Writer",
    "en_reader" : "Reader",
    "en_channel_editor" : "Channel Editor",
    "en_device_manager" : "Device Manager",
    "en_event_source_manager" : "Event Source Manager",
    "en_event_notifications_publisher" : "Event Notification Publisher",
    "en_status_reporter" : "Status Reporter",
    "en_email_sender" : "Email Sender",
    "en_custom_email_status_reporter" : "Custom Email Status Reporter",
  }
  region                    = "us-south"

  # COS Related
  cos_bucket_name         = "fs_cos_bucket"
  cos_instance_id         = "dhd2-2bdjd-2bdjd-asgd3"
  skip_en_cos_auth_policy = false
  cos_endpoint            = "https://s3.private.us-south.cloud-object-storage.appdomain.cloud"

  cbr_rules = [
    {
      description      = "Event notification access only from vpc"
      enforcement_mode = "enabled"
      account_id       = "defc0df06b644a9cabc6e44f55b3880s"
      rule_contexts = [{
        attributes = [
          {
            "name" : "endpointType",
            "value" : "private"
          },
          {
            name  = "networkZoneId"
            value = "93a51a1debe2674193217209601dde6f" # pragma: allowlist secret
        }]
      }]
    }
  ]
}
```

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
### Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_ibm"></a> [ibm](#requirement\_ibm) | >= 1.65.0, <2.0.0 |

### Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_event_notification"></a> [event\_notification](#module\_event\_notification) | ../../ | n/a |

### Resources

No resources.

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cbr_rules"></a> [cbr\_rules](#input\_cbr\_rules) | The list of context-based restrictions rules to create. | <pre>list(object({<br/>    description = string<br/>    account_id  = string<br/>    rule_contexts = list(object({<br/>      attributes = optional(list(object({<br/>        name  = string<br/>        value = string<br/>    }))) }))<br/>    enforcement_mode = string<br/>  }))</pre> | `[]` | no |
| <a name="input_cos_bucket_name"></a> [cos\_bucket\_name](#input\_cos\_bucket\_name) | The name of an existing Object Storage bucket to use for the storage of failed delivery events. | `string` | `null` | no |
| <a name="input_cos_endpoint"></a> [cos\_endpoint](#input\_cos\_endpoint) | The endpoint URL for your bucket region. Required if `cos_integration_enabled` is set to `true`. [Learn more](https://cloud.ibm.com/docs/cloud-object-storage?topic=cloud-object-storage-endpoints). | `string` | `null` | no |
| <a name="input_cos_instance_id"></a> [cos\_instance\_id](#input\_cos\_instance\_id) | The ID of the IBM Cloud Object Storage instance in which the bucket that is defined in the `cos_bucket_name` variable exists. Required if `cos_integration_enabled` is set to true. | `string` | `null` | no |
| <a name="input_cos_integration_enabled"></a> [cos\_integration\_enabled](#input\_cos\_integration\_enabled) | Whether to connect an Object Storage service instance to your Event Notifications instance to collect events that failed delivery. If set to `false`, no failed events are captured. | `bool` | `true` | no |
| <a name="input_existing_kms_instance_crn"></a> [existing\_kms\_instance\_crn](#input\_existing\_kms\_instance\_crn) | The CRN of the Hyper Protect Crypto Services or Key Protect instance. To ensure compliance with IBM Cloud Framework for Financial Services standards, it is required to use Hyper Protect Crypto Services only. | `string` | n/a | yes |
| <a name="input_kms_endpoint_url"></a> [kms\_endpoint\_url](#input\_kms\_endpoint\_url) | The KMS endpoint URL to use when you configure KMS encryption. | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | The name of the Event Notifications instance that is created by this module. | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | The IBM Cloud region where the Event Notifications resource is created. Possible values: `us-south` (Dallas), `eu-gb` (London), `eu-de` (Frankfurt), `au-syd` (Sydney), `eu-es` (Madrid) | `string` | `"us-south"` | no |
| <a name="input_resource_group_id"></a> [resource\_group\_id](#input\_resource\_group\_id) | The resource group ID to use when creating the Event Notifications instance. | `string` | n/a | yes |
| <a name="input_root_key_id"></a> [root\_key\_id](#input\_root\_key\_id) | The key ID of a root key, existing in the KMS instance passed in `var.existing_kms_instance_crn`, which will be used to encrypt the data encryption keys which are then used to encrypt the data. | `string` | n/a | yes |
| <a name="input_service_credential_names"></a> [service\_credential\_names](#input\_service\_credential\_names) | The mapping of names and roles for service credentials that you want to create for the Event Notifications instance. | `map(string)` | `{}` | no |
| <a name="input_skip_en_cos_auth_policy"></a> [skip\_en\_cos\_auth\_policy](#input\_skip\_en\_cos\_auth\_policy) | Whether an IAM authorization policy is created for your Event Notifications instance to interact with your Object Storage bucket. Set to `true` to use an existing policy. Ignored if `cos_integration_enabled` is set to `false`. | `bool` | `false` | no |
| <a name="input_skip_en_kms_auth_policy"></a> [skip\_en\_kms\_auth\_policy](#input\_skip\_en\_kms\_auth\_policy) | Set to `true` to skip the creation of an IAM authorization policy that permits all Event Notifications instances in the resource group reader access to the instance specified in the `existing_kms_instance_guid` variable. | `bool` | `false` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | The list of tags to add to the Event Notifications instance. | `list(string)` | `[]` | no |

### Outputs

| Name | Description |
|------|-------------|
| <a name="output_crn"></a> [crn](#output\_crn) | Event notification instance crn |
| <a name="output_event_notification_instance_name"></a> [event\_notification\_instance\_name](#output\_event\_notification\_instance\_name) | Event Notification name |
| <a name="output_guid"></a> [guid](#output\_guid) | Event Notification guid |
| <a name="output_service_credentials_json"></a> [service\_credentials\_json](#output\_service\_credentials\_json) | Service credentials json map |
| <a name="output_service_credentials_object"></a> [service\_credentials\_object](#output\_service\_credentials\_object) | Service credentials json object |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
