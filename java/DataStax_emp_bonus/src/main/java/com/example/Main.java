package com.example;

import com.datastax.oss.driver.api.core.CqlSession;
import com.datastax.oss.driver.api.core.cql.ResultSet;
import com.datastax.oss.driver.api.core.cql.Row;
import java.net.InetSocketAddress;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.stream.Collectors;

public class Main {
    public static void main(String[] args) {
        // Replace with your Cassandra node IP and local DC name
        String cassandraNode = "127.0.0.1";
        String dataCenter = "datacenter1"; 

        try (CqlSession session = CqlSession.builder()
                .addContactPoint(new InetSocketAddress(cassandraNode, 9042))
                .withLocalDatacenter(dataCenter)
                .withKeyspace("hr_department")
                .build()) {

            System.out.println("Connected to Cassandra!");

            // 1. Fetch data
            String query = "SELECT emp_id, name, salary, performance_score FROM employee_stats";
            ResultSet rs = session.execute(query);

            List<Employee> employees = new ArrayList<>();
            for (Row row : rs) {
                employees.add(new Employee(
                    row.getString("emp_id"),
                    row.getString("name"),
                    row.getDouble("salary"),
                    row.getInt("performance_score")
                ));
            }

            // 2. Filter Top 5 Performers
            List<Employee> topFive = employees.stream()
                .sorted(Comparator.comparingInt(Employee::getPerformanceScore).reversed())
                .limit(5)
                .collect(Collectors.toList());

            // 3. Calculate Bonus (15% for score > 90, else 10%)
            System.out.println("\n--- Bonus Results ---");
            for (Employee emp : topFive) {
                double bonusRate = (emp.getPerformanceScore() >= 90) ? 0.15 : 0.10;
                double bonusAmount = emp.getSalary() * bonusRate;

                System.out.printf("Winner: %-10s | Score: %d | Base: $%.2f | Bonus: $%.2f (%.0f%%)%n",
                        emp.getName(), emp.getPerformanceScore(), emp.getSalary(), 
                        bonusAmount, bonusRate * 100);
            }

        } catch (Exception e) {
            System.err.println("Error connecting to Cassandra: " + e.getMessage());
            e.printStackTrace();
        }
    }
}