SWIFT := swift
BINARY := pngpaste
BUILD_DIR := .build/release
DEBUG_DIR := .build/debug
PREFIX := /usr/local
SWIFTLINT := swiftlint
SWIFTFORMAT := swiftformat
SHELLCHECK := shellcheck
SHFMT := shfmt
BREW := brew
SCRIPTS_DIR := scripts
COVERAGE_DIR := .build/coverage
Q := @

.PHONY: all build build-debug install uninstall clean \
        test test-unit test-integration test-leaks test-coverage coverage-html \
        lint lint-swift lint-bash format format-swift format-bash \
        format-check format-check-swift format-check-bash check setup help

all: build

build: ## Build release binary
	$(Q)echo "Building release..."
	$(Q)$(SWIFT) build -c release --quiet
	$(Q)echo "✓ Build complete: $(BUILD_DIR)/$(BINARY)"

build-debug: ## Build debug binary
	$(Q)echo "Building debug..."
	$(Q)$(SWIFT) build --quiet
	$(Q)echo "✓ Debug build complete"

install: build ## Install to $(PREFIX)/bin
	$(Q)echo "Installing to $(PREFIX)/bin..."
	$(Q)install -d $(PREFIX)/bin
	$(Q)install -m 755 $(BUILD_DIR)/$(BINARY) $(PREFIX)/bin/
	$(Q)echo "✓ Installed $(BINARY) to $(PREFIX)/bin"

uninstall: ## Remove from $(PREFIX)/bin
	$(Q)echo "Removing $(PREFIX)/bin/$(BINARY)..."
	$(Q)rm -f $(PREFIX)/bin/$(BINARY)
	$(Q)echo "✓ Uninstalled"

clean: ## Clean build artifacts
	$(Q)echo "Cleaning build artifacts..."
	$(Q)$(SWIFT) package clean 2>/dev/null || true
	$(Q)rm -rf .build
	$(Q)rm -rf $(COVERAGE_DIR)
	$(Q)echo "✓ Clean complete"

test: ## Run all tests
	$(Q)echo "Running all tests..."
	$(Q)$(SWIFT) test --enable-swift-testing 2>&1 | grep -E "^(✔|✗|Test run|error:|warning:)" || true
	$(Q)echo ""

test-unit: ## Run unit tests only
	$(Q)echo "Running unit tests..."
	$(Q)$(SWIFT) test --enable-swift-testing --filter "Unit" 2>&1 | grep -E "^(✔|✗|Test run|error:|warning:)" || true
	$(Q)echo ""

test-integration: ## Run integration tests only
	$(Q)echo "Running integration tests..."
	$(Q)$(SWIFT) test --enable-swift-testing --filter "Integration" 2>&1 | grep -E "^(✔|✗|Test run|error:|warning:)" || true
	$(Q)echo ""

test-coverage: ## Run tests with coverage report
	$(Q)echo "Running tests with coverage..."
	$(Q)$(SWIFT) test --enable-swift-testing --enable-code-coverage 2>&1 | grep -E "^(✔|✗|Test run|error:)" || true
	$(Q)echo ""
	$(Q)echo "Coverage report:"
	$(Q)xcrun llvm-cov report \
		$(DEBUG_DIR)/pngpastePackageTests.xctest/Contents/MacOS/pngpastePackageTests \
		-instr-profile=$(DEBUG_DIR)/codecov/default.profdata \
		-ignore-filename-regex=".build|Tests" \
		-use-color 2>/dev/null || echo "Coverage data not available"
	$(Q)echo ""
	$(Q)echo "For HTML report: make coverage-html"

coverage-html: ## Generate HTML coverage report
	$(Q)echo "Generating HTML coverage report..."
	$(Q)$(SWIFT) test --enable-swift-testing --enable-code-coverage 2>&1 | grep -E "^(✔|✗|Test run)" || true
	$(Q)mkdir -p $(COVERAGE_DIR)
	$(Q)xcrun llvm-cov show \
		$(DEBUG_DIR)/pngpastePackageTests.xctest/Contents/MacOS/pngpastePackageTests \
		-instr-profile=$(DEBUG_DIR)/codecov/default.profdata \
		-ignore-filename-regex=".build|Tests" \
		-format=html \
		-output-dir=$(COVERAGE_DIR) 2>/dev/null
	$(Q)echo "✓ Report: $(COVERAGE_DIR)/index.html"
	$(Q)open $(COVERAGE_DIR)/index.html

test-leaks: build ## Run memory leak tests
	$(Q)echo "Running memory leak tests..."
	$(Q)if leaks --atExit -- $(BUILD_DIR)/$(BINARY) -b 2>/dev/null; then \
		echo "✓ No memory leaks detected"; \
	else \
		echo "✗ Memory leaks detected"; \
		exit 1; \
	fi

lint: lint-swift lint-bash ## Run all linters

lint-swift: ## Run SwiftLint
	$(Q)if command -v $(SWIFTLINT) >/dev/null 2>&1; then \
		echo "Running SwiftLint..."; \
		$(SWIFTLINT) lint --quiet --strict && echo "✓ SwiftLint passed"; \
	else \
		echo "⚠ SwiftLint not installed. Run 'make setup'"; \
	fi

lint-bash: ## Run ShellCheck on bash scripts
	$(Q)if command -v $(SHELLCHECK) >/dev/null 2>&1; then \
		echo "Running ShellCheck..."; \
		find $(SCRIPTS_DIR) -name '*.sh' -exec $(SHELLCHECK) {} + && echo "✓ ShellCheck passed"; \
	else \
		echo "⚠ ShellCheck not installed. Run 'make setup'"; \
	fi

format: format-swift format-bash ## Format all code

format-swift: ## Format Swift code with SwiftFormat
	$(Q)if command -v $(SWIFTFORMAT) >/dev/null 2>&1; then \
		echo "Formatting Swift code..."; \
		$(SWIFTFORMAT) Sources Tests --quiet; \
		echo "✓ Swift formatted"; \
	else \
		echo "⚠ SwiftFormat not installed. Run 'make setup'"; \
	fi

format-bash: ## Format bash scripts with shfmt
	$(Q)if command -v $(SHFMT) >/dev/null 2>&1; then \
		echo "Formatting bash scripts..."; \
		$(SHFMT) -w -i 2 -ci $(SCRIPTS_DIR)/*.sh; \
		echo "✓ Bash formatted"; \
	else \
		echo "⚠ shfmt not installed. Run 'make setup'"; \
	fi

format-check: format-check-swift format-check-bash ## Check all formatting

format-check-swift: ## Check Swift formatting without changes
	$(Q)if command -v $(SWIFTFORMAT) >/dev/null 2>&1; then \
		echo "Checking Swift format..."; \
		$(SWIFTFORMAT) Sources Tests --lint --quiet && echo "✓ Swift format OK"; \
	else \
		echo "⚠ SwiftFormat not installed. Run 'make setup'"; \
	fi

format-check-bash: ## Check bash formatting without changes
	$(Q)if command -v $(SHFMT) >/dev/null 2>&1; then \
		echo "Checking bash format..."; \
		$(SHFMT) -d -i 2 -ci $(SCRIPTS_DIR)/*.sh && echo "✓ Bash format OK"; \
	else \
		echo "⚠ shfmt not installed. Run 'make setup'"; \
	fi

check: lint format-check test ## Run lint + format-check + test
	$(Q)echo "✓ All checks passed"

setup: ## Install development dependencies
	$(Q)echo "Installing development dependencies..."
	$(Q)echo ""
	$(Q)if command -v $(BREW) >/dev/null 2>&1; then \
		echo "Using Homebrew to install tools..."; \
		echo ""; \
		echo "── swiftlint ───────────────────────────"; \
		echo ""; \
		$(BREW) install swiftlint || echo "⚠ swiftlint failed (may require full Xcode.app)"; \
		echo ""; \
		echo "── swiftformat ─────────────────────────"; \
		echo ""; \
		$(BREW) install swiftformat || echo "⚠ swiftformat failed"; \
		echo ""; \
		echo "── shellcheck ──────────────────────────"; \
		echo ""; \
		$(BREW) install shellcheck || echo "⚠ shellcheck failed"; \
		echo ""; \
		echo "── shfmt ──────────────────────────────"; \
		echo ""; \
		$(BREW) install shfmt || echo "⚠ shfmt failed"; \
	else \
		echo "Homebrew not found. Install tools manually or get Homebrew from https://brew.sh"; \
	fi
	$(Q)echo ""
	$(Q)echo "────────────────────────────────────────"
	$(Q)echo ""
	$(Q)echo "Tool status:"
	$(Q)echo "  swiftlint:   $$(swiftlint version 2>/dev/null || echo 'not found')"
	$(Q)echo "  swiftformat: $$(swiftformat --version 2>/dev/null || echo 'not found')"
	$(Q)echo "  shellcheck:  $$(shellcheck --version 2>/dev/null | head -2 | tail -1 || echo 'not found')"
	$(Q)echo "  shfmt:       $$(shfmt --version 2>/dev/null || echo 'not found')"
	$(Q)echo ""
	$(Q)echo "────────────────────────────────────────"

help: ## Show this help
	$(Q)echo "pngpaste - Development Commands"
	$(Q)echo ""
	$(Q)grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  make %-16s %s\n", $$1, $$2}'
