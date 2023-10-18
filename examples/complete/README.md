# Complete example with BYOK encryption and CBR rules

<!-- There is a pre-commit hook that will take the title of each example add include it in the repos main README.md  -->
<!-- Add text below should describe exactly what resources are provisioned / configured by the example  -->



An end-to-end example that does the following:

- Create a new resource group if one is not passed in.
- Create Key Protect instance with root key.
- Create a new Event Notification instance with BYOK encryption.
- Create a Virtual Private Cloud (VPC).
- Create Context Based Restriction (CBR) to only allow Event Notification to be accessible from the VPC.
