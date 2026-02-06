CREATE KEYSPACE hr_department WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 1};

USE hr_department;

CREATE TABLE employee_stats (
    emp_id text PRIMARY KEY,
    name text,
    salary double,
    performance_score int
);

-- Sample Data
INSERT INTO employee_stats (emp_id, name, salary, performance_score) VALUES ('E01', 'Alice', 80000, 95);
INSERT INTO employee_stats (emp_id, name, salary, performance_score) VALUES ('E02', 'Bob', 75000, 88);
INSERT INTO employee_stats (emp_id, name, salary, performance_score) VALUES ('E03', 'Charlie', 90000, 92);
INSERT INTO employee_stats (emp_id, name, salary, performance_score) VALUES ('E04', 'David', 70000, 85);
INSERT INTO employee_stats (emp_id, name, salary, performance_score) VALUES ('E05', 'Eve', 85000, 98);
INSERT INTO employee_stats (emp_id, name, salary, performance_score) VALUES ('E06', 'Frank', 60000, 70);