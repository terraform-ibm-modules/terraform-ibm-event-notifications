# Cloud automation for Event Notifications (Fully configurable)

## Prerequisites
- An existing resource group

When `existing_en_instance_crn` is not passed, this solution configures the following infrastructure:

- optionally a KMS key ring
- optionally a KMS key for IBM Event Notifications encryption
- optionally a KMS key for IBM Cloud Object Storage encryption
- optionally an IBM Cloud Object Storage bucket to collect events that fail delivery
- an IBM Event Notifications instance

When `existing_en_instance_crn` is passed, this solution ignores ALL other inputs and sets the outputs based on the CRN.


:exclamation: **Important:** This solution is not intended to be called by one or more other modules because it contains a provider configuration and is not compatible with the `for_each`, `count`, and `depends_on` arguments. For more information, see [Providers Within Modules](https://developer.hashicorp.com/terraform/language/modules/develop/providers).

![event-notifications-deployable-architecture](../../reference-architecture/en.svg)

<!-- Below content is automatically populated via pre-commit hook -->
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
### Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0 |
| <a name="requirement_ibm"></a> [ibm](#requirement\_ibm) | 1.80.4 |
| <a name="requirement_time"></a> [time](#requirement\_time) | 0.13.1 |

### Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_cos_buckets"></a> [cos\_buckets](#module\_cos\_buckets) | terraform-ibm-modules/cos/ibm//modules/buckets | 10.1.12 |
| <a name="module_cos_kms_key_crn_parser"></a> [cos\_kms\_key\_crn\_parser](#module\_cos\_kms\_key\_crn\_parser) | terraform-ibm-modules/common-utilities/ibm//modules/crn-parser | 1.2.0 |
| <a name="module_event_notifications"></a> [event\_notifications](#module\_event\_notifications) | ../.. | n/a |
| <a name="module_existing_cos_crn_parser"></a> [existing\_cos\_crn\_parser](#module\_existing\_cos\_crn\_parser) | terraform-ibm-modules/common-utilities/ibm//modules/crn-parser | 1.2.0 |
| <a name="module_existing_en_crn_parser"></a> [existing\_en\_crn\_parser](#module\_existing\_en\_crn\_parser) | terraform-ibm-modules/common-utilities/ibm//modules/crn-parser | 1.2.0 |
| <a name="module_existing_kms_crn_parser"></a> [existing\_kms\_crn\_parser](#module\_existing\_kms\_crn\_parser) | terraform-ibm-modules/common-utilities/ibm//modules/crn-parser | 1.2.0 |
| <a name="module_existing_kms_key_crn_parser"></a> [existing\_kms\_key\_crn\_parser](#module\_existing\_kms\_key\_crn\_parser) | terraform-ibm-modules/common-utilities/ibm//modules/crn-parser | 1.2.0 |
| <a name="module_existing_sm_crn_parser"></a> [existing\_sm\_crn\_parser](#module\_existing\_sm\_crn\_parser) | terraform-ibm-modules/common-utilities/ibm//modules/crn-parser | 1.2.0 |
| <a name="module_kms"></a> [kms](#module\_kms) | terraform-ibm-modules/kms-all-inclusive/ibm | 5.1.13 |
| <a name="module_resource_group"></a> [resource\_group](#module\_resource\_group) | terraform-ibm-modules/resource-group/ibm | 1.2.1 |
| <a name="module_secrets_manager_service_credentials"></a> [secrets\_manager\_service\_credentials](#module\_secrets\_manager\_service\_credentials) | terraform-ibm-modules/secrets-manager/ibm//modules/secrets | 2.6.14 |

### Resources

| Name | Type |
|------|------|
| [ibm_iam_authorization_policy.cos_kms_policy](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.80.4/docs/resources/iam_authorization_policy) | resource |
| [ibm_iam_authorization_policy.en_kms_policy](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.80.4/docs/resources/iam_authorization_policy) | resource |
| [ibm_iam_authorization_policy.secrets_manager_key_manager](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.80.4/docs/resources/iam_authorization_policy) | resource |
| [time_sleep.wait_for_en_authorization_policy](https://registry.terraform.io/providers/hashicorp/time/0.13.1/docs/resources/sleep) | resource |
| [ibm_resource_instance.existing_en_instance](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.80.4/docs/data-sources/resource_instance) | data source |

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_add_bucket_name_suffix"></a> [add\_bucket\_name\_suffix](#input\_add\_bucket\_name\_suffix) | Whether to add a randomly generated 4-character suffix to the newly provisioned Object Storage bucket name. Set to `false` if you want full control over bucket naming by using the `cos_bucket_name` variable. | `bool` | `true` | no |
| <a name="input_cbr_rules"></a> [cbr\_rules](#input\_cbr\_rules) | The list of context-based restrictions rules to create.  [Learn more](https://github.com/terraform-ibm-modules/terraform-ibm-event-notifications/tree/main/solutions/fully-configurable/DA-cbr_rules.md) | <pre>list(object({<br/>    description = string<br/>    account_id  = string<br/>    rule_contexts = list(object({<br/>      attributes = optional(list(object({<br/>        name  = string<br/>        value = string<br/>    }))) }))<br/>    enforcement_mode = string<br/>    operations = optional(list(object({<br/>      api_types = list(object({<br/>        api_type_id = string<br/>      }))<br/>    })))<br/>  }))</pre> | `[]` | no |
| <a name="input_cos_bucket_access_tags"></a> [cos\_bucket\_access\_tags](#input\_cos\_bucket\_access\_tags) | A list of access tags to apply to the Cloud Object Storage bucket created by the module. For more information, see https://cloud.ibm.com/docs/account?topic=account-access-tags-tutorial. | `list(string)` | `[]` | no |
| <a name="input_cos_bucket_class"></a> [cos\_bucket\_class](#input\_cos\_bucket\_class) | The storage class of the newly provisioned Cloud Object Storage bucket. Specify one of the following values for the storage class: `standard`, `vault`, `cold`, `smart` (default), or `onerate_active`. | `string` | `"standard"` | no |
| <a name="input_cos_bucket_name"></a> [cos\_bucket\_name](#input\_cos\_bucket\_name) | The name to use when creating the Object Storage bucket for the storage of failed delivery events. Bucket names are globally unique. If `add_bucket_name_suffix` is set to `true`, a random 4 character string is added to this name to help ensure that the bucket name is unique. If a `prefix` input variable is specified, it is added to this name in the `<prefix>-value` format. | `string` | `"base-event-notifications-bucket"` | no |
| <a name="input_cos_bucket_region"></a> [cos\_bucket\_region](#input\_cos\_bucket\_region) | The COS bucket region. If `cos_bucket_region` is set to null, then `region` will be used. | `string` | `null` | no |
| <a name="input_cos_key_name"></a> [cos\_key\_name](#input\_cos\_key\_name) | The name of the key which will be created for the Event Notifications. Not used if supplying an existing key. Only use if 'enable\_collecting\_failed\_events' is true. If a `prefix` input variable is specified, it is added to this name in the `<prefix>-value` format. | `string` | `"event-notifications-cos-key"` | no |
| <a name="input_enable_collecting_failed_events"></a> [enable\_collecting\_failed\_events](#input\_enable\_collecting\_failed\_events) | Set to true to enable Cloud Object Storage integration. If true a Cloud Object Storage instance to store failed events in should also be passed using variable `existing_cos_instance_crn`. For more info see https://cloud.ibm.com/docs/event-notifications?topic=event-notifications-en-cfe-integrations. | `bool` | `false` | no |
| <a name="input_event_notifications_access_tags"></a> [event\_notifications\_access\_tags](#input\_event\_notifications\_access\_tags) | A list of access tags to apply to the Event Notifications instance created by the module. For more information, see https://cloud.ibm.com/docs/account?topic=account-access-tags-tutorial. | `list(string)` | `[]` | no |
| <a name="input_event_notifications_instance_name"></a> [event\_notifications\_instance\_name](#input\_event\_notifications\_instance\_name) | The name of the Event Notifications instance that is created by this solution. If a `prefix` input variable is specified, it is added to this name in the `<prefix>-value` format. | `string` | `"event-notifications"` | no |
| <a name="input_event_notifications_key_name"></a> [event\_notifications\_key\_name](#input\_event\_notifications\_key\_name) | The name for the key that will be created for the Event Notifications instance. Not used if an existing key is specified. If a `prefix` input variable is specified, it is added to this name in the `<prefix>-value` format. | `string` | `"event-notifications-key"` | no |
| <a name="input_event_notifications_key_ring_name"></a> [event\_notifications\_key\_ring\_name](#input\_event\_notifications\_key\_ring\_name) | The name of the key ring which will be created for the Event Notifications instance. Not used if supplying an existing key. If a `prefix` input variable is specified, it is added to this name in the `<prefix>-value` format. | `string` | `"event-notifications-key-ring"` | no |
| <a name="input_event_notifications_resource_tags"></a> [event\_notifications\_resource\_tags](#input\_event\_notifications\_resource\_tags) | The list of tags to add to the Event Notifications instance. | `list(string)` | `[]` | no |
| <a name="input_existing_cos_instance_crn"></a> [existing\_cos\_instance\_crn](#input\_existing\_cos\_instance\_crn) | The CRN of an IBM Cloud Object Storage instance. If not supplied, Cloud Object Storage will not be configured. To use, 'enable\_collecting\_failed\_events' must be set to true. | `string` | `null` | no |
| <a name="input_existing_event_notifications_instance_crn"></a> [existing\_event\_notifications\_instance\_crn](#input\_existing\_event\_notifications\_instance\_crn) | The CRN of existing Event Notifications instance. If not supplied, a new instance is created. | `string` | `null` | no |
| <a name="input_existing_kms_instance_crn"></a> [existing\_kms\_instance\_crn](#input\_existing\_kms\_instance\_crn) | The CRN of the KMS instance (Hyper Protect Crypto Services or Key Protect instance). If the KMS instance is in different account you must also provide a value for `ibmcloud_kms_api_key`. To use an existing kms instance you must also provide a value for 'kms\_endpoint\_url' and 'existing\_kms\_root\_key\_crn' should be null. A value should not be passed passing existing EN instance using the `existing_event_notifications_instance_crn` input. | `string` | `null` | no |
| <a name="input_existing_kms_root_key_crn"></a> [existing\_kms\_root\_key\_crn](#input\_existing\_kms\_root\_key\_crn) | The key CRN of a root key which will be used to encrypt the data. To use an existing key you must also provide a value for 'kms\_endpoint\_url' and 'existing\_kms\_instance\_crn' should be null. If no value passed, a new key will be created in the instance provided in the `existing_kms_instance_crn` input. | `string` | `null` | no |
| <a name="input_existing_monitoring_crn"></a> [existing\_monitoring\_crn](#input\_existing\_monitoring\_crn) | The CRN of an IBM Cloud Monitoring instance used to monitor the IBM Cloud Object Storage bucket that is used for storing failed events. Only applicable if failed events are enabled using the `enable_collecting_failed_events` input. If no value passed, metrics are sent to the instance associated to the container's location unless otherwise specified in the Metrics Router service configuration. | `string` | `null` | no |
| <a name="input_existing_resource_group_name"></a> [existing\_resource\_group\_name](#input\_existing\_resource\_group\_name) | The name of an existing resource group to provision the resources. | `string` | `"Default"` | no |
| <a name="input_existing_secrets_manager_endpoint_type"></a> [existing\_secrets\_manager\_endpoint\_type](#input\_existing\_secrets\_manager\_endpoint\_type) | The endpoint type to use if `existing_secrets_manager_instance_crn` is specified. Possible values: public, private. | `string` | `"private"` | no |
| <a name="input_existing_secrets_manager_instance_crn"></a> [existing\_secrets\_manager\_instance\_crn](#input\_existing\_secrets\_manager\_instance\_crn) | The CRN of existing secrets manager to use to create service credential secrets for Event Notification instance. | `string` | `null` | no |
| <a name="input_ibmcloud_api_key"></a> [ibmcloud\_api\_key](#input\_ibmcloud\_api\_key) | The API key to use for IBM Cloud. | `string` | n/a | yes |
| <a name="input_ibmcloud_kms_api_key"></a> [ibmcloud\_kms\_api\_key](#input\_ibmcloud\_kms\_api\_key) | The IBM Cloud API key that can create a root key and key ring in the key management service (KMS) instance. If not specified, the 'ibmcloud\_api\_key' variable is used. Specify this key if the instance in `existing_kms_instance_crn` is in an account that's different from the Event Notifications instance. Leave this input empty if the same account owns both instances. | `string` | `null` | no |
| <a name="input_kms_encryption_enabled"></a> [kms\_encryption\_enabled](#input\_kms\_encryption\_enabled) | Set to true to enable KMS encryption on Event Notifications instance and Cloud Object Storage bucket. When set to true 'kms\_endpoint\_url' and one of 'existing\_kms\_instance\_crn' or 'existing\_kms\_root\_key\_crn' must be set. | `bool` | `false` | no |
| <a name="input_kms_endpoint_type"></a> [kms\_endpoint\_type](#input\_kms\_endpoint\_type) | The type of the endpoint that is used for communicating with the KMS instance. Possible values: `public` or `private` (default). Only used if not supplying an existing root key. | `string` | `"private"` | no |
| <a name="input_kms_endpoint_url"></a> [kms\_endpoint\_url](#input\_kms\_endpoint\_url) | The KMS endpoint URL to use when you configure KMS encryption. When set to true, a value must be passed for either `existing_kms_root_key_crn` or `existing_kms_instance_crn` (to create a new key). The Hyper Protect Crypto Services endpoint URL format is `https://api.private.<REGION>.hs-crypto.cloud.ibm.com:<port>` and the Key Protect endpoint URL format is `https://<REGION>.kms.cloud.ibm.com`. Not required if passing an existing instance using the `existing_event_notifications_instance_crn` input. | `string` | `null` | no |
| <a name="input_management_endpoint_type_for_bucket"></a> [management\_endpoint\_type\_for\_bucket](#input\_management\_endpoint\_type\_for\_bucket) | The type of endpoint for the IBM Terraform provider to use to manage Object Storage buckets. Available values: `public` or `direct`. | `string` | `"direct"` | no |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | Prefix to add to all resources created by this solution. To not use any prefix value, you can set this value to `null` or an empty string. | `string` | n/a | yes |
| <a name="input_provider_visibility"></a> [provider\_visibility](#input\_provider\_visibility) | Set the visibility value for the IBM terraform provider. Supported values are `public`, `private`, `public-and-private`. [Learn more](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/guides/custom-service-endpoints). | `string` | `"private"` | no |
| <a name="input_region"></a> [region](#input\_region) | The region in which the Event Notifications resources are provisioned. | `string` | `"us-south"` | no |
| <a name="input_service_credential_names"></a> [service\_credential\_names](#input\_service\_credential\_names) | The mapping of names and roles for service credentials that you want to create for the Event Notifications instance. [Learn more](https://github.com/terraform-ibm-modules/terraform-ibm-event-notifications/tree/main/solutions/fully-configurable/DA-types.md#service-credential-secrets | `map(string)` | `{}` | no |
| <a name="input_service_credential_secrets"></a> [service\_credential\_secrets](#input\_service\_credential\_secrets) | Service credential secrets configuration for Event Notification. [Learn more](https://github.com/terraform-ibm-modules/terraform-ibm-event-notifications/tree/main/solutions/fully-configurable/DA-types.md#service-credential-secrets). | <pre>list(object({<br/>    secret_group_name        = string<br/>    secret_group_description = optional(string)<br/>    existing_secret_group    = optional(bool)<br/>    service_credentials = list(object({<br/>      secret_name                                 = string<br/>      service_credentials_source_service_role_crn = string<br/>      secret_labels                               = optional(list(string))<br/>      secret_auto_rotation                        = optional(bool)<br/>      secret_auto_rotation_unit                   = optional(string)<br/>      secret_auto_rotation_interval               = optional(number)<br/>      service_credentials_ttl                     = optional(string)<br/>      service_credential_secret_description       = optional(string)<br/><br/>    }))<br/>  }))</pre> | `[]` | no |
| <a name="input_service_endpoints"></a> [service\_endpoints](#input\_service\_endpoints) | Specify whether you want to enable public, private, or both public and private service endpoints. Possible values: `public`, `private`, `public-and-private` | `string` | `"private"` | no |
| <a name="input_service_plan"></a> [service\_plan](#input\_service\_plan) | The pricing plan of the Event Notifications instance. Possible values: `Lite`, `Standard` | `string` | `"standard"` | no |
| <a name="input_skip_cos_kms_auth_policy"></a> [skip\_cos\_kms\_auth\_policy](#input\_skip\_cos\_kms\_auth\_policy) | Set to true to skip the creation of an IAM authorization policy that permits the COS instance to read the encryption key from the KMS instance. If set to false, pass in a value for the KMS instance in the `existing_key_management_service_instance_crn` variable. If a value is specified for `ibmcloud_kms_api_key`, the policy is created in the KMS account. | `bool` | `false` | no |
| <a name="input_skip_event_notifications_cos_auth_policy"></a> [skip\_event\_notifications\_cos\_auth\_policy](#input\_skip\_event\_notifications\_cos\_auth\_policy) | Set to `true` to skip the creation of an IAM authorization policy that permits the Event Notifications instance `Object Writer` and `Reader` access to the given Object Storage bucket. Set to `true` to use an existing policy. | `bool` | `false` | no |
| <a name="input_skip_event_notifications_kms_auth_policy"></a> [skip\_event\_notifications\_kms\_auth\_policy](#input\_skip\_event\_notifications\_kms\_auth\_policy) | Set to true to skip the creation of an IAM authorization policy that permits the Event Notifications instance to read the encryption key from the KMS instance. If a value is specified for `ibmcloud_kms_api_key`, the policy is created in the KMS account. | `bool` | `false` | no |
| <a name="input_skip_event_notifications_secrets_manager_auth_policy"></a> [skip\_event\_notifications\_secrets\_manager\_auth\_policy](#input\_skip\_event\_notifications\_secrets\_manager\_auth\_policy) | Whether an IAM authorization policy is created for Secrets Manager instance to create a service credential secrets for Event Notification.If set to false, the Secrets Manager instance passed by the user is granted the Key Manager access to the Event Notifications instance created by the Deployable Architecture. Set to `true` to use an existing policy. The value of this is ignored if any value for 'existing\_secrets\_manager\_instance\_crn' is not passed. | `bool` | `false` | no |

### Outputs

| Name | Description |
|------|-------------|
| <a name="output_crn"></a> [crn](#output\_crn) | Event Notification crn |
| <a name="output_crn_list_object"></a> [crn\_list\_object](#output\_crn\_list\_object) | A list of objects containing the CRN of the Event Notifications instance |
| <a name="output_event_notification_instance_name"></a> [event\_notification\_instance\_name](#output\_event\_notification\_instance\_name) | Event Notification name |
| <a name="output_guid"></a> [guid](#output\_guid) | Event Notification guid |
| <a name="output_service_credential_secret_groups"></a> [service\_credential\_secret\_groups](#output\_service\_credential\_secret\_groups) | Service credential secret groups |
| <a name="output_service_credential_secrets"></a> [service\_credential\_secrets](#output\_service\_credential\_secrets) | Service credential secrets |
| <a name="output_service_credentials_json"></a> [service\_credentials\_json](#output\_service\_credentials\_json) | Service credentials json map |
| <a name="output_service_credentials_object"></a> [service\_credentials\_object](#output\_service\_credentials\_object) | Service credentials object |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
