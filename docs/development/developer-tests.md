# Developer Testing Guide

This guide covers local development testing for Wassette, including CI parity testing and development environment setup.

## Quick Start

```bash
# Check prerequisites
just dev-check

# Set up development environment (one-time setup)
just rust-setup

# Install act for local CI testing (one-time setup)
just act-install

# Run local CI tests (matches GitHub exactly)
just act-lint
just act-build
```

## Overview

Wassette provides comprehensive local testing tools that ensure perfect parity between local development and GitHub CI. This prevents CI failures by catching issues before pushing code.

### Key Benefits

- **Perfect CI Parity**: Uses exact same GitHub Actions workflows locally
- **Zero Configuration Drift**: Always uses latest `.github/workflows/rust.yml`
- **Fork Testing**: Test against custom repositories and feature branches
- **Developer Experience**: Easy installation and clear commands
- **Automatic Cleanup**: Containers are automatically removed after use

## Prerequisites

### Required Tools

- **Docker**: For running containerized CI environments
- **Rust/Cargo**: For building and testing Rust code
- **act**: For running GitHub Actions locally (can be installed via `just act-install`)

### Rust Targets

- `wasm32-wasip2`: Required for WebAssembly component builds

## Development Environment Setup

### One-Time Setup

```bash
# Check what's installed
just dev-check

# Set up complete Rust development environment
just rust-setup

# Install act tool for local CI testing
just act-install
```

The `rust-setup` command installs:
- Nightly Rust toolchain with rustfmt
- `wasm32-wasip2` target for WebAssembly builds
- Additional tools: `cargo-machete`, `cargo-audit`, `cargo-deny`, `typos-cli`

## Local CI Testing

### Individual CI Jobs

Run specific GitHub Actions jobs locally:

```bash
# Linting (rustfmt + clippy)
just act-lint

# Build and test
just act-build

# Security audits
just act-security

# Dependency checks
just act-deps

# Coverage analysis
just act-coverage

# Spell checking
just act-spelling

# Link checking
just act-linkChecker

# License header validation
just act-license-headers
```

### Workflow Testing

```bash
# Run all Rust workflow jobs
just act-rust-all

# Run examples workflow
just act-examples

# Run all workflows
just act-all
```

## Fork and Branch Testing

Test against custom repositories or feature branches:

```bash
# Test against your fork
just act-lint-fork github.com/yourusername/wassette

# Test against a specific branch (set up remote first)
git remote add feature-branch https://github.com/username/wassette
just act-build-fork github.com/username/wassette
```

### Available Fork Commands

All CI jobs have corresponding fork variants:

- `act-lint-fork repo`
- `act-build-fork repo`
- `act-security-fork repo`
- `act-deps-fork repo`
- `act-coverage-fork repo`
- `act-spelling-fork repo`
- `act-linkChecker-fork repo`
- `act-license-headers-fork repo`
- `act-examples-fork repo`
- `act-rust-all-fork repo`
- `act-all-fork repo`

## Quick Development Testing

For rapid development iteration:

```bash
# Fast local tests (no containers)
just test

# Build project
just build

# Clean build artifacts
just clean
```

These commands run faster than full CI simulation but may not catch all CI-specific issues.

## Container Management

### Automatic Cleanup

All `act-*` commands use the `--rm` flag for automatic container cleanup.

### Manual Cleanup

```bash
# Clean up any stuck act containers
just act-clean

# View current act containers
docker ps --filter "name=act-"
```

## Troubleshooting

### Common Issues

**act not found**
```bash
# Install act via justfile
just act-install

# Or install manually
curl https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash
```

**Docker permission denied**
```bash
# Add user to docker group (requires logout/login)
sudo usermod -aG docker $USER
```

**wasm32-wasip2 target missing**
```bash
# Install WebAssembly target
rustup target add wasm32-wasip2
```

**Containers not cleaning up**
```bash
# Force cleanup
just act-clean

# Check Docker space usage
docker system df
```

### Performance Tips

1. **Use individual job commands** (`just act-lint`) instead of full workflows for faster feedback
2. **Run `just test` first** for quick validation before CI simulation
3. **Use fork commands** to test against feature branches without switching locally

## Integration with IDE

Most IDEs can run Justfile commands directly:

- **VS Code**: Use the "Just" extension
- **IntelliJ/CLion**: Use the "Just" plugin
- **Command Line**: `just dev-help` for available commands

## CI Workflow Mapping

| Justfile Command | GitHub Actions Job | Purpose |
|------------------|-------------------|---------|
| `act-lint` | `lint` | Code formatting and linting |
| `act-build` | `build` | Build and test execution |
| `act-security` | `security` | Security vulnerability scans |
| `act-deps` | `deps` | Dependency analysis |
| `act-coverage` | `coverage` | Test coverage reporting |
| `act-spelling` | `spelling` | Spell checking |
| `act-linkChecker` | `linkChecker` | Documentation link validation |
| `act-license-headers` | `license-headers` | License header compliance |

## Development Workflow

### Recommended Flow

1. **Start with quick tests**: `just test`
2. **Run relevant CI job**: `just act-lint` or `just act-build`
3. **Before pushing**: `just act-rust-all`
4. **For documentation changes**: `just act-spelling && just act-linkChecker`

### Feature Branch Workflow

```bash
# Create feature branch
git checkout -b feature/new-feature

# Develop and test locally
just test

# Test against your fork before creating PR
just act-build-fork github.com/yourusername/wassette

# Final validation
just act-rust-all
```

This ensures your changes work correctly before submitting a pull request.