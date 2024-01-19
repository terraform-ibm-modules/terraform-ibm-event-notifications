// Tests in this file are run in the PR pipeline and the continuous testing pipeline
package test

import (
	"log"
	"math/rand"
	"os"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/common"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/testhelper"
)

const completeExampleDir = "examples/complete"
const fsExampleDir = "examples/fscloud"

// Use existing group for tests
const resourceGroup = "geretain-test-event-notifications"

const yamlLocation = "../common-dev-assets/common-go-assets/common-permanent-resources.yaml"

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
	validRegions := []string{
		"us-south",
		"eu-gb",
		"eu-de",
		"au-syd",
		"eu-es",
	}
	options := testhelper.TestOptionsDefaultWithVars(&testhelper.TestOptions{
		Testing:       t,
		TerraformDir:  dir,
		Prefix:        prefix,
		ResourceGroup: resourceGroup,
		Region:        validRegions[rand.Intn(len(validRegions))],
	})
	return options
}

func TestRunCompleteExample(t *testing.T) {
	t.Parallel()

	options := setupOptions(t, "event-notification-complete", completeExampleDir)

	output, err := options.RunTestConsistency()
	assert.Nil(t, err, "This should not have errored")
	assert.NotNil(t, output, "Expected some output")
}

func TestRunUpgradeExample(t *testing.T) {
	t.Parallel()

	options := setupOptions(t, "event-notification-upg", completeExampleDir)

	output, err := options.RunTestUpgrade()
	if !options.UpgradeTestSkipped {
		assert.Nil(t, err, "This should not have errored")
		assert.NotNil(t, output, "Expected some output")
	}
}

func setupOptionsFScloud(t *testing.T, prefix string, dir string) *testhelper.TestOptions {
	validRegions := []string{
		"us-south",
		"eu-gb",
		"eu-de",
		"au-syd",
		"eu-es",
	}
	options := testhelper.TestOptionsDefaultWithVars(&testhelper.TestOptions{
		Testing:       t,
		TerraformDir:  dir,
		Prefix:        prefix,
		ResourceGroup: resourceGroup,
		Region:        validRegions[rand.Intn(len(validRegions))],
		TerraformVars: map[string]interface{}{
			"existing_kms_instance_crn": permanentResources["hpcs_south_crn"],
			"root_key_id":               permanentResources["hpcs_south_root_key_id"],
		},
	})
	return options
}

func TestRunFSCloudExample(t *testing.T) {
	t.Parallel()

	options := setupOptionsFScloud(t, "en-fs", fsExampleDir)

	output, err := options.RunTestConsistency()
	assert.Nil(t, err, "This should not have errored")
	assert.NotNil(t, output, "Expected some output")
}
