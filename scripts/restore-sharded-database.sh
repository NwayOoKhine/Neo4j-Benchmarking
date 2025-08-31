#!/usr/bin/env bash

set -eu
set -o pipefail

echo "Restoring sharded Neo4j databases from backup..."

# Check if backup files exist
if [ ! -f "backups/neo4j-data-persons-backup.tar.gz" ] || [ ! -f "backups/neo4j-data-forums-backup.tar.gz" ] || [ ! -f "backups/neo4j-data-main-backup.tar.gz" ]; then
    echo "Error: Backup files not found in ./backups/"
    echo "Please run backup-sharded-database.sh first"
    exit 1
fi

# Stop all containers
echo "Stopping containers..."
docker-compose stop neo4j-fabric neo4j-persons neo4j-forums

# Remove existing volumes
echo "Removing existing data volumes..."
docker volume rm neo4j-fabric-project_neo4j-data-persons neo4j-fabric-project_neo4j-data-forums neo4j-fabric-project_neo4j-data-main || echo "Some volumes may not exist"

# Recreate volumes
echo "Recreating volumes..."
docker volume create neo4j-fabric-project_neo4j-data-persons
docker volume create neo4j-fabric-project_neo4j-data-forums
docker volume create neo4j-fabric-project_neo4j-data-main

# Restore each shard from backup
echo "Restoring persons shard..."
docker run --rm -v neo4j-fabric-project_neo4j-data-persons:/data -v "$(pwd)/backups:/backup" alpine tar xzf /backup/neo4j-data-persons-backup.tar.gz -C /data

echo "Restoring forums shard..."
docker run --rm -v neo4j-fabric-project_neo4j-data-forums:/data -v "$(pwd)/backups:/backup" alpine tar xzf /backup/neo4j-data-forums-backup.tar.gz -C /data

echo "Restoring fabric coordinator..."
docker run --rm -v neo4j-fabric-project_neo4j-data-main:/data -v "$(pwd)/backups:/backup" alpine tar xzf /backup/neo4j-data-main-backup.tar.gz -C /data

# Restart containers
echo "Restarting containers..."
docker-compose up -d neo4j-persons neo4j-forums neo4j-fabric

# Wait for containers to be ready
echo "Waiting for databases to start..."
sleep 15

echo "Testing connectivity..."
until docker exec neo4j-persons cypher-shell -u neo4j -p password "RETURN 'Persons restored' as status" > /dev/null 2>&1; do
    echo -n "."
    sleep 2
done
echo "Persons database ready"

until docker exec neo4j-forums cypher-shell -u neo4j -p password "RETURN 'Forums restored' as status" > /dev/null 2>&1; do
    echo -n "."
    sleep 2
done
echo "Forums database ready"

until docker exec neo4j-fabric cypher-shell -u neo4j -p password "RETURN 'Fabric restored' as status" > /dev/null 2>&1; do
    echo -n "."
    sleep 2
done
echo "Fabric database ready"

echo "Restore completed successfully!"
