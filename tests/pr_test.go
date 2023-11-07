// Tests in this file are run in the PR pipeline and the continuous testing pipeline
package test

import (
	"math/rand"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/testhelper"
)

const completeExampleDir = "examples/complete"

// Use existing group for tests
const resourceGroup = "geretain-test-event-notifications"

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
