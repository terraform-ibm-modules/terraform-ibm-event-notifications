# Event Notifications solution

This solution that configures the following infrastructure:

- Creates a resource group, if one is not passed in.
- Provisions and configures an Event Notifications instance.
- Provisions an IBM Cloud Object Storage instance to connect to an Event Notifications instance and collect events that fail delivery.
- Configures KMS encryption by using an existing root key. Optionally creates a key ring and key in an existing instance.

:exclamation: **Important:** This solution is not intended to be called by one or more other modules because it contains a provider configuration and is not compatible with the `for_each`, `count`, and `depends_on` arguments. For more information, see [Providers Within Modules](https://developer.hashicorp.com/terraform/language/modules/develop/providers).
