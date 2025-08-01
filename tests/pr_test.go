// Tests in this file are run in the PR pipeline and the continuous testing pipeline
package test

import (
	"encoding/json"
	"fmt"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/cloudinfo"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/testaddons"
	"log"
	"math/rand"
	"os"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/files"
	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/common"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/testhelper"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/testschematic"
)

const completeExampleDir = "examples/complete"
const fsExampleDir = "examples/fscloud"
const secEnforcedDir = "solutions/security-enforced"
const fullyConfigurableDADir = "solutions/fully-configurable"

// Use existing group for tests
const resourceGroup = "geretain-test-event-notifications"

const yamlLocation = "../common-dev-assets/common-go-assets/common-permanent-resources.yaml"

// Current supported EN region
var validRegions = []string{
	"us-south",
	"eu-de",
	"eu-es",
	"eu-gb",
	"au-syd",
}

var permanentResources map[string]interface{}

// TestMain will be run before any parallel tests, used to read data from yaml for use with tests
func TestMain(m *testing.M) {

	var err error
	permanentResources, err = common.LoadMapFromYaml(yamlLocation)
	if err != nil {
		log.Fatal(err)
	}

	os.Exit(m.Run())
}

func setupOptions(t *testing.T, prefix string, dir string) *testhelper.TestOptions {

	options := testhelper.TestOptionsDefaultWithVars(&testhelper.TestOptions{
		Testing:      t,
		TerraformDir: dir,
		Prefix:       prefix,
		/*
		 Comment out the 'ResourceGroup' input to force this tests to create a unique resource group. This is because
		 there is a restriction with the Event Notification service, which allows only one Lite plan instance per resource group.
		*/
		// ResourceGroup:      resourceGroup,
		Region: validRegions[rand.Intn(len(validRegions))],
	})

	return options
}

func TestBasicFullyConfigurableInSchematics(t *testing.T) {
	t.Parallel()

	var region = validRegions[rand.Intn(len(validRegions))]

	options := testschematic.TestSchematicOptionsDefault(&testschematic.TestSchematicOptions{
		Testing: t,
		Prefix:  "en-basic",
		TarIncludePatterns: []string{
			"*.tf",
			fullyConfigurableDADir + "/*.tf",
		},
		ResourceGroup:          resourceGroup,
		TemplateFolder:         fullyConfigurableDADir,
		Tags:                   []string{"test-schematic"},
		DeleteWorkspaceOnFail:  false,
		WaitJobCompleteMinutes: 60,
	})

	options.TerraformVars = []testschematic.TestSchematicTerraformVar{
		{Name: "ibmcloud_api_key", Value: options.RequiredEnvironmentVars["TF_VAR_ibmcloud_api_key"], DataType: "string", Secure: true},
		{Name: "prefix", Value: options.Prefix, DataType: "string"},
		{Name: "region", Value: region, DataType: "string"},
	}

	err := options.RunSchematicTest()
	assert.Nil(t, err, "This should not have errored")
}

func TestCompleteExampleInSchematics(t *testing.T) {
	t.Parallel()

	var region = validRegions[rand.Intn(len(validRegions))]

	options := testschematic.TestSchematicOptionsDefault(&testschematic.TestSchematicOptions{
		Testing: t,
		Prefix:  "en-complete",
		TarIncludePatterns: []string{
			"*.tf",
			completeExampleDir + "/*.tf",
		},
		ResourceGroup:          resourceGroup,
		TemplateFolder:         completeExampleDir,
		Tags:                   []string{"test-schematic"},
		DeleteWorkspaceOnFail:  false,
		WaitJobCompleteMinutes: 60,
	})

	options.TerraformVars = []testschematic.TestSchematicTerraformVar{
		{Name: "ibmcloud_api_key", Value: options.RequiredEnvironmentVars["TF_VAR_ibmcloud_api_key"], DataType: "string", Secure: true},
		{Name: "prefix", Value: options.Prefix, DataType: "string"},
		{Name: "region", Value: region, DataType: "string"},
		{Name: "access_tags", Value: permanentResources["accessTags"], DataType: "list"},
	}

	err := options.RunSchematicTest()
	assert.Nil(t, err, "This should not have errored")
}

func TestSecurityEnforcedDAInSchematics(t *testing.T) {
	t.Parallel()

	var region = validRegions[rand.Intn(len(validRegions))]

	options := testschematic.TestSchematicOptionsDefault(&testschematic.TestSchematicOptions{
		Testing: t,
		Prefix:  "en-da",
		TarIncludePatterns: []string{
			"*.tf",
			fullyConfigurableDADir + "/*.tf",
			secEnforcedDir + "/*.tf",
		},
		TemplateFolder:         secEnforcedDir,
		Tags:                   []string{"test-schematic"},
		DeleteWorkspaceOnFail:  false,
		WaitJobCompleteMinutes: 60,
	})

	serviceCredentialSecrets := []map[string]interface{}{
		{
			"secret_group_name": fmt.Sprintf("%s-secret-group", options.Prefix),
			"service_credentials": []map[string]string{
				{
					"secret_name": fmt.Sprintf("%s-cred-reader", options.Prefix),
					"service_credentials_source_service_role_crn": "crn:v1:bluemix:public:iam::::serviceRole:Reader",
				},
				{
					"secret_name": fmt.Sprintf("%s-cred-writer", options.Prefix),
					"service_credentials_source_service_role_crn": "crn:v1:bluemix:public:iam::::serviceRole:Writer",
				},
				{
					"secret_name": fmt.Sprintf("%s-cred-editor", options.Prefix),
					"service_credentials_source_service_role_crn": "crn:v1:bluemix:public:iam::::role:Editor",
				},
			},
		},
	}

	serviceCredentialNames := map[string]string{
		"admin": "Manager",
		"user1": "Writer",
		"user2": "Reader",
	}

	serviceCredentialNamesJSON, err := json.Marshal(serviceCredentialNames)
	if err != nil {
		log.Fatalf("Error converting to JSON: %s", err)
	}

	options.TerraformVars = []testschematic.TestSchematicTerraformVar{
		{Name: "prefix", Value: options.Prefix, DataType: "string"},
		{Name: "ibmcloud_api_key", Value: options.RequiredEnvironmentVars["TF_VAR_ibmcloud_api_key"], DataType: "string", Secure: true},
		{Name: "region", Value: region, DataType: "string"},
		{Name: "existing_resource_group_name", Value: permanentResources["general_test_storage_cos_instance_resource_group"], DataType: "string"},
		{Name: "existing_kms_instance_crn", Value: permanentResources["hpcs_south_crn"], DataType: "string"},
		{Name: "kms_endpoint_url", Value: permanentResources["hpcs_south_private_endpoint"], DataType: "string"},
		{Name: "existing_secrets_manager_instance_crn", Value: permanentResources["secretsManagerCRN"], DataType: "string"},
		{Name: "service_credential_secrets", Value: serviceCredentialSecrets, DataType: "list(object)"},
		{Name: "service_credential_names", Value: string(serviceCredentialNamesJSON), DataType: "map(string)"},
		{Name: "existing_cos_instance_crn", Value: permanentResources["general_test_storage_cos_instance_crn"], DataType: "string"},
	}

	err = options.RunSchematicTest()
	assert.Nil(t, err, "This should not have errored")
}

func TestFullyConfigurableDAInSchematics(t *testing.T) {
	t.Parallel()

	var region = validRegions[rand.Intn(len(validRegions))]

	options := testschematic.TestSchematicOptionsDefault(&testschematic.TestSchematicOptions{
		Testing: t,
		Prefix:  "en-da",
		TarIncludePatterns: []string{
			"*.tf",
			fullyConfigurableDADir + "/*.tf",
		},
		TemplateFolder:         fullyConfigurableDADir,
		Tags:                   []string{"test-schematic"},
		DeleteWorkspaceOnFail:  false,
		WaitJobCompleteMinutes: 60,
	})

	serviceCredentialSecrets := []map[string]interface{}{
		{
			"secret_group_name": fmt.Sprintf("%s-secret-group", options.Prefix),
			"service_credentials": []map[string]string{
				{
					"secret_name": fmt.Sprintf("%s-cred-reader", options.Prefix),
					"service_credentials_source_service_role_crn": "crn:v1:bluemix:public:iam::::serviceRole:Reader",
				},
				{
					"secret_name": fmt.Sprintf("%s-cred-writer", options.Prefix),
					"service_credentials_source_service_role_crn": "crn:v1:bluemix:public:iam::::serviceRole:Writer",
				},
				{
					"secret_name": fmt.Sprintf("%s-cred-editor", options.Prefix),
					"service_credentials_source_service_role_crn": "crn:v1:bluemix:public:iam::::role:Editor",
				},
			},
		},
	}

	serviceCredentialNames := map[string]string{
		"admin": "Manager",
		"user1": "Writer",
		"user2": "Reader",
	}

	serviceCredentialNamesJSON, err := json.Marshal(serviceCredentialNames)
	if err != nil {
		log.Fatalf("Error converting to JSON: %s", err)
	}

	options.TerraformVars = []testschematic.TestSchematicTerraformVar{
		{Name: "prefix", Value: options.Prefix, DataType: "string"},
		{Name: "ibmcloud_api_key", Value: options.RequiredEnvironmentVars["TF_VAR_ibmcloud_api_key"], DataType: "string", Secure: true},
		{Name: "region", Value: region, DataType: "string"},
		{Name: "existing_resource_group_name", Value: permanentResources["general_test_storage_cos_instance_resource_group"], DataType: "string"},

		{Name: "kms_encryption_enabled", Value: true, DataType: "bool"},
		{Name: "existing_kms_instance_crn", Value: permanentResources["hpcs_south_crn"], DataType: "string"},
		{Name: "kms_endpoint_url", Value: permanentResources["hpcs_south_private_endpoint"], DataType: "string"},

		{Name: "enable_collecting_failed_events", Value: true, DataType: "bool"},
		{Name: "existing_cos_instance_crn", Value: permanentResources["general_test_storage_cos_instance_crn"], DataType: "string"},
		{Name: "cos_bucket_region", Value: "us-south", DataType: "string"},

		{Name: "existing_secrets_manager_instance_crn", Value: permanentResources["secretsManagerCRN"], DataType: "string"},
		{Name: "service_credential_secrets", Value: serviceCredentialSecrets, DataType: "list(object)"},
		{Name: "service_credential_names", Value: string(serviceCredentialNamesJSON), DataType: "map(string)"},
	}

	err = options.RunSchematicTest()
	assert.Nil(t, err, "This should not have errored")
}

func TestFSCloudInSchematics(t *testing.T) {
	t.Parallel()

	var region = validRegions[rand.Intn(len(validRegions))]

	options := testschematic.TestSchematicOptionsDefault(&testschematic.TestSchematicOptions{
		Testing: t,
		Prefix:  "en-fs",
		TarIncludePatterns: []string{
			"*.tf",
			fsExampleDir + "/*.tf",
			"modules/fscloud/*.tf",
		},
		ResourceGroup:          resourceGroup,
		TemplateFolder:         fsExampleDir,
		Tags:                   []string{"test-schematic"},
		DeleteWorkspaceOnFail:  false,
		WaitJobCompleteMinutes: 60,
	})

	options.TerraformVars = []testschematic.TestSchematicTerraformVar{
		{Name: "ibmcloud_api_key", Value: options.RequiredEnvironmentVars["TF_VAR_ibmcloud_api_key"], DataType: "string", Secure: true},
		{Name: "region", Value: region, DataType: "string"},
		{Name: "prefix", Value: options.Prefix, DataType: "string"},
		{Name: "existing_kms_instance_crn", Value: permanentResources["hpcs_south_crn"], DataType: "string"},
		{Name: "kms_endpoint_url", Value: permanentResources["hpcs_south_private_endpoint"], DataType: "string"},
		{Name: "root_key_crn", Value: permanentResources["hpcs_south_root_key_crn"], DataType: "string"},
		{Name: "access_tags", Value: permanentResources["accessTags"], DataType: "list"},
	}

	err := options.RunSchematicTest()
	assert.Nil(t, err, "This should not have errored")
}

func TestRunSecurityEnforcedUpgradeDASolution(t *testing.T) {
	t.Parallel()

	prefix := "ensecupg"
	var region = validRegions[rand.Intn(len(validRegions))]

	// Verify ibmcloud_api_key variable is set
	checkVariable := "TF_VAR_ibmcloud_api_key"
	val, present := os.LookupEnv(checkVariable)
	require.True(t, present, checkVariable+" environment variable not set")
	require.NotEqual(t, "", val, checkVariable+" environment variable is empty")

	// ------------------------------------------------------------------------------------
	// Deploy EN DA passing in existing RG, KMS and COS instances
	// ------------------------------------------------------------------------------------
	options := testschematic.TestSchematicOptionsDefault(&testschematic.TestSchematicOptions{
		Testing: t,
		Prefix:  prefix,
		TarIncludePatterns: []string{
			"*.tf",
			fullyConfigurableDADir + "/*.tf",
			secEnforcedDir + "/*.tf",
		},
		TemplateFolder:         secEnforcedDir,
		Tags:                   []string{"test-schematic"},
		DeleteWorkspaceOnFail:  false,
		WaitJobCompleteMinutes: 60,
	})
	options.TerraformVars = []testschematic.TestSchematicTerraformVar{
		{Name: "prefix", Value: options.Prefix, DataType: "string"},
		{Name: "ibmcloud_api_key", Value: options.RequiredEnvironmentVars["TF_VAR_ibmcloud_api_key"], DataType: "string", Secure: true},
		{Name: "existing_resource_group_name", Value: permanentResources["general_test_storage_cos_instance_resource_group"], DataType: "string"},
		{Name: "region", Value: region, DataType: "string"},
		{Name: "existing_kms_instance_crn", Value: permanentResources["hpcs_south_crn"], DataType: "string"},
		{Name: "kms_endpoint_url", Value: permanentResources["hpcs_south_public_endpoint"], DataType: "string"},
		{Name: "existing_cos_instance_crn", Value: permanentResources["general_test_storage_cos_instance_crn"], DataType: "string"},
	}
	err := options.RunSchematicUpgradeTest()
	if !options.UpgradeTestSkipped {
		assert.Nil(t, err, "This should not have errored")
	}
}

func TestRunExistingResourcesInstances(t *testing.T) {
	t.Parallel()

	// ------------------------------------------------------------------------------------
	// Provision existing resources first
	// ------------------------------------------------------------------------------------

	prefix := fmt.Sprintf("en-existing-%s", strings.ToLower(random.UniqueId()))
	realTerraformDir := ".."
	tempTerraformDir, _ := files.CopyTerraformFolderToTemp(realTerraformDir, fmt.Sprintf(prefix+"-%s", strings.ToLower(random.UniqueId())))
	existingRes := realTerraformDir + "/tests/existing-resources"

	// Verify ibmcloud_api_key variable is set
	checkVariable := "TF_VAR_ibmcloud_api_key"
	val, present := os.LookupEnv(checkVariable)
	require.True(t, present, checkVariable+" environment variable not set")
	require.NotEqual(t, "", val, checkVariable+" environment variable is empty")
	logger.Log(t, "Tempdir: ", tempTerraformDir)
	existingTerraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: existingRes,
		Vars: map[string]interface{}{
			"prefix": prefix,
			"region": validRegions[rand.Intn(len(validRegions))],
		},
		// Set Upgrade to true to ensure latest version of providers and modules are used by terratest.
		// This is the same as setting the -upgrade=true flag with terraform.
		Upgrade: true,
	})
	terraform.WorkspaceSelectOrNew(t, existingTerraformOptions, prefix)
	_, existErr := terraform.InitAndApplyE(t, existingTerraformOptions)
	if existErr != nil {
		assert.True(t, existErr == nil, "Init and Apply of temp existing resource failed")
	} else {

		var region = validRegions[rand.Intn(len(validRegions))]

		// ------------------------------------------------------------------------------------
		// Deploy EN DA passing in existing RG and EN
		// ------------------------------------------------------------------------------------

		options := testschematic.TestSchematicOptionsDefault(&testschematic.TestSchematicOptions{
			Testing: t,
			Prefix:  "enexres",
			TarIncludePatterns: []string{
				"*.tf",
				fullyConfigurableDADir + "/*.tf",
			},
			TemplateFolder:         fullyConfigurableDADir,
			Tags:                   []string{"test-schematic"},
			DeleteWorkspaceOnFail:  false,
			WaitJobCompleteMinutes: 60,
		})
		options.TerraformVars = []testschematic.TestSchematicTerraformVar{
			{Name: "prefix", Value: options.Prefix, DataType: "string"},
			{Name: "ibmcloud_api_key", Value: options.RequiredEnvironmentVars["TF_VAR_ibmcloud_api_key"], DataType: "string", Secure: true},
			{Name: "region", Value: region, DataType: "string"},
			{Name: "existing_resource_group_name", Value: permanentResources["general_test_storage_cos_instance_resource_group"], DataType: "string"},
			{Name: "existing_event_notifications_instance_crn", Value: terraform.Output(t, existingTerraformOptions, "event_notification_instance_crn"), DataType: "string"},
		}
		err := options.RunSchematicTest()
		assert.NoError(t, err, "TestRunExistingResourcesInstances using existing RG and EN Failed")

		// ------------------------------------------------------------------------------------
		// Deploy EN DA passing in existing RG, COS instance, Cloud Monitoring instance and KMS key
		// ------------------------------------------------------------------------------------

		options2 := testschematic.TestSchematicOptionsDefault(&testschematic.TestSchematicOptions{
			Testing: t,
			Prefix:  "enexres2",
			TarIncludePatterns: []string{
				"*.tf",
				fullyConfigurableDADir + "/*.tf",
			},
			TemplateFolder:         fullyConfigurableDADir,
			Tags:                   []string{"test-schematic"},
			DeleteWorkspaceOnFail:  false,
			WaitJobCompleteMinutes: 60,
		})
		options2.TerraformVars = []testschematic.TestSchematicTerraformVar{
			{Name: "prefix", Value: options.Prefix, DataType: "string"},
			{Name: "ibmcloud_api_key", Value: options.RequiredEnvironmentVars["TF_VAR_ibmcloud_api_key"], DataType: "string", Secure: true},
			{Name: "region", Value: region, DataType: "string"},
			{Name: "existing_resource_group_name", Value: permanentResources["general_test_storage_cos_instance_resource_group"], DataType: "string"},
			{Name: "kms_encryption_enabled", Value: true, DataType: "bool"},
			{Name: "existing_kms_root_key_crn", Value: terraform.Output(t, existingTerraformOptions, "key_crn"), DataType: "string"},
			{Name: "kms_endpoint_url", Value: permanentResources["hpcs_south_private_endpoint"], DataType: "string"},
			{Name: "enable_collecting_failed_events", Value: true, DataType: "bool"},
			{Name: "existing_cos_instance_crn", Value: terraform.Output(t, existingTerraformOptions, "cos_crn"), DataType: "string"},
			{Name: "existing_monitoring_crn", Value: terraform.Output(t, existingTerraformOptions, "cloud_monitoring_crn"), DataType: "string"},
		}
		err2 := options2.RunSchematicTest()
		assert.NoError(t, err2, "TestRunExistingResourcesInstances using existing RG, COS instance, and KMS key Failed")

		// ------------------------------------------------------------------------------------
		// Deploy EN DA passing in existing RG, COS instance and KMS instance
		// ------------------------------------------------------------------------------------
		options3 := testschematic.TestSchematicOptionsDefault(&testschematic.TestSchematicOptions{
			Testing: t,
			Prefix:  "enexsres3",
			TarIncludePatterns: []string{
				"*.tf",
				fullyConfigurableDADir + "/*.tf",
			},
			TemplateFolder:         fullyConfigurableDADir,
			Tags:                   []string{"test-schematic"},
			DeleteWorkspaceOnFail:  false,
			WaitJobCompleteMinutes: 60,
		})
		options3.TerraformVars = []testschematic.TestSchematicTerraformVar{
			{Name: "prefix", Value: options3.Prefix, DataType: "string"},
			{Name: "ibmcloud_api_key", Value: options.RequiredEnvironmentVars["TF_VAR_ibmcloud_api_key"], DataType: "string", Secure: true},
			{Name: "region", Value: region, DataType: "string"},
			{Name: "existing_resource_group_name", Value: permanentResources["general_test_storage_cos_instance_resource_group"], DataType: "string"},
			{Name: "existing_kms_instance_crn", Value: permanentResources["hpcs_south_crn"], DataType: "string"},
			{Name: "kms_encryption_enabled", Value: true, DataType: "bool"},
			{Name: "kms_endpoint_url", Value: permanentResources["hpcs_south_private_endpoint"], DataType: "string"},
			{Name: "enable_collecting_failed_events", Value: true, DataType: "bool"},
			{Name: "existing_cos_instance_crn", Value: terraform.Output(t, existingTerraformOptions, "cos_crn"), DataType: "string"},
			{Name: "cos_bucket_name", Value: terraform.Output(t, existingTerraformOptions, "bucket_name"), DataType: "string"},
		}
		err3 := options3.RunSchematicTest()
		assert.NoError(t, err3, "TestRunExistingResourcesInstances using existing RG, COS instance and KMS instance Failed")
	}
	// Check if "DO_NOT_DESTROY_ON_FAILURE" is set
	envVal, _ := os.LookupEnv("DO_NOT_DESTROY_ON_FAILURE")
	// Destroy the temporary existing resources if required
	if t.Failed() && strings.ToLower(envVal) == "true" {
		fmt.Println("Terratest failed. Debug the test and delete resources manually.")
	} else {
		logger.Log(t, "START: Destroy (existing resources)")
		terraform.Destroy(t, existingTerraformOptions)
		terraform.WorkspaceDelete(t, existingTerraformOptions, prefix)
		logger.Log(t, "END: Destroy (existing resources)")
	}
}

func TestENDefaultConfiguration(t *testing.T) {
	t.Parallel()

	options := testaddons.TestAddonsOptionsDefault(&testaddons.TestAddonOptions{
		Testing:       t,
		Prefix:        "endeft",
		ResourceGroup: resourceGroup,
		QuietMode:     true, // Suppress logs except on failure
	})

	options.AddonConfig = cloudinfo.NewAddonConfigTerraform(
		options.Prefix,
		"deploy-arch-ibm-event-notifications",
		"fully-configurable",
		map[string]interface{}{
			"prefix":                  options.Prefix,
			"region":                  validRegions[rand.Intn(len(validRegions))],
			"enable_platform_metrics": "false", // Disable platform metrics for addon tests
		},
	)

	err := options.RunAddonTest()
	require.NoError(t, err)
}

// TestDependencyPermutations runs dependency permutations for the Event Notifications and all its dependencies
func TestDependencyPermutations(t *testing.T) {

	options := testaddons.TestAddonsOptionsDefault(&testaddons.TestAddonOptions{
		Testing: t,
		Prefix:  "en-perm",
		AddonConfig: cloudinfo.AddonConfig{
			OfferingName:   "deploy-arch-ibm-event-notifications",
			OfferingFlavor: "fully-configurable",
			Inputs: map[string]interface{}{
				"prefix":                       "en-perm",
				"region":                       validRegions[rand.Intn(len(validRegions))],
				"existing_resource_group_name": resourceGroup,
			},
		},
	})

	err := options.RunAddonPermutationTest()
	assert.NoError(t, err, "Dependency permutation test should not fail")
}
