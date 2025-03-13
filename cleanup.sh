#!/bin/bash
# Cleanup script for the repository

# Remove temporary debugging files
rm -f TROUBLESHOOTING.md
rm -f DEBUG_NOTES.md
rm -f scripts/commit-no-sign.sh

# Remove test node pool configuration if it still exists
rm -f test_node_pool.tf

# Create scripts directory if it doesn't exist
mkdir -p scripts

echo "Repository cleanup complete!"
