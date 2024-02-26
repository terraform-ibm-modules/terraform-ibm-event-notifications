# Financial Services Cloud Profile

This is a profile for Event Notifications that meets Financial Services Cloud requirements.
It has been scanned by [IBM Code Risk Analyzer (CRA)](https://cloud.ibm.com/docs/code-risk-analyzer-cli-plugin?topic=code-risk-analyzer-cli-plugin-cra-cli-plugin#terraform-command) and meets all applicable goals.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
### Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0, <1.6.0 |
| <a name="requirement_ibm"></a> [ibm](#requirement\_ibm) | >= 1.56.1, <2.0.0 |

### Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_event_notification"></a> [event\_notification](#module\_event\_notification) | ../../ | n/a |

### Resources

No resources.

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cbr_rules"></a> [cbr\_rules](#input\_cbr\_rules) | (Optional, list) List of CBR rules to create. | <pre>list(object({<br>    description = string<br>    account_id  = string<br>    rule_contexts = list(object({<br>      attributes = optional(list(object({<br>        name  = string<br>        value = string<br>    }))) }))<br>    enforcement_mode = string<br>  }))</pre> | `[]` | no |
| <a name="input_existing_kms_instance_crn"></a> [existing\_kms\_instance\_crn](#input\_existing\_kms\_instance\_crn) | The CRN of the Hyper Protect Crypto Services or Key Protect instance. To ensure compliance with FSCloud standards, it is required to use HPCS only. | `string` | n/a | yes |
| <a name="input_kms_endpoint_url"></a> [kms\_endpoint\_url](#input\_kms\_endpoint\_url) | The KMS endpoint URL to use when configuring KMS encryption. | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | The name to give the IBM Event Notification instance created by this module. | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | IBM Cloud region where event notification will be created, supported regions are: us-south (Dallas), eu-gb (London), eu-de (Frankfurt), au-syd (Sydney), eu-es (Madrid) | `string` | `"us-south"` | no |
| <a name="input_resource_group_id"></a> [resource\_group\_id](#input\_resource\_group\_id) | ID of resource group to use when creating the event stream instance | `string` | n/a | yes |
| <a name="input_root_key_id"></a> [root\_key\_id](#input\_root\_key\_id) | The Key ID of a root key, existing in the KMS instance passed in var.existing\_kms\_instance\_crn, which will be used to encrypt the data encryption keys (DEKs) which are then used to encrypt the data. | `string` | n/a | yes |
| <a name="input_service_credential_names"></a> [service\_credential\_names](#input\_service\_credential\_names) | Map of name, role for service credentials that you want to create for the event notification | `map(string)` | `{}` | no |
| <a name="input_skip_iam_authorization_policy"></a> [skip\_iam\_authorization\_policy](#input\_skip\_iam\_authorization\_policy) | Set to true to skip the creation of an IAM authorization policy that permits all event notification instances in the provided resource group reader access to the instance specified in the existing\_kms\_instance\_guid variable. | `bool` | `false` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Optional list of tags to be added to the Event Notification instance | `list(string)` | `[]` | no |

### Outputs

| Name | Description |
|------|-------------|
| <a name="output_crn"></a> [crn](#output\_crn) | Event notification instance crn |
| <a name="output_event_notification_instance_name"></a> [event\_notification\_instance\_name](#output\_event\_notification\_instance\_name) | Event Notification name |
| <a name="output_guid"></a> [guid](#output\_guid) | Event Notification guid |
| <a name="output_service_credentials_json"></a> [service\_credentials\_json](#output\_service\_credentials\_json) | Service credentials json map |
| <a name="output_service_credentials_object"></a> [service\_credentials\_object](#output\_service\_credentials\_object) | Service credentials json object |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
