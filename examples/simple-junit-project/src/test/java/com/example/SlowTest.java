package com.example;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

/**
 * Test class that simulates slow test execution by adding delays.
 * This helps demonstrate MVNimble's test optimization capabilities.
 */
public class SlowTest {
    
    private Calculator calculator;
    
    @BeforeEach
    public void setUp() {
        calculator = new Calculator();
        // Simulate slow test setup
        try {
            Thread.sleep(100);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }
    
    @Test
    public void testSlowAddition() throws InterruptedException {
        // Simulate a slow test with a delay
        Thread.sleep(500);
        assertEquals(5, calculator.add(2, 3), "2 + 3 should equal 5");
    }
    
    @Test
    public void testVerySlowMultiplication() throws InterruptedException {
        // Simulate a very slow test with a longer delay
        Thread.sleep(1000);
        assertEquals(10, calculator.multiply(2, 5), "2 * 5 should equal 10");
    }
    
    @Test
    public void testModeratelySlowDivision() throws InterruptedException {
        // Simulate a moderately slow test
        Thread.sleep(750);
        assertEquals(4, calculator.divide(8, 2), "8 / 2 should equal 4");
    }
    
    @Test
    public void testSlowSubtraction() throws InterruptedException {
        // Another slow test
        Thread.sleep(600);
        assertEquals(5, calculator.subtract(10, 5), "10 - 5 should equal 5");
    }
    
    @Test
    public void testComplexSlowCalculation() throws InterruptedException {
        // Simulate a complex test case with multiple operations and delays
        Thread.sleep(300);
        double result = calculator.add(5, 5);
        Thread.sleep(300);
        result = calculator.multiply(result, 2);
        Thread.sleep(300);
        result = calculator.subtract(result, 5);
        assertEquals(15, result, "((5 + 5) * 2) - 5 should equal 15");
    }
}