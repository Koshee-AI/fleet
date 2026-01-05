#!/bin/bash
# sync-upstream.sh
# Syncs Koshee's Fleet fork with upstream FleetDM
#
# Usage:
#   ./scripts/sync-upstream.sh              # Merge from upstream/main
#   ./scripts/sync-upstream.sh v4.78.0      # Merge specific tag
#
# This script:
# 1. Adds upstream remote if not present
# 2. Fetches upstream changes
# 3. Merges specified branch/tag
# 4. Lists files that commonly have conflicts
#
# After running, manually resolve any conflicts and test before pushing.

set -e

UPSTREAM_URL="https://github.com/fleetdm/fleet.git"
UPSTREAM_REF="${1:-main}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Fleet Upstream Sync ===${NC}"
echo "Upstream URL: ${UPSTREAM_URL}"
echo "Syncing to: ${UPSTREAM_REF}"
echo ""

# Add upstream remote if not exists
if ! git remote get-url upstream &>/dev/null; then
    echo -e "${YELLOW}Adding upstream remote...${NC}"
    git remote add upstream "${UPSTREAM_URL}"
else
    echo "Upstream remote already configured"
fi

# Fetch upstream
echo -e "${YELLOW}Fetching upstream...${NC}"
git fetch upstream --tags

# Check for uncommitted changes
if ! git diff-index --quiet HEAD --; then
    echo -e "${RED}ERROR: You have uncommitted changes. Please commit or stash them first.${NC}"
    exit 1
fi

# Get current branch
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
echo "Current branch: ${CURRENT_BRANCH}"

# Merge upstream
echo -e "${YELLOW}Merging upstream/${UPSTREAM_REF}...${NC}"
if git merge "upstream/${UPSTREAM_REF}" --no-edit; then
    echo -e "${GREEN}Merge successful!${NC}"
else
    echo -e "${YELLOW}Merge has conflicts. Please resolve them manually.${NC}"
    echo ""
    echo "Common Koshee-specific files that may conflict:"
    echo "  - CLAUDE.md"
    echo "  - Dockerfile.multiarch"
    echo "  - .tekton/"
    echo "  - charts/fleet/values.yaml"
    echo "  - charts/fleet/values-koshee.yaml"
    echo "  - charts/fleet/templates/deployment.yaml"
    echo "  - charts/fleet/templates/mysql-backup.yaml"
    echo "  - charts/fleet/templates/cloudflare-tunnel.yaml"
    echo ""
    echo "After resolving conflicts:"
    echo "  1. git add <resolved-files>"
    echo "  2. git commit"
    echo "  3. Test: helm template ./charts/fleet -f charts/fleet/values-koshee.yaml"
    echo "  4. Push to trigger build"
    exit 1
fi

# Show what changed
echo ""
echo -e "${GREEN}=== Sync Complete ===${NC}"
echo "Changes from upstream:"
git log --oneline HEAD~10..HEAD 2>/dev/null | head -10 || true

echo ""
echo "Next steps:"
echo "  1. Review changes: git diff HEAD~1"
echo "  2. Test Helm chart: helm template ./charts/fleet -f charts/fleet/values-koshee.yaml"
echo "  3. Run tests: make test"
echo "  4. Push to trigger build: git push"
