#!/bin/bash
set -e

# ZMK Local Build Script for Ubuntu
# Builds firmware based on build.yaml configuration

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_DIR="${SCRIPT_DIR}"
BUILD_DIR="${SCRIPT_DIR}/build"
OUTPUT_DIR="${SCRIPT_DIR}/firmware"

echo "=== ZMK Firmware Build Script ==="
echo ""

# Check for dependencies
check_dependencies() {
    echo "Checking dependencies..."
    local missing_deps=()

    command -v git >/dev/null 2>&1 || missing_deps+=("git")
    command -v python3 >/dev/null 2>&1 || missing_deps+=("python3")
    command -v uv >/dev/null 2>&1 || missing_deps+=("uv")
    command -v cmake >/dev/null 2>&1 || missing_deps+=("cmake")
    command -v dtc >/dev/null 2>&1 || missing_deps+=("device-tree-compiler")
    command -v wget >/dev/null 2>&1 || missing_deps+=("wget")
    command -v tar >/dev/null 2>&1 || missing_deps+=("tar")
    command -v xz >/dev/null 2>&1 || missing_deps+=("xz-utils")

    if [ ${#missing_deps[@]} -ne 0 ]; then
        echo "Missing dependencies: ${missing_deps[*]}"
        echo "Install with: sudo apt-get install ${missing_deps[*]}"
        exit 1
    fi

    echo "All dependencies found."
}

# Setup Zephyr SDK
setup_zephyr_sdk() {
    local SDK_VERSION="0.16.8"
    local SDK_DIR="${HOME}/.local/zephyr-sdk-${SDK_VERSION}"

    if [ -d "${SDK_DIR}" ]; then
        echo "Zephyr SDK ${SDK_VERSION} already installed at ${SDK_DIR}"
        return 0
    fi

    echo "Installing Zephyr SDK ${SDK_VERSION}..."

    local SDK_FILE="zephyr-sdk-${SDK_VERSION}_linux-x86_64.tar.xz"
    local SDK_URL="https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v${SDK_VERSION}/${SDK_FILE}"

    cd /tmp

    if [ ! -f "${SDK_FILE}" ]; then
        echo "Downloading Zephyr SDK..."
        wget -q --show-progress "${SDK_URL}"
    fi

    echo "Extracting Zephyr SDK..."
    mkdir -p "${HOME}/.local"
    tar -xvf "${SDK_FILE}" -C "${HOME}/.local"

    echo "Setting up Zephyr SDK..."
    cd "${SDK_DIR}"
    ./setup.sh -t arm-zephyr-eabi -c

    rm -f "/tmp/${SDK_FILE}"

    echo "Zephyr SDK installed successfully"
}

# Setup west workspace
setup_workspace() {
    echo "Setting up west workspace..."
    cd "${WORKSPACE_DIR}"

    # Ensure Python dependencies are installed
    uv sync

    # Initialize west workspace from config directory if not already done
    if [ ! -f ".west/config" ]; then
        echo "Initializing west workspace from config directory..."
        uv run west init -l config
    fi

    echo "Updating west workspace..."
    uv run west update --fetch-opt=--filter=tree:0
    uv run west zephyr-export
}

# Build firmware for a specific board/shield combination
build_firmware() {
    local board="$1"
    local shield="$2"
    local snippet="$3"
    local cmake_args="$4"

    echo ""
    echo "Building: board=${board}, shield=${shield}"

    local build_name="${board}"
    [ -n "${shield}" ] && build_name="${build_name}-${shield// /_}"

    local build_path="${BUILD_DIR}/${build_name}"

    # Prepare build command
    local west_args="-s zmk/app -d ${build_path} -p -b ${board}"
    local extra_cmake_args="-DZMK_CONFIG=${WORKSPACE_DIR}/config"

    if [ -n "${shield}" ]; then
        extra_cmake_args="${extra_cmake_args} -DSHIELD=\"${shield}\""
    fi

    if [ -n "${snippet}" ]; then
        west_args="${west_args} -S \"${snippet}\""
    fi

    if [ -n "${cmake_args}" ]; then
        extra_cmake_args="${extra_cmake_args} ${cmake_args}"
    fi

    # Activate the uv virtual environment so all subprocess calls use it
    source "${WORKSPACE_DIR}/.venv/bin/activate"

    echo "Running: cd ${WORKSPACE_DIR} && west build ${west_args} -- ${extra_cmake_args}"
    cd "${WORKSPACE_DIR}"
    eval west build ${west_args} -- ${extra_cmake_args}

    # Copy firmware to output directory
    mkdir -p "${OUTPUT_DIR}"

    local uf2_file="${build_path}/zephyr/zmk.uf2"
    if [ -f "${uf2_file}" ]; then
        local output_name="${build_name}.uf2"
        cp "${uf2_file}" "${OUTPUT_DIR}/${output_name}"
        echo "✓ Firmware saved: ${OUTPUT_DIR}/${output_name}"
    else
        echo "⚠ Warning: UF2 file not found at ${uf2_file}"
    fi
}

# Main build process
main() {
    check_dependencies
    setup_zephyr_sdk
    setup_workspace

    echo ""
    echo "=== Building firmware configurations ==="

    # Build left side with studio
    build_firmware "nice_nano_v2" "corne_left nice_view_adapter nice_view" "studio-rpc-usb-uart" ""

    # Build right side
    build_firmware "nice_nano_v2" "corne_right nice_view_adapter nice_view" "" ""

    # Build settings reset
    build_firmware "nice_nano_v2" "settings_reset" "" ""

    echo ""
    echo "=== Build Complete ==="
    echo "Firmware files are in: ${OUTPUT_DIR}/"
    ls -lh "${OUTPUT_DIR}/"
}

main "$@"