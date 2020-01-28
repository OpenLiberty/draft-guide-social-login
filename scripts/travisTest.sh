#!/bin/bash
set -euxo pipefail

##############################################################################
##
##  Travis CI test script
##
##############################################################################

# LMP 3.0+ goals are listed here: https://github.com/OpenLiberty/ci.maven#goals

## Rebuild the application
#       package                   - Take the compiled code and package it in its distributable format.
#       liberty:create            - Create a Liberty server.
#       liberty:install-feature   - Install a feature packaged as a Subsystem Archive (esa) to the Liberty runtime.
#       liberty:deploy            - Copy applications to the Liberty server's dropins or apps directory. 
mvn -q clean package liberty:create liberty:install-feature liberty:deploy


## Run the tests
# These commands are separated because if one of the commands fail, the test script will fail and exit. 
# e.g if liberty:start fails, then there is no need to run the failsafe commands. 
#       liberty:start             - Start a Liberty server in the background.
#       failsafe:integration-test - Runs the integration tests of an application.
#       liberty:stop              - Stop a Liberty server.
#       failsafe:verify           - Verifies that the integration tests of an application passed.
mvn liberty:start

# Check that the endpoint returns 200
STATUS="$(curl --write-out "%{http_code}\n" --silent --output /dev/null "http://localhost:9080/api/hello")"
if [ "${STATUS}" -ne "200" ]
    then
        echo "FAIL: Endpoint returned ${STATUS}, expected 200."
        exit 1
fi

# Curl the hello endpoint and verify that it redirects to the social media selection form
RESPONSE=$(curl "http://localhost:9080/api/hello")
if [ -z "${RESPONSE}" ]
    then
        echo "FAIL: Could not find string literal \"Social Media Selection Form\" in response."
        exit 1
fi

mvn liberty:stop