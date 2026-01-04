#!/usr/bin/env bash
# Pre-Release Validation Script for ahocorasick
# This script runs all quality checks before creating a release

set -e  # Exit on first error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Header
echo ""
echo "================================================"
echo "  ahocorasick - Pre-Release Check"
echo "================================================"
echo ""

# Track overall status
ERRORS=0
WARNINGS=0

# 1. Check Go version
log_info "Checking Go version..."
GO_VERSION=$(go version | awk '{print $3}')
REQUIRED_VERSION="go1.21"
if [[ "$GO_VERSION" < "$REQUIRED_VERSION" ]]; then
    log_error "Go version $REQUIRED_VERSION+ required, found $GO_VERSION"
    ERRORS=$((ERRORS + 1))
else
    log_success "Go version: $GO_VERSION"
fi
echo ""

# 2. Check git status
log_info "Checking git status..."
if git diff-index --quiet HEAD --; then
    log_success "Working directory is clean"
else
    log_warning "Uncommitted changes detected"
    git status --short
    WARNINGS=$((WARNINGS + 1))
fi
echo ""

# 3. Code formatting check
log_info "Checking code formatting..."
UNFORMATTED=$(gofmt -l . 2>/dev/null || true)
if [ -n "$UNFORMATTED" ]; then
    log_error "The following files need formatting:"
    echo "$UNFORMATTED"
    echo ""
    log_info "Run: go fmt ./..."
    ERRORS=$((ERRORS + 1))
else
    log_success "All files are properly formatted"
fi
echo ""

# 4. Go vet
log_info "Running go vet..."
if go vet ./... 2>&1; then
    log_success "go vet passed"
else
    log_error "go vet failed"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# 5. Build
log_info "Building package..."
if go build ./... 2>&1; then
    log_success "Build successful"
else
    log_error "Build failed"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# 6. go.mod validation
log_info "Validating go.mod..."
go mod verify
if [ $? -eq 0 ]; then
    log_success "go.mod verified"
else
    log_error "go.mod verification failed"
    ERRORS=$((ERRORS + 1))
fi

# Check if go.mod needs tidying
cp go.mod go.mod.bak
go mod tidy
if diff -q go.mod go.mod.bak > /dev/null 2>&1; then
    log_success "go.mod is tidy"
else
    log_warning "go.mod needed tidying"
    WARNINGS=$((WARNINGS + 1))
fi
rm -f go.mod.bak
echo ""

# 7. golangci-lint configuration
log_info "Verifying golangci-lint configuration..."
if command -v golangci-lint &> /dev/null; then
    if golangci-lint config verify 2>&1; then
        log_success "golangci-lint config is valid"
    else
        log_error "golangci-lint config is invalid"
        ERRORS=$((ERRORS + 1))
    fi
else
    log_warning "golangci-lint not installed"
    WARNINGS=$((WARNINGS + 1))
fi
echo ""

# 8. Run tests
log_info "Running tests..."
TEST_OUTPUT=$(go test -v ./... 2>&1)
if echo "$TEST_OUTPUT" | grep -q "FAIL"; then
    log_error "Tests failed"
    echo "$TEST_OUTPUT" | grep -E "^(---|FAIL)" | head -20
    ERRORS=$((ERRORS + 1))
else
    PASS_COUNT=$(echo "$TEST_OUTPUT" | grep -c "^--- PASS" || echo "0")
    log_success "All tests passed ($PASS_COUNT tests)"
fi
echo ""

# 9. Test coverage
log_info "Checking test coverage..."
COVERAGE=$(go test -cover ./... 2>&1 | grep "coverage:" | awk '{print $5}' | sed 's/%//')
if [ -n "$COVERAGE" ]; then
    echo "  Coverage: ${COVERAGE}%"
    if awk -v cov="$COVERAGE" 'BEGIN {exit !(cov >= 70.0)}'; then
        log_success "Coverage meets requirement (>70%)"
    else
        log_warning "Coverage below 70% (${COVERAGE}%)"
        WARNINGS=$((WARNINGS + 1))
    fi
else
    log_warning "Could not determine coverage"
    WARNINGS=$((WARNINGS + 1))
fi
echo ""

# 10. golangci-lint
log_info "Running golangci-lint..."
if command -v golangci-lint &> /dev/null; then
    LINT_OUTPUT=$(golangci-lint run --timeout=2m ./... 2>&1)
    LINT_EXIT=$?
    if [ $LINT_EXIT -eq 0 ]; then
        log_success "golangci-lint passed (0 issues)"
    else
        log_error "Linter found issues"
        echo "$LINT_OUTPUT" | tail -10
        ERRORS=$((ERRORS + 1))
    fi
else
    log_error "golangci-lint not installed"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# 11. Check for TODO/FIXME
log_info "Checking for TODO/FIXME comments..."
TODO_COUNT=$(grep -r "TODO\|FIXME" --include="*.go" . 2>/dev/null | wc -l)
TODO_COUNT=${TODO_COUNT:-0}
if [ "$TODO_COUNT" -gt 0 ]; then
    log_warning "Found $TODO_COUNT TODO/FIXME comments"
    grep -r "TODO\|FIXME" --include="*.go" . 2>/dev/null | head -5
    WARNINGS=$((WARNINGS + 1))
else
    log_success "No TODO/FIXME comments found"
fi
echo ""

# 12. Check documentation
log_info "Checking documentation..."
DOCS_MISSING=0
for doc in README.md CHANGELOG.md LICENSE; do
    if [ ! -f "$doc" ]; then
        log_error "Missing: $doc"
        DOCS_MISSING=1
        ERRORS=$((ERRORS + 1))
    fi
done
if [ $DOCS_MISSING -eq 0 ]; then
    log_success "All documentation files present"
fi
echo ""

# 13. Run benchmarks (quick sanity check)
log_info "Running benchmarks (sanity check)..."
BENCH_OUTPUT=$(go test -bench=BenchmarkIsMatchWithMatch -benchtime=100ms -count=1 ./... 2>&1)
if echo "$BENCH_OUTPUT" | grep -q "MB/s"; then
    THROUGHPUT=$(echo "$BENCH_OUTPUT" | grep "MB/s" | awk '{for(i=1;i<=NF;i++) if($i ~ /MB\/s/) print $(i-1)}')
    log_success "Benchmark throughput: ${THROUGHPUT} MB/s"
else
    log_warning "Could not determine benchmark throughput"
    WARNINGS=$((WARNINGS + 1))
fi
echo ""

# Summary
echo "========================================"
echo "  Summary"
echo "========================================"
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    log_success "✅ All checks passed! Ready for release."
    echo ""
    log_info "Next steps:"
    echo "  1. Update CHANGELOG.md with release notes"
    echo "  2. Commit: git add -A && git commit -m 'chore: prepare vX.Y.Z'"
    echo "  3. Tag: git tag -a vX.Y.Z -m 'Release vX.Y.Z'"
    echo "  4. Push: git push origin main --tags"
    echo ""
    exit 0
elif [ $ERRORS -eq 0 ]; then
    log_warning "Checks completed with $WARNINGS warning(s)"
    echo ""
    log_info "Review warnings above before release"
    exit 0
else
    log_error "Checks failed with $ERRORS error(s) and $WARNINGS warning(s)"
    echo ""
    log_error "Fix errors before release"
    exit 1
fi
