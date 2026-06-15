
#Remove old container
docker rm -f cassandra-db

# Rebuild
docker build -t cassandra-hr-app .

# Run
docker run -d --name cassandra-db -p 9042:9042 cassandra-hr-app

# Wait a bit for initialization
docker logs -f cassandra-db 
# docker logs cassandra-db | tail -20

# Check if it's running
docker ps

# Verify data
docker exec -it cassandra-db cqlsh -e "USE hr_department; SELECT * FROM employee_stats;"

# Clean and compile
mvn clean compile
mvn exec:java -Dexec.mainClass="com.example.Main"
