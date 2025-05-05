#!/usr/bin/env bash
# Script to install MVNimble and apply fixes to analyze.sh

set -e

# Path configurations
MVNIMBLE_SOURCE="/Users/vorthruna/Code/mvnimble"
MVNIMBLE_INSTALL="/Users/vorthruna/mvnimble-install"

# Colors for terminal output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
BOLD='\033[1m'
RESET='\033[0m'

echo -e "${BOLD}${BLUE}=== MVNimble Installation with Fixes ===${RESET}"

# Create clean installation directory
echo -e "\n${BOLD}${BLUE}Step 1: Preparing installation directory${RESET}"
[ -d "$MVNIMBLE_INSTALL" ] && rm -rf "$MVNIMBLE_INSTALL"
mkdir -p "$MVNIMBLE_INSTALL"
echo -e "${GREEN}✓ Created clean installation directory${RESET}"

# Install MVNimble
echo -e "\n${BOLD}${BLUE}Step 2: Installing MVNimble${RESET}"
"$MVNIMBLE_SOURCE/install-simple.sh" --prefix="$MVNIMBLE_INSTALL" --non-interactive --skip-tests

# Apply fixes to analyze.sh
echo -e "\n${BOLD}${BLUE}Step 3: Applying fixes to analyze.sh${RESET}"
ANALYZE_SH="${MVNIMBLE_INSTALL}/lib/analyze.sh"

# Make a backup
cp "$ANALYZE_SH" "${ANALYZE_SH}.backup"
echo -e "${GREEN}✓ Created backup: ${ANALYZE_SH}.backup${RESET}"

# Fix line 241: bash echo mvn: command not found
# We need to escape the mvn command
sed -i.tmp '239s/echo "mvn -T/echo "\\\\mvn -T/' "$ANALYZE_SH"

# Fix line 255: plugin: No such file or directory
# We need to escape the XML tags
sed -i.tmp '245s/echo "<plugin>"/echo "<\\\\plugin>"/' "$ANALYZE_SH"
sed -i.tmp '253s/echo "<\/plugin>"/echo "<\\\\\/plugin>"/' "$ANALYZE_SH"

# Fix line 260: @Category: command not found
# We need to escape the @ symbol
sed -i.tmp '260s/echo "3. Use `@Category`/echo "3. Use \`\\\\@Category\`/' "$ANALYZE_SH"

# Fix line 462: forkCount: No such file or directory
# We need to escape the XML tags in the POM analysis section
sed -i.tmp '457s/echo "   <forkCount>/echo "   <\\\\forkCount>/' "$ANALYZE_SH"
sed -i.tmp '458s/echo "   <reuseForks>/echo "   <\\\\reuseForks>/' "$ANALYZE_SH"
sed -i.tmp '459s/echo "   <parallel>/echo "   <\\\\parallel>/' "$ANALYZE_SH"
sed -i.tmp '460s/echo "   <threadCount>/echo "   <\\\\threadCount>/' "$ANALYZE_SH"

# Fix line 467: argLine: No such file or directory
sed -i.tmp '465s/echo "   <argLine>/echo "   <\\\\argLine>/' "$ANALYZE_SH"

# Fix line 473: groups: No such file or directory
sed -i.tmp '470s/echo "   <groups>/echo "   <\\\\groups>/' "$ANALYZE_SH"
sed -i.tmp '471s/echo "   <excludedGroups>/echo "   <\\\\excludedGroups>/' "$ANALYZE_SH"

# Also fix other XML tags in the Surefire Configuration section
sed -i.tmp '246s/echo "  <groupId>/echo "  <\\\\groupId>/' "$ANALYZE_SH"
sed -i.tmp '247s/echo "  <artifactId>/echo "  <\\\\artifactId>/' "$ANALYZE_SH"
sed -i.tmp '248s/echo "  <configuration>/echo "  <\\\\configuration>/' "$ANALYZE_SH"
sed -i.tmp '249s/echo "    <forkCount>/echo "    <\\\\forkCount>/' "$ANALYZE_SH"
sed -i.tmp '250s/echo "    <reuseForks>/echo "    <\\\\reuseForks>/' "$ANALYZE_SH"
sed -i.tmp '251s/echo "    <argLine>/echo "    <\\\\argLine>/' "$ANALYZE_SH"
sed -i.tmp '252s/echo "  <\/configuration>/echo "  <\\\\\/configuration>/' "$ANALYZE_SH"

# Clean up
rm -f "${ANALYZE_SH}.tmp"
echo -e "${GREEN}✓ Fixed analyze.sh${RESET}"

echo -e "\n${BOLD}${GREEN}Installation Complete!${RESET}"
echo -e "MVNimble installed with fixes at: ${MVNIMBLE_INSTALL}"
echo -e "You can now run commands like:"
echo -e "  ${MVNIMBLE_INSTALL}/bin/mvnimble --help"
echo -e "  ${MVNIMBLE_INSTALL}/bin/mvnimble verify"