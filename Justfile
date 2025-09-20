# Clean component target directories to avoid permission issues
clean-test-components:
    rm -rf examples/fetch-rs/target/
    rm -rf examples/filesystem-rs/target/

# Pre-build test components to avoid building during test execution
build-test-components:
    just clean-test-components
    (cd examples/fetch-rs && cargo build --release --target wasm32-wasip2)
    (cd examples/filesystem-rs && cargo build --release --target wasm32-wasip2)

test:
    just build-test-components
    cargo test --workspace -- --nocapture
    cargo test --doc --workspace -- --nocapture

build mode="debug":
    mkdir -p bin
    cargo build --workspace {{ if mode == "release" { "--release" } else { "" } }}
    cp target/{{ mode }}/wassette bin/
    
build-examples mode="debug":
    mkdir -p bin
    (cd examples/fetch-rs && just build mode)
    (cd examples/filesystem-rs && just build mode)
    (cd examples/get-weather-js && just build)
    (cd examples/time-server-js && just build)
    (cd examples/eval-py && just build)
    (cd examples/gomodule-go && just build)
    cp examples/fetch-rs/target/wasm32-wasip2/{{ mode }}/fetch_rs.wasm bin/fetch-rs.wasm
    cp examples/filesystem-rs/target/wasm32-wasip2/{{ mode }}/filesystem.wasm bin/filesystem.wasm
    cp examples/get-weather-js/weather.wasm bin/get-weather-js.wasm
    cp examples/time-server-js/time.wasm bin/time-server-js.wasm
    cp examples/eval-py/eval.wasm bin/eval-py.wasm
    cp examples/gomodule-go/gomodule.wasm bin/gomodule.wasm
    
clean:
    cargo clean
    rm -rf bin

component2json path="examples/fetch-rs/target/wasm32-wasip2/release/fetch_rs.wasm":
    cargo run --bin component2json -p component2json -- {{ path }}

run RUST_LOG='info':
    RUST_LOG={{RUST_LOG}} cargo run --bin wassette serve --sse

run-streamable RUST_LOG='info':
    RUST_LOG={{RUST_LOG}} cargo run --bin wassette serve --streamable-http

run-filesystem RUST_LOG='info':
    RUST_LOG={{RUST_LOG}} cargo run --bin wassette serve --sse --plugin-dir ./examples/filesystem-rs

# Requires an openweather API key in the environment variable OPENWEATHER_API_KEY
run-get-weather RUST_LOG='info':
    RUST_LOG={{RUST_LOG}} cargo run --bin wassette serve --sse --plugin-dir ./examples/get-weather-js

run-fetch-rs RUST_LOG='info':
    RUST_LOG={{RUST_LOG}} cargo run --bin wassette serve --sse --plugin-dir ./examples/fetch-rs

# Documentation commands
docs-build:
    cd docs && mdbook build

docs-serve:
    cd docs && mdbook serve --open

docs-watch:
    cd docs && mdbook serve

# Development Environment Commands

# Show available development commands
dev-help:
    @echo "🚀 Wassette Development Commands"
    @echo ""
    @echo "📋 Setup:"
    @echo "  just dev-check       - Check development prerequisites"
    @echo "  just rust-setup      - Set up Rust development environment"
    @echo "  just act-install     - Install act tool for local CI"
    @echo ""
    @echo "🧪 Local CI Testing (matches GitHub exactly):"
    @echo "  just act-lint        - Run linting checks"
    @echo "  just act-build       - Run build and tests"
    @echo "  just act-security    - Run security audits"
    @echo "  just act-rust-all    - Run all Rust workflow jobs"
    @echo ""
    @echo "⚡ Quick Development:"
    @echo "  just test            - Run core tests (fast)"
    @echo "  just build           - Build project"
    @echo "  just clean           - Clean build artifacts"
    @echo ""
    @echo "🔧 Utilities:"
    @echo "  just act-clean       - Clean up act containers"
    @echo "  just dev-help        - Show this help"

# Check if development prerequisites are installed
dev-check:
    @echo "🔍 Checking development prerequisites..."
    @command -v act >/dev/null 2>&1 || (echo "❌ act not installed. Run: just act-install" && exit 1)
    @command -v docker >/dev/null 2>&1 || (echo "❌ Docker not installed. Please install Docker: https://docs.docker.com/get-docker/" && exit 1)
    @command -v cargo >/dev/null 2>&1 || (echo "❌ Rust/Cargo not installed. Run: just rust-setup" && exit 1)
    @rustup target list --installed | grep -q wasm32-wasip2 || (echo "❌ wasm32-wasip2 target not installed. Run: rustup target add wasm32-wasip2" && exit 1)
    @echo "✅ All prerequisites are installed!"

# Set up Rust development environment
rust-setup:
    @echo "🦀 Setting up Rust development environment..."
    @echo "Checking nightly toolchain..."
    @rustup toolchain list | grep -q nightly || rustup toolchain install nightly --component rustfmt
    @echo "Checking wasm32-wasip2 target..."
    @rustup target list --installed | grep -q wasm32-wasip2 || rustup target add wasm32-wasip2
    @echo "Checking cargo tools..."
    @command -v cargo-machete >/dev/null 2>&1 || cargo install cargo-machete
    @command -v cargo-audit >/dev/null 2>&1 || cargo install cargo-audit
    @command -v cargo-deny >/dev/null 2>&1 || cargo install cargo-deny
    @command -v typos >/dev/null 2>&1 || cargo install typos-cli
    @echo "✅ Rust development environment ready!"

# Act commands - run GitHub CI locally using act (github.com/nektos/act)
# Each command corresponds to a specific job in .github/workflows/rust.yml
# Uses --rm to automatically clean up containers after each run
#
# To test against your own fork:
# just act-lint-fork github.com/yourusername/wassette
# just act-build-fork github.com/yourusername/wassette

# Install act tool for running GitHub Actions locally
act-install:
    @echo "Installing act (GitHub Actions runner)..."
    @echo "Note: For security, the install script will be downloaded for your review before running with sudo."
    tmpfile=$(mktemp /tmp/act-install.XXXXXX.sh) && \
    curl -fsSL https://raw.githubusercontent.com/nektos/act/master/install.sh -o "$tmpfile" && \
    echo "Downloaded install script to $tmpfile" && \
    echo "SHA256 checksum:" && sha256sum "$tmpfile" && \
    echo "Please review the script before running:" && \
    echo "    less $tmpfile" && \
    echo "To install, run:" && \
    echo "    sudo bash $tmpfile"

act-license-headers:
    act -W ./.github/workflows/rust.yml -j license-headers --rm

act-lint:
    act -W ./.github/workflows/rust.yml -j lint --rm

act-build:
    act -W ./.github/workflows/rust.yml -j build --rm

act-deps:
    act -W ./.github/workflows/rust.yml -j deps --rm

act-security:
    act -W ./.github/workflows/rust.yml -j security --rm

act-coverage:
    act -W ./.github/workflows/rust.yml -j coverage --rm

act-spelling:
    act -W ./.github/workflows/rust.yml -j spelling --rm

act-linkChecker:
    act -W ./.github/workflows/rust.yml -j linkChecker --rm

# Run examples workflow
act-examples:
    act -W ./.github/workflows/examples.yml --rm

# Run all rust workflow jobs
act-rust-all:
    act -W ./.github/workflows/rust.yml --rm

# Run all workflows
act-all:
    act -W ./.github/workflows/rust.yml --rm
    act -W ./.github/workflows/examples.yml --rm

# Fork-specific commands for testing custom repositories
act-license-headers-fork repo:
    act -W ./.github/workflows/rust.yml -j license-headers --rm --env GITHUB_REPOSITORY={{repo}}

act-lint-fork repo:
    act -W ./.github/workflows/rust.yml -j lint --rm --env GITHUB_REPOSITORY={{repo}}

act-build-fork repo:
    act -W ./.github/workflows/rust.yml -j build --rm --env GITHUB_REPOSITORY={{repo}}

act-deps-fork repo:
    act -W ./.github/workflows/rust.yml -j deps --rm --env GITHUB_REPOSITORY={{repo}}

act-security-fork repo:
    act -W ./.github/workflows/rust.yml -j security --rm --env GITHUB_REPOSITORY={{repo}}

act-coverage-fork repo:
    act -W ./.github/workflows/rust.yml -j coverage --rm --env GITHUB_REPOSITORY={{repo}}

act-spelling-fork repo:
    act -W ./.github/workflows/rust.yml -j spelling --rm --env GITHUB_REPOSITORY={{repo}}

act-linkChecker-fork repo:
    act -W ./.github/workflows/rust.yml -j linkChecker --rm --env GITHUB_REPOSITORY={{repo}}

# Run examples workflow against fork
act-examples-fork repo:
    act -W ./.github/workflows/examples.yml --rm --env GITHUB_REPOSITORY={{repo}}

# Run all rust workflow jobs against fork
act-rust-all-fork repo:
    act -W ./.github/workflows/rust.yml --rm --env GITHUB_REPOSITORY={{repo}}

# Run all workflows against fork
act-all-fork repo:
    act -W ./.github/workflows/rust.yml --rm --env GITHUB_REPOSITORY={{repo}}
    act -W ./.github/workflows/examples.yml --rm --env GITHUB_REPOSITORY={{repo}}

# Clean up any stuck act containers
act-clean:
    @echo "Current act containers:"
    -docker ps --filter "name=act-"
    @echo "Stopping and removing act containers..."
    -docker stop $(docker ps -q --filter "name=act-") 2>/dev/null || true
    -docker rm $(docker ps -aq --filter "name=act-") 2>/dev/null || true
    @echo "Act containers cleaned up."
