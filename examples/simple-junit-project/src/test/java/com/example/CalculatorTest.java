package com.example;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

/**
 * Unit tests for the Calculator class.
 */
public class CalculatorTest {
    
    private Calculator calculator;
    
    @BeforeEach
    public void setUp() {
        calculator = new Calculator();
    }
    
    @Test
    public void testAdd() {
        assertEquals(5, calculator.add(2, 3), "2 + 3 should equal 5");
        assertEquals(0, calculator.add(-2, 2), "-2 + 2 should equal 0");
        assertEquals(-5, calculator.add(-2, -3), "-2 + -3 should equal -5");
    }
    
    @Test
    public void testSubtract() {
        assertEquals(2, calculator.subtract(5, 3), "5 - 3 should equal 2");
        assertEquals(-2, calculator.subtract(3, 5), "3 - 5 should equal -2");
        assertEquals(0, calculator.subtract(3, 3), "3 - 3 should equal 0");
    }
    
    @Test
    public void testMultiply() {
        assertEquals(6, calculator.multiply(2, 3), "2 * 3 should equal 6");
        assertEquals(0, calculator.multiply(5, 0), "5 * 0 should equal 0");
        assertEquals(-6, calculator.multiply(2, -3), "2 * -3 should equal -6");
    }
    
    @Test
    public void testDivide() {
        assertEquals(2, calculator.divide(6, 3), "6 / 3 should equal 2");
        assertEquals(0.5, calculator.divide(1, 2), "1 / 2 should equal 0.5");
        assertEquals(-2, calculator.divide(-6, 3), "-6 / 3 should equal -2");
    }
    
    @Test
    public void testDivideByZero() {
        Exception exception = assertThrows(IllegalArgumentException.class, () -> {
            calculator.divide(1, 0);
        });
        
        String expectedMessage = "Division by zero is not allowed";
        String actualMessage = exception.getMessage();
        
        assertTrue(actualMessage.contains(expectedMessage));
    }
}