
FROM cassandra:4.1

# Copy the CQL initialization script
COPY create_test_emp_data.cql /create_test_emp_data.cql
COPY docker-entrypoint-custom.sh /docker-entrypoint-custom.sh

RUN chmod +x /docker-entrypoint-custom.sh
#expose casandra
EXPOSE 9042

ENTRYPOINT ["/docker-entrypoint-custom.sh"]

