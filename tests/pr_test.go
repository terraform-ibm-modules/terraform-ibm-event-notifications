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
	"testing"

	"github.com/IBM/go-sdk-core/v5/core"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/common"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/testschematic"
)

/*
Global variables
*/
const advancedExampleDir = "examples/advanced"
const basicExampleDir = "examples/basic"
const fsExampleDir = "examples/fscloud"
const secEnforcedDir = "solutions/security-enforced"
const fullyConfigurableDADir = "solutions/fully-configurable"
const terraformVersion = "terraform_v1.12.2" // This should match the version in the ibm_catalog.json
const resourceGroup = "geretain-test-event-notifications"
const yamlLocation = "../common-dev-assets/common-go-assets/common-permanent-resources.yaml"

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
		TerraformVersion:       terraformVersion,
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
		TerraformVersion:       terraformVersion,
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

func TestRunSecurityEnforcedUpgradeDASolution(t *testing.T) {
	t.Parallel()

	// ------------------------------------------------------------------------------------
	// Deploy EN DA passing in existing RG, KMS and COS instances
	// ------------------------------------------------------------------------------------
	options := testschematic.TestSchematicOptionsDefault(&testschematic.TestSchematicOptions{
		Testing: t,
		Prefix:  "ensecupg",
		TarIncludePatterns: []string{
			"*.tf",
			fullyConfigurableDADir + "/*.tf",
			secEnforcedDir + "/*.tf",
		},
		TemplateFolder:             secEnforcedDir,
		Tags:                       []string{"test-schematic"},
		DeleteWorkspaceOnFail:      false,
		WaitJobCompleteMinutes:     60,
		Region:                     validRegions[rand.Intn(len(validRegions))],
		CheckApplyResultForUpgrade: true,
		TerraformVersion:           terraformVersion,
	})
	options.TerraformVars = []testschematic.TestSchematicTerraformVar{
		{Name: "prefix", Value: options.Prefix, DataType: "string"},
		{Name: "ibmcloud_api_key", Value: options.RequiredEnvironmentVars["TF_VAR_ibmcloud_api_key"], DataType: "string", Secure: true},
		{Name: "existing_resource_group_name", Value: permanentResources["general_test_storage_cos_instance_resource_group"], DataType: "string"},
		{Name: "region", Value: options.Region, DataType: "string"},
		{Name: "existing_kms_instance_crn", Value: permanentResources["hpcs_south_crn"], DataType: "string"},
		{Name: "kms_endpoint_url", Value: permanentResources["hpcs_south_public_endpoint"], DataType: "string"},
		{Name: "existing_cos_instance_crn", Value: permanentResources["general_test_storage_cos_instance_crn"], DataType: "string"},
	}
	err := options.RunSchematicUpgradeTest()
	if !options.UpgradeTestSkipped {
		assert.Nil(t, err, "This should not have errored")
	}
}

// Test deployment with all "on-by-default" dependant DAs
func TestAddonDefaultConfiguration(t *testing.T) {
	t.Parallel()

	options := testaddons.TestAddonsOptionsDefault(&testaddons.TestAddonOptions{
		Testing:       t,
		Prefix:        "en-addon",
		ResourceGroup: resourceGroup,
		QuietMode:     true, // Suppress logs except on failure
	})

	options.AddonConfig = cloudinfo.NewAddonConfigTerraform(
		options.Prefix,
		"deploy-arch-ibm-event-notifications",
		"fully-configurable",
		map[string]interface{}{
			"region":                  validRegions[rand.Intn(len(validRegions))],
			"existing_resource_group": resourceGroup,
		},
	)

	// Disable target / route creation to prevent hitting quota in account
	options.AddonConfig.Dependencies = []cloudinfo.AddonConfig{
		{
			OfferingName:   "deploy-arch-ibm-cloud-monitoring",
			OfferingFlavor: "fully-configurable",
			Inputs: map[string]interface{}{
				"enable_metrics_routing_to_cloud_monitoring": false,
			},
			Enabled: core.BoolPtr(true),
		},
	}

	err := options.RunAddonTest()
	require.NoError(t, err)
}
