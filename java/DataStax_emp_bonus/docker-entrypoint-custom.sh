#!/bin/bash
set -e

echo "Starting Cassandra..."
docker-entrypoint.sh cassandra &

echo "Waiting for Cassandra to start..."
until cqlsh -e "describe keyspaces" > /dev/null 2>&1; do
    echo "Still waiting..."
    sleep 3
done

echo "Cassandra is ready!"
echo "Executing initialization script..."
cqlsh -f /create_test_emp_data.cql

echo "Database initialized successfully!"
echo "Keeping container alive..."

# Keep container running forever
tail -f /dev/null
