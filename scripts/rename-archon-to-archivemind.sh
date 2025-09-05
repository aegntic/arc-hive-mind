#!/bin/bash

# Script to rename all instances of "archon" to "archivemind" in the codebase
# Usage: ./scripts/rename-archon-to-archivemind.sh

set -e

echo "🔄 Starting comprehensive rename from 'archon' to 'archivemind'..."

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counter for changes
CHANGES_MADE=0

# Function to perform case-sensitive replacements in a file
perform_replacements() {
    local file="$1"
    
    # Skip binary files and git directory
    if [[ "$file" == *".git/"* ]] || [[ "$file" == *"node_modules/"* ]] || file "$file" 2>/dev/null | grep -q "binary"; then
        return
    fi
    
    # Create temp file for safe replacement
    temp_file=$(mktemp)
    
    # Perform replacements with proper case handling
    sed -e 's/\bArchon\b/Archivemind/g' \
        -e 's/\barchon\b/archivemind/g' \
        -e 's/\bARCHON\b/ARCHIVEMIND/g' \
        -e 's/Archon-/Archivemind-/g' \
        -e 's/archon-/archivemind-/g' \
        -e 's/ARCHON_/ARCHIVEMIND_/g' \
        -e 's/archon_/archivemind_/g' \
        -e 's/\.archon\b/.archivemind/g' \
        -e 's/"archon"/"archivemind"/g' \
        -e "s/'archon'/'archivemind'/g" \
        "$file" > "$temp_file" 2>/dev/null || {
        rm -f "$temp_file"
        return
    }
    
    # Only update if changes were made
    if ! cmp -s "$file" "$temp_file" 2>/dev/null; then
        mv "$temp_file" "$file"
        echo -e "${GREEN}✓${NC} Updated: $file"
        ((CHANGES_MADE++))
    else
        rm -f "$temp_file"
    fi
}

# Export function for use with find -exec
export -f perform_replacements
export RED GREEN YELLOW NC CHANGES_MADE

echo -e "${YELLOW}Step 1/4:${NC} Processing text files..."

# Find and process all text files
find . -type f \
    -not -path "./.git/*" \
    -not -path "./node_modules/*" \
    -not -path "./__pycache__/*" \
    -not -path "./dist/*" \
    -not -path "./build/*" \
    -not -name "*.pyc" \
    -not -name "*.pyo" \
    -not -name "*.so" \
    -not -name "*.dylib" \
    -not -name "*.dll" \
    -not -name "*.exe" \
    -not -name "*.bin" \
    -not -name "*.jpg" \
    -not -name "*.jpeg" \
    -not -name "*.png" \
    -not -name "*.gif" \
    -not -name "*.ico" \
    -not -name "*.woff" \
    -not -name "*.woff2" \
    -not -name "*.ttf" \
    -not -name "*.eot" \
    -not -name "*.lock" \
    -not -name "package-lock.json" \
    -exec bash -c 'perform_replacements "$0"' {} \;

echo -e "${YELLOW}Step 2/4:${NC} Renaming directories..."

# Rename directories from bottom-up to avoid path conflicts
find . -depth -type d -name "*archon*" -not -path "./.git/*" -not -path "./node_modules/*" 2>/dev/null | while read dir; do
    newdir=$(echo "$dir" | sed 's/archon/archivemind/g')
    if [ "$dir" != "$newdir" ]; then
        if mv "$dir" "$newdir" 2>/dev/null; then
            echo -e "${GREEN}✓${NC} Renamed directory: $dir → $newdir"
            ((CHANGES_MADE++))
        fi
    fi
done

echo -e "${YELLOW}Step 3/4:${NC} Renaming files..."

# Rename files containing 'archon' in their names
find . -type f -name "*archon*" -not -path "./.git/*" -not -path "./node_modules/*" 2>/dev/null | while read file; do
    newfile=$(echo "$file" | sed 's/archon/archivemind/g')
    if [ "$file" != "$newfile" ]; then
        if mv "$file" "$newfile" 2>/dev/null; then
            echo -e "${GREEN}✓${NC} Renamed file: $file → $newfile"
            ((CHANGES_MADE++))
        fi
    fi
done

echo -e "${YELLOW}Step 4/4:${NC} Verifying changes..."

# Count remaining instances (excluding .git and node_modules)
remaining=$(grep -r -i "archon" . \
    --exclude-dir=.git \
    --exclude-dir=node_modules \
    --exclude-dir=dist \
    --exclude-dir=build \
    --exclude="*.lock" \
    --exclude="package-lock.json" \
    2>/dev/null | wc -l || echo "0")

echo ""
echo "═══════════════════════════════════════════════════════"
echo -e "${GREEN}✅ Rename operation completed!${NC}"
echo "═══════════════════════════════════════════════════════"
echo ""
echo "📊 Statistics:"
echo "   • Files and directories processed: $(find . -not -path "./.git/*" -not -path "./node_modules/*" | wc -l)"
echo "   • Changes made: $CHANGES_MADE"
echo "   • Remaining 'archon' references: $remaining"

if [ "$remaining" -gt 0 ]; then
    echo ""
    echo -e "${YELLOW}⚠️  Warning:${NC} Some references to 'archon' still exist."
    echo "These might be in binary files, locked files, or git history."
    echo ""
    echo "To see them, run:"
    echo "  grep -r -i 'archon' . --exclude-dir=.git --exclude-dir=node_modules"
fi

echo ""
echo "💡 Next steps:"
echo "  1. Review the changes: git diff"
echo "  2. Stage changes: git add -A"
echo "  3. Commit: git commit -m 'Rename archon to archivemind'"
echo "  4. Push to remote: git push origin <branch>"