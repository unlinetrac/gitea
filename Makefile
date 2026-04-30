# Makefile for Gitea
# Provides common development, build, and test targets

.PHONY: all build clean test lint fmt vet run generate help

# Go parameters
GOCMD   := go
GOBUILD := $(GOCMD) build
GOCLEAN := $(GOCMD) clean
GOTEST  := $(GOCMD) test
GOGET   := $(GOCMD) get
GOFMT   := gofmt
GOVET   := $(GOCMD) vet
GOLINT  := golangci-lint

# Build parameters
BINARY_NAME    := gitea
BINARY_UNIX    := $(BINARY_NAME)_unix
MAIN_PKG       := ./cmd/gitea
BUILD_FLAGS    := -v
LD_FLAGS       := -s -w
VERSION        ?= $(shell git describe --tags --always --dirty 2>/dev/null || echo "dev")
GIT_COMMIT     ?= $(shell git rev-parse --short HEAD 2>/dev/null || echo "unknown")
BUILD_DATE     ?= $(shell date -u +"%Y-%m-%dT%H:%M:%SZ")

# Inject version info at build time
LD_FLAGS_FULL  := $(LD_FLAGS) \
	-X main.Version=$(VERSION) \
	-X main.GitCommit=$(GIT_COMMIT) \
	-X main.BuildDate=$(BUILD_DATE)

## all: Build the binary (default target)
all: build

## build: Compile the application
build:
	@echo ">> Building $(BINARY_NAME) $(VERSION)..."
	$(GOBUILD) $(BUILD_FLAGS) -ldflags "$(LD_FLAGS_FULL)" -o $(BINARY_NAME) $(MAIN_PKG)

## build-linux: Cross-compile for Linux amd64
build-linux:
	@echo ">> Cross-compiling for Linux..."
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
		$(GOBUILD) $(BUILD_FLAGS) -ldflags "$(LD_FLAGS_FULL)" -o $(BINARY_UNIX) $(MAIN_PKG)

## run: Run the application with air for live reloading
run:
	@echo ">> Starting development server..."
	air

## test: Run all unit tests
test:
	@echo ">> Running tests..."
	$(GOTEST) -v -race -coverprofile=coverage.out ./...

## test-short: Run tests excluding long-running integration tests
test-short:
	@echo ">> Running short tests..."
	$(GOTEST) -short -v ./...

## coverage: Generate and display test coverage report
coverage: test
	@echo ">> Generating coverage report..."
	$(GOCMD) tool cover -html=coverage.out -o coverage.html
	@echo "Coverage report written to coverage.html"

## lint: Run linter
lint:
	@echo ">> Running linter..."
	$(GOLINT) run ./...

## fmt: Format source code
fmt:
	@echo ">> Formatting code..."
	$(GOFMT) -s -w .

## vet: Run go vet
vet:
	@echo ">> Running go vet..."
	$(GOVET) ./...

## generate: Run go generate
generate:
	@echo ">> Running go generate..."
	$(GOCMD) generate ./...

## tidy: Tidy go modules
tidy:
	@echo ">> Tidying modules..."
	$(GOCMD) mod tidy

## clean: Remove build artifacts
clean:
	@echo ">> Cleaning..."
	$(GOCLEAN)
	rm -f $(BINARY_NAME) $(BINARY_UNIX) coverage.out coverage.html

## help: Display this help message
help:
	@echo "Usage: make [target]"
	@echo ""
	@grep -E '^## ' $(MAKEFILE_LIST) | sed 's/## /  /' | column -t -s ':'
