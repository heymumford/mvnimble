#!/usr/bin/env bash
# Fixed version of analyze.sh that escapes XML tags and other special syntax

# First find the analyze.sh file in the MVNimble installation and make a backup
MVNIMBLE_INSTALL="/Users/vorthruna/mvnimble-install"
ANALYZE_SH="${MVNIMBLE_INSTALL}/lib/analyze.sh"

if [ ! -f "$ANALYZE_SH" ]; then
  echo "Error: analyze.sh not found at ${ANALYZE_SH}"
  exit 1
fi

# Make a backup
cp "$ANALYZE_SH" "${ANALYZE_SH}.backup"
echo "Created backup: ${ANALYZE_SH}.backup"

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
echo "Fixed analyze.sh at ${ANALYZE_SH}"

# Test the fix by running a simple command from analyze.sh
echo "Testing the fix..."
cd "$MVNIMBLE_INSTALL/lib"
bash -c "source analyze.sh && echo 'Test successful'"
if [ $? -eq 0 ]; then
  echo "✅ Fix was successful"
else
  echo "❌ Fix failed, restoring backup"
  cp "${ANALYZE_SH}.backup" "$ANALYZE_SH"
fi