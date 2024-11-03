#!/bin/bash

# Variables
TEST_CONTAINER_NAME="test-cert-script"
TEST_HOSTNAME="localhost"
CONFIG_FILE_PATH=$(pwd)/security/tests/app_config

echo "Running test_certbot.sh"

# Clean up any previous test containers
docker rm -f $TEST_CONTAINER_NAME 2>/dev/null

# Run the container with the test configuration
docker run -d --rm \
    -v $CONFIG_FILE_PATH:/run/secrets/app_config \
    --name $TEST_CONTAINER_NAME \
    test-cert-script

# Allow some time for the container to initialize and run the script
sleep 10

# Define expected paths based on environment
EXPECTED_PATH="/etc/letsencrypt/live/$TEST_HOSTNAME"

# Check if the self-signed certificate was created in the expected directory
if docker exec $TEST_CONTAINER_NAME [ -f "$EXPECTED_PATH/localhost.crt" ] && \
   docker exec $TEST_CONTAINER_NAME [ -f "$EXPECTED_PATH/localhost.key" ]; then
    echo "Test passed: Self-signed certificate generated correctly at $EXPECTED_PATH"
    TEST_RESULT=0
else
    echo "Test failed: Self-signed certificate not found at $EXPECTED_PATH"
    TEST_RESULT=1
fi

# Stop the container after the test
docker stop $TEST_CONTAINER_NAME

exit $TEST_RESULT
