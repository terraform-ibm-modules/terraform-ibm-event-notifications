# Event Notifications solution

When `existing_en_instance_crn` is not passed, this solution configures the following infrastructure:

- a resource group, if one is not passed in.
- optionally a KMS key ring and key for IBM Event Notifications encryption
- optionally a KMS key ring and key for IBM Cloud Object Storage encryption
- optionally an IBM Cloud Object Storage instance
- optionally an IBM Cloud Object Storage bucket to collect events that fail delivery
- an IBM Event Notifications instance

When `existing_en_instance_crn` is passed, this solution ignores ALL other inputs and sets the outputs based on the CRN.

- required inputs MUST still be set, but will be ignored.

:exclamation: **Important:** This solution is not intended to be called by one or more other modules because it contains a provider configuration and is not compatible with the `for_each`, `count`, and `depends_on` arguments. For more information, see [Providers Within Modules](https://developer.hashicorp.com/terraform/language/modules/develop/providers).
