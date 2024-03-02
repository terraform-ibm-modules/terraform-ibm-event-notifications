# Event Notifications solution

This solution supports the following:
- Creating a new resource group, or taking in an existing one.
- Provisioning and configuring an Event Notifications instance.

**NB:** This solution is not intended to be called by one or more other modules since it contains a provider configurations, meaning it is not compatible with the `for_each`, `count`, and `depends_on` arguments. For more information see [Providers Within Modules](https://developer.hashicorp.com/terraform/language/modules/develop/providers)
