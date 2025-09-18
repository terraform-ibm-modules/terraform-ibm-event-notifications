# Advanced example with BYOK encryption and CBR rules

An end-to-end example that creates the following infrastructure:

- A resource group, if one is not passed in.
- A Key Protect instance with a root key.
- An Event Notifications instance with bring-your-own-key encryption.
- Service credentials for the Event Notifications instance.
- An IBM Cloud Object Storage service instance and bucket to collect events that fail delivery.
- An Event Notifications webhook destination, topic and subscription.
