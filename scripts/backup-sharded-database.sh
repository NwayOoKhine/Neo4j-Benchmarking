#!/usr/bin/env bash

set -eu
set -o pipefail

echo "Backing up sharded Neo4j databases..."

# Stop all containers
echo "Stopping containers..."
docker-compose stop neo4j-fabric neo4j-persons neo4j-forums

# Create backup directories if they don't exist
mkdir -p backups/

# Backup each shard's volume to tar files
echo "Backing up persons shard..."
docker run --rm -v neo4j-fabric-project_neo4j-data-persons:/data -v "$(pwd)/backups:/backup" alpine tar czf /backup/neo4j-data-persons-backup.tar.gz -C /data .

echo "Backing up forums shard..."
docker run --rm -v neo4j-fabric-project_neo4j-data-forums:/data -v "$(pwd)/backups:/backup" alpine tar czf /backup/neo4j-data-forums-backup.tar.gz -C /data .

echo "Backing up fabric coordinator..."
docker run --rm -v neo4j-fabric-project_neo4j-data-main:/data -v "$(pwd)/backups:/backup" alpine tar czf /backup/neo4j-data-main-backup.tar.gz -C /data .

# Restart containers
echo "Restarting containers..."
docker-compose up -d neo4j-persons neo4j-forums neo4j-fabric

# Wait for containers to be ready
echo "Waiting for databases to start..."
sleep 10

echo "Testing connectivity..."
docker exec neo4j-persons cypher-shell -u neo4j -p password "RETURN 'Persons ready' as status" || echo "Persons not ready yet"
docker exec neo4j-forums cypher-shell -u neo4j -p password "RETURN 'Forums ready' as status" || echo "Forums not ready yet"
docker exec neo4j-fabric cypher-shell -u neo4j -p password "RETURN 'Fabric ready' as status" || echo "Fabric not ready yet"

echo "Backup completed! Files stored in ./backups/"
ls -la backups/
