# ADR 006: BATS Testing Framework Adoption

## Status

Proposed

## Context

MVNimble requires a robust, reliable testing approach to ensure code quality and correctness across different environments. The current test framework is custom-built and while functional, it:

1. **Lacks Standardization**: Our current approach uses custom test utilities that don't follow industry standards, making onboarding new contributors more challenging.

2. **Limited Test Reporting**: The current framework has basic pass/fail reporting but lacks detailed diagnostics and TAP (Test Anything Protocol) compatibility that CI/CD systems can leverage.

3. **Maintenance Overhead**: Maintaining a custom test framework requires ongoing effort that could be directed toward core MVNimble features.

4. **Missing Test Features**: Advanced features like test fixtures, setup/teardown, test skipping, and parallel execution are not readily available.

5. **Portability Concerns**: Custom test frameworks might behave inconsistently across different environments, complicating cross-platform compatibility efforts.

MVNimble's focus on providing a standardized test optimization utility for Maven projects makes it especially important that we demonstrate best practices in our own testing approach.

## Decision

We will adopt BATS (Bash Automated Testing System) as the standard testing framework for MVNimble. BATS is:

1. **Industry Standard**: A TAP-compliant testing framework specifically designed for Bash scripts with wide adoption in the open source community.

2. **Feature Rich**: Provides test fixtures, setup/teardown functions, skip functionality, and detailed diagnostics.

3. **CI/CD Compatible**: Produces output compatible with CI/CD systems and test harnesses.

4. **Actively Maintained**: Has an active community and regular updates.

5. **Lightweight**: Small footprint and minimal dependencies, making it suitable for various environments.

The implementation will include:

1. **Automatic Installation**: MVNimble will check for BATS installation during setup and offer to install it if missing.

2. **Migration Path**: Gradually migrate existing tests to BATS while maintaining backward compatibility.

3. **Test Taxonomy**: Organize tests logically based on MVNimble modules and functionality.

4. **Documentation**: Provide examples and guidelines for creating new BATS tests.

## Consequences

### Positive

- **Improved Test Quality**: BATS provides better isolation between tests and more detailed failure information.
- **Reduced Maintenance**: Using a standard framework reduces the code we need to maintain ourselves.
- **Better CI/CD Integration**: TAP-compliance makes integration with various CI/CD tools seamless.
- **Enhanced Developer Experience**: Developers familiar with BATS can immediately contribute to MVNimble testing.
- **Consistency**: BATS enforces a consistent testing pattern across the codebase.
- **Faster Feedback**: Better diagnostics and test organization provide faster feedback to developers.

### Negative

- **Learning Curve**: Team members not familiar with BATS will need to learn it.
- **Migration Effort**: Existing tests will need to be migrated to the new framework.
- **Additional Dependency**: Introduces an external dependency, although a minimal one.
- **Potential Performance Overhead**: BATS may have minor performance overhead compared to minimal test scripts.

### Neutral

- **Changed Test Structure**: Test files will follow BATS conventions rather than our custom format.
- **Parallel Testing Considerations**: Requires careful design of tests to ensure they function correctly when run in parallel.

## Implementation Notes

1. **Installation Process**:
   ```bash
   # Check for BATS installation
   if ! command -v bats >/dev/null 2>&1; then
     echo "BATS is not installed. Would you like to install it? [y/N]"
     read -r response
     if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
       # Install BATS
       git clone https://github.com/bats-core/bats-core.git
       cd bats-core
       ./install.sh /usr/local
     fi
   fi
   ```

2. **Test Structure**:
   ```bash
   #!/usr/bin/env bats

   load test_helper
   
   setup() {
     # Test setup code
   }
   
   teardown() {
     # Test cleanup code
   }
   
   @test "verify environment detection works" {
     run detect_operating_system
     [ "$status" -eq 0 ]
     [[ "$output" == "macos" || "$output" == "linux" ]]
   }
   ```

3. **Integration with Existing Tests**:
   - Create a `bats/` directory within the test directory for new BATS tests
   - Provide a compatibility layer for running both old-style tests and BATS tests
   - Gradually migrate tests from the custom format to BATS

4. **CI/CD Integration**:
   - Configure CI pipelines to recognize and process BATS output
   - Use BATS' `--tap` option to produce TAP-compliant output
   - Leverage test formatters for better visualization of results

5. **Test Helpers**:
   - Create common test helpers for MVNimble-specific test needs
   - Implement shared setup/teardown functions for test consistency

By adopting BATS, MVNimble will align with industry standards for Bash testing, reduce maintenance overhead, and improve the developer experience while maintaining the high quality and reliability standards expected from a test optimization utility.

---
Copyright (C) 2025 Eric C. Mumford (@heymumford) Code covered by MIT license
