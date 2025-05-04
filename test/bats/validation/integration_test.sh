#!/usr/bin/env bash
# Copyright (C) 2025 Eric C. Mumford (@heymumford) Code covered by MIT license
#
# Integration Test for MVNimble Validation Framework
#
# This script integrates all validation components and runs a comprehensive
# validation test of MVNimble's capabilities across all dimensions.

# Source common libraries
source "$(dirname "$(dirname "$0")")/test_helper.bash"

# Source individual validation scripts
source "$(dirname "$0")/closed_loop/closed_loop_validation.sh"
source "$(dirname "$0")/gold_standard/gold_standard_validation.sh"
source "$(dirname "$0")/thread_safety/thread_safety_validation.sh"
source "$(dirname "$0")/educational/educational_effectiveness_validation.sh"
source "$(dirname "$0")/monitoring/monitoring_validation.sh"

# Constants
VALIDATION_REPORT_DIR="$(dirname "$0")/reports"
COMPREHENSIVE_REPORT="${VALIDATION_REPORT_DIR}/comprehensive_validation_report.md"

#######################################
# Creates the necessary directory structure for integration testing
# Arguments:
#   None
# Outputs:
#   None
#######################################
function setup_integration_environment() {
  mkdir -p "${VALIDATION_REPORT_DIR}"
  
  # Set up individual validation environments
  setup_closed_loop_environment
  setup_gold_standard_environment
  setup_thread_safety_environment
  setup_educational_environment
  
  # Setup monitoring environment (if needed)
  mkdir -p "${ROOT_DIR}/results/validation/monitoring"
}

#######################################
# Runs a comprehensive validation test across all dimensions
# Arguments:
#   None
# Outputs:
#   Summary of validation results
#######################################
function run_comprehensive_validation() {
  local start_time=$(date +%s)
  
  echo "Running Comprehensive MVNimble Validation..."
  echo "============================================"
  
  # Track results from each validation component
  local closed_loop_result
  local gold_standard_result
  local thread_safety_result
  local educational_result
  local monitoring_result
  
  # Run closed-loop validation
  echo "Running Closed-Loop Validation..."
  closed_loop_result=$(run_closed_loop_validation)
  echo "Closed-Loop Validation complete. Result: ${closed_loop_result}%"
  echo ""
  
  # Run gold standard validation
  echo "Running Gold Standard Validation..."
  gold_standard_result=$(run_gold_standard_validation)
  echo "Gold Standard Validation complete. Result: ${gold_standard_result}%"
  echo ""
  
  # Run thread safety validation
  echo "Running Thread Safety Validation..."
  thread_safety_result=$(run_thread_safety_validation)
  echo "Thread Safety Validation complete. Result: ${thread_safety_result}%"
  echo ""
  
  # Run educational effectiveness validation
  echo "Running Educational Effectiveness Validation..."
  educational_result=$(run_educational_validation)
  echo "Educational Effectiveness Validation complete. Result: ${educational_result}%"
  echo ""
  
  # Run monitoring validation (platform test only for integration)
  echo "Running Monitoring Validation..."
  # We use the platform test which doesn't require Maven
  run_validation "platform" > /dev/null
  
  # Get the results from the validation log
  if [ -f "${ROOT_DIR}/results/validation/monitoring/validation_results.log" ]; then
    monitoring_result=$(grep "Overall Validation Score:" "${ROOT_DIR}/results/validation/monitoring/validation_results.log" | grep -o "[0-9]\+/[0-9]\+ ([0-9]\+%)" | grep -o "[0-9]\+%" | grep -o "[0-9]\+")
  else
    monitoring_result=0
  fi
  echo "Monitoring Validation complete. Result: ${monitoring_result}%"
  echo ""
  
  # Calculate overall validation score (weighted average)
  local overall_score=$(echo "scale=2; (${closed_loop_result} * 0.30 + ${gold_standard_result} * 0.20 + ${thread_safety_result} * 0.20 + ${educational_result} * 0.15 + ${monitoring_result} * 0.15)" | bc)
  
  # Track end time and calculate duration
  local end_time=$(date +%s)
  local duration=$((end_time - start_time))
  
  # Generate comprehensive validation report
  generate_comprehensive_report "${closed_loop_result}" "${gold_standard_result}" "${thread_safety_result}" "${educational_result}" "${monitoring_result}" "${overall_score}" "${duration}"
  
  echo "Comprehensive Validation Summary"
  echo "================================"
  echo "Closed-Loop Validation: ${closed_loop_result}%"
  echo "Gold Standard Validation: ${gold_standard_result}%"
  echo "Thread Safety Validation: ${thread_safety_result}%"
  echo "Educational Effectiveness: ${educational_result}%"
  echo "Real-time Monitoring: ${monitoring_result}%"
  echo "Overall Validation Score: ${overall_score}%"
  echo "Validation Duration: ${duration} seconds"
  echo ""
  echo "Comprehensive report generated: ${COMPREHENSIVE_REPORT}"
  
  # Return overall validation score
  echo "${overall_score}"
}

#######################################
# Generates a comprehensive validation report
# Arguments:
#   $1 - Closed-loop validation result
#   $2 - Gold standard validation result
#   $3 - Thread safety validation result
#   $4 - Educational effectiveness result
#   $5 - Real-time monitoring result
#   $6 - Overall validation score
#   $7 - Validation duration in seconds
# Outputs:
#   None
#######################################
function generate_comprehensive_report() {
  local closed_loop_result="$1"
  local gold_standard_result="$2"
  local thread_safety_result="$3"
  local educational_result="$4"
  local monitoring_result="$5"
  local overall_score="$6"
  local duration="$7"
  
  # Determine overall status
  local status="NEEDS IMPROVEMENT"
  if (( $(echo "${overall_score} >= 90" | bc -l) )); then
    status="EXCELLENT"
  elif (( $(echo "${overall_score} >= 80" | bc -l) )); then
    status="GOOD"
  elif (( $(echo "${overall_score} >= 70" | bc -l) )); then
    status="SATISFACTORY"
  fi
  
  # Create report
  cat > "${COMPREHENSIVE_REPORT}" << EOF
# Comprehensive MVNimble Validation Report

## Overview
- **Date**: $(date -u +"%Y-%m-%d %H:%M:%S UTC")
- **Overall Status**: ${status}
- **Overall Score**: ${overall_score}%
- **Validation Duration**: ${duration} seconds ($(echo "scale=2; ${duration}/60" | bc) minutes)

## Summary by Validation Dimension

### Closed-Loop Validation (35% weight)
- **Score**: ${closed_loop_result}%
- **Purpose**: Validates MVNimble's ability to provide recommendations that lead to actual improvements
- **Details**: [Full Closed-Loop Validation Report](../closed_loop/reports/summary_report.md)

### Gold Standard Validation (25% weight)
- **Score**: ${gold_standard_result}%
- **Purpose**: Validates MVNimble's recommendations against expert-derived optimal configurations
- **Details**: [Full Gold Standard Validation Report](../gold_standard/reports/summary_report.md)

### Thread Safety Validation (25% weight)
- **Score**: ${thread_safety_result}%
- **Purpose**: Validates MVNimble's ability to detect and diagnose thread safety issues
- **Details**: [Full Thread Safety Validation Report](../thread_safety/reports/summary_report.md)

### Educational Effectiveness (15% weight)
- **Score**: ${educational_result}%
- **Purpose**: Validates MVNimble's ability to effectively educate users about test flakiness
- **Details**: [Full Educational Effectiveness Report](../educational/reports/educational_summary.md)

### Real-time Monitoring (15% weight)
- **Score**: ${monitoring_result}%
- **Purpose**: Validates MVNimble's "Test Engineering Tricorder" capabilities for real-time monitoring
- **Details**: [Full Monitoring Validation Report](../monitoring/validation_results.log)

## Strengths and Weaknesses

### Strengths
$(
  # Identify the highest scoring dimension
  local max_score=0
  local max_dimension=""
  
  if (( $(echo "${closed_loop_result} > ${max_score}" | bc -l) )); then
    max_score="${closed_loop_result}"
    max_dimension="Closed-Loop Validation"
  fi
  
  if (( $(echo "${gold_standard_result} > ${max_score}" | bc -l) )); then
    max_score="${gold_standard_result}"
    max_dimension="Gold Standard Validation"
  fi
  
  if (( $(echo "${thread_safety_result} > ${max_score}" | bc -l) )); then
    max_score="${thread_safety_result}"
    max_dimension="Thread Safety Validation"
  fi
  
  if (( $(echo "${educational_result} > ${max_score}" | bc -l) )); then
    max_score="${educational_result}"
    max_dimension="Educational Effectiveness"
  fi
  
  if (( $(echo "${monitoring_result} > ${max_score}" | bc -l) )); then
    max_score="${monitoring_result}"
    max_dimension="Real-time Monitoring"
  fi
  
  echo "- **${max_dimension}** (${max_score}%): MVNimble's strongest dimension"
  
  case "${max_dimension}" in
    "Closed-Loop Validation")
      echo "  - Provides recommendations that lead to significant performance improvements"
      echo "  - Accurately predicts improvement magnitudes"
      echo "  - Successfully optimizes test execution across multiple dimensions"
      ;;
    "Gold Standard Validation")
      echo "  - Recommendations closely match expert-derived solutions"
      echo "  - Provides optimal configurations for various test scenarios"
      echo "  - Demonstrates strong understanding of best practices"
      ;;
    "Thread Safety Validation")
      echo "  - Effectively detects thread safety issues in tests"
      echo "  - Provides accurate diagnoses of concurrency problems"
      echo "  - Recommends appropriate solutions for thread-related flakiness"
      ;;
    "Educational Effectiveness")
      echo "  - Clearly explains complex concepts to users"
      echo "  - Effectively transfers knowledge about test flakiness"
      echo "  - Provides actionable recommendations with good educational value"
      ;;
    "Real-time Monitoring")
      echo "  - Effectively monitors system and test execution in real-time"
      echo "  - Provides insightful analysis of resource usage and test patterns"
      echo "  - Detects flakiness patterns and correlates them with resource usage"
      ;;
  esac
)

### Areas for Improvement
$(
  # Identify the lowest scoring dimension
  local min_score=100
  local min_dimension=""
  
  if (( $(echo "${closed_loop_result} < ${min_score}" | bc -l) )); then
    min_score="${closed_loop_result}"
    min_dimension="Closed-Loop Validation"
  fi
  
  if (( $(echo "${gold_standard_result} < ${min_score}" | bc -l) )); then
    min_score="${gold_standard_result}"
    min_dimension="Gold Standard Validation"
  fi
  
  if (( $(echo "${thread_safety_result} < ${min_score}" | bc -l) )); then
    min_score="${thread_safety_result}"
    min_dimension="Thread Safety Validation"
  fi
  
  if (( $(echo "${educational_result} < ${min_score}" | bc -l) )); then
    min_score="${educational_result}"
    min_dimension="Educational Effectiveness"
  fi
  
  if (( $(echo "${monitoring_result} < ${min_score}" | bc -l) )); then
    min_score="${monitoring_result}"
    min_dimension="Real-time Monitoring"
  fi
  
  echo "- **${min_dimension}** (${min_score}%): MVNimble's weakest dimension"
  
  case "${min_dimension}" in
    "Closed-Loop Validation")
      echo "  - Improve accuracy of performance improvement predictions"
      echo "  - Enhance multi-dimensional optimization capabilities"
      echo "  - Better handle complex test environments with multiple constraints"
      ;;
    "Gold Standard Validation")
      echo "  - Recommendations need to more closely match expert solutions"
      echo "  - Improve configuration recommendations for certain test scenarios"
      echo "  - Better align with industry best practices"
      ;;
    "Thread Safety Validation")
      echo "  - Enhance detection of subtle thread safety issues"
      echo "  - Improve diagnosis accuracy for complex concurrency problems"
      echo "  - Provide more specific recommendations for thread-related flakiness"
      ;;
    "Educational Effectiveness")
      echo "  - Improve clarity of explanations for complex concepts"
      echo "  - Enhance knowledge transfer effectiveness"
      echo "  - Make recommendations more actionable for users"
      ;;
    "Real-time Monitoring")
      echo "  - Improve resource correlation analysis accuracy"
      echo "  - Enhance cross-platform compatibility for monitoring functions"
      echo "  - Provide more granular real-time insights during test execution"
      ;;
  esac
)

## Overall Assessment

MVNimble's validation results indicate a $(if (( $(echo "${overall_score} >= 90" | bc -l) )); then echo "very strong"; elif (( $(echo "${overall_score} >= 80" | bc -l) )); then echo "strong"; elif (( $(echo "${overall_score} >= 70" | bc -l) )); then echo "moderate"; else echo "basic"; fi) ability to diagnose test flakiness issues and provide valuable recommendations. The tool demonstrates $(if (( $(echo "${closed_loop_result} >= 80" | bc -l) )); then echo "strong"; else echo "reasonable"; fi) performance in providing recommendations that lead to actual improvements, with recommendations that $(if (( $(echo "${gold_standard_result} >= 80" | bc -l) )); then echo "closely"; else echo "somewhat"; fi) match expert-derived solutions.

MVNimble $(if (( $(echo "${thread_safety_result} >= 80" | bc -l) )); then echo "excels at"; else echo "adequately handles"; fi) detecting and diagnosing thread safety issues, its educational effectiveness is $(if (( $(echo "${educational_result} >= 80" | bc -l) )); then echo "excellent"; else echo "acceptable"; fi), and its real-time monitoring capabilities are $(if (( $(echo "${monitoring_result} >= 80" | bc -l) )); then echo "highly effective"; else echo "developing"; fi).

## Recommendations for MVNimble Improvement

1. **Focus Areas**
   - Primary focus should be on improving ${min_dimension}
   - Continue to build on strengths in ${max_dimension}

2. **Specific Enhancements**
   - Improve diagnosis accuracy for complex scenarios
   - Enhance recommendation specificity and actionability
   - Strengthen educational components to better transfer knowledge
   - Expand test coverage for diverse test environments

3. **Development Priorities**
   - Address the weaknesses identified in the individual validation reports
   - Strengthen integration between diagnostic and recommendation components
   - Enhance user experience for better information transfer
   - Develop more comprehensive test scenarios for future validation

## Validation Methodology

This comprehensive validation employed a multi-dimensional approach:

1. **Closed-Loop Validation**: Testing if MVNimble's recommendations lead to actual improvements
2. **Gold Standard Validation**: Comparing recommendations against expert-derived solutions
3. **Thread Safety Validation**: Evaluating detection and diagnosis of concurrency issues
4. **Educational Effectiveness**: Assessing knowledge transfer and explanation quality
5. **Real-time Monitoring**: Validating the "Test Engineering Tricorder" capabilities

Each dimension used specific metrics and test scenarios to provide a holistic view of MVNimble's capabilities.

## Next Steps

- Address identified improvement areas in priority order
- Conduct user studies to validate real-world effectiveness
- Expand validation test scenarios to cover more edge cases
- Re-run validation after implementing improvements
- Establish continuous validation as part of the development process

---

Report generated on $(date -u +"%Y-%m-%d") by the MVNimble Comprehensive Validation Framework
EOF
}

# Main function
function main() {
  # Set up integration environment
  setup_integration_environment
  
  # Create test scenarios for each validation dimension
  create_closed_loop_scenarios
  create_standard_gold_scenarios
  create_all_scenarios # Thread safety scenarios
  create_standard_scenarios # Educational scenarios
  
  # Run comprehensive validation
  run_comprehensive_validation
}

# Allow sourcing without executing
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi