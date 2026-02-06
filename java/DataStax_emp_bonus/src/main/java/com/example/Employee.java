package com.example;

public class Employee {
    private final String id;
    private final String name;
    private final double salary;
    private final int performanceScore;

    public Employee(String id, String name, double salary, int performanceScore) {
        this.id = id;
        this.name = name;
        this.salary = salary;
        this.performanceScore = performanceScore;
    }

    public String getName() { return name; }
    public double getSalary() { return salary; }
    public int getPerformanceScore() { return performanceScore; }

    @Override
    public String toString() {
        return String.format("Employee[ID=%s, Name=%s, Salary=%.2f, Score=%d]", 
                              id, name, salary, performanceScore);
    }
}