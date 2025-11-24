#!/bin/bash

# verify_cuda.sh
# Comprehensive CUDA 13.0 System Installation Verification Script
# For Ubuntu 25.04 with NVIDIA Tesla T4 GPU

echo "======================================================================"
echo "CUDA 13.0 System Installation Verification"
echo "Ubuntu 25.04 | NVIDIA Tesla T4 GPU"
echo "======================================================================"
echo ""

# Color codes for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Success/failure counters
PASSED=0
FAILED=0

# Function to print success
print_success() {
    echo -e "${GREEN}✓${NC} $1"
    ((PASSED++))
}

# Function to print failure
print_failure() {
    echo -e "${RED}✗${NC} $1"
    ((FAILED++))
}

# Function to print warning
print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# ======================================================================
# Test 1: GPU Detection
# ======================================================================
echo "[1/10] Checking GPU detection..."
if lspci | grep -i nvidia | grep -i "Tesla T4" > /dev/null 2>&1; then
    print_success "GPU detected: NVIDIA Tesla T4"
elif lspci | grep -i nvidia > /dev/null 2>&1; then
    GPU_NAME=$(lspci | grep -i nvidia | head -1 | cut -d':' -f3)
    print_warning "GPU detected but not Tesla T4:$GPU_NAME"
    ((PASSED++))
else
    print_failure "No NVIDIA GPU detected"
fi
echo ""

# ======================================================================
# Test 2: NVIDIA Driver
# ======================================================================
echo "[2/10] Checking NVIDIA driver..."
if command -v nvidia-smi &> /dev/null; then
    DRIVER_VERSION=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>/dev/null)
    if [ -n "$DRIVER_VERSION" ]; then
        print_success "NVIDIA driver loaded: Version $DRIVER_VERSION"
        nvidia-smi --query-gpu=name,driver_version,memory.total --format=csv,noheader
    else
        print_failure "nvidia-smi found but driver not loaded"
    fi
else
    print_failure "nvidia-smi not found - NVIDIA driver not installed"
fi
echo ""

# ======================================================================
# Test 3: CUDA Compiler (nvcc)
# ======================================================================
echo "[3/10] Checking CUDA compiler (nvcc)..."
if command -v nvcc &> /dev/null; then
    NVCC_VERSION=$(nvcc --version | grep "release" | awk '{print $5}' | cut -d',' -f1)
    NVCC_PATH=$(which nvcc)
    print_success "nvcc found: Version $NVCC_VERSION at $NVCC_PATH"
else
    print_failure "nvcc not found - CUDA toolkit not installed"
fi
echo ""

# ======================================================================
# Test 4: libdevice.10.bc
# ======================================================================
echo "[4/10] Checking libdevice.10.bc..."
LIBDEVICE_PATH="/usr/lib/nvidia-cuda-toolkit/libdevice/libdevice.10.bc"
if [ -f "$LIBDEVICE_PATH" ]; then
    LIBDEVICE_SIZE=$(ls -lh "$LIBDEVICE_PATH" | awk '{print $5}')
    print_success "libdevice.10.bc found at: $LIBDEVICE_PATH ($LIBDEVICE_SIZE)"
else
    print_failure "libdevice.10.bc not found at: $LIBDEVICE_PATH"
    # Try to find it elsewhere
    echo "  Searching for libdevice.10.bc..."
    FOUND_LIBDEVICE=$(sudo find /usr -name "libdevice.10.bc" 2>/dev/null | head -1)
    if [ -n "$FOUND_LIBDEVICE" ]; then
        print_warning "Found at alternative location: $FOUND_LIBDEVICE"
    fi
fi
echo ""

# ======================================================================
# Test 5: CUDA Runtime Libraries
# ======================================================================
echo "[5/10] Checking CUDA runtime libraries..."
if [ -f "/usr/lib/x86_64-linux-gnu/libcudart.so" ] || ls /usr/lib/x86_64-linux-gnu/libcudart.so* > /dev/null 2>&1; then
    CUDART_VERSION=$(ls -1 /usr/lib/x86_64-linux-gnu/libcudart.so.* 2>/dev/null | head -1 | grep -oP 'libcudart\.so\.\K[0-9.]+')
    print_success "CUDA runtime libraries found: libcudart.so.$CUDART_VERSION"
else
    print_failure "CUDA runtime libraries not found in /usr/lib/x86_64-linux-gnu/"
fi
echo ""

# ======================================================================
# Test 6: CUDA Toolkit Libraries
# ======================================================================
echo "[6/10] Checking CUDA toolkit libraries..."
if [ -d "/usr/lib/nvidia-cuda-toolkit/lib64" ]; then
    LIB_COUNT=$(ls /usr/lib/nvidia-cuda-toolkit/lib64/*.so 2>/dev/null | wc -l)
    print_success "CUDA toolkit libraries found: $LIB_COUNT libraries in /usr/lib/nvidia-cuda-toolkit/lib64/"
else
    print_failure "CUDA toolkit library directory not found"
fi
echo ""

# ======================================================================
# Test 7: Environment Variables
# ======================================================================
echo "[7/10] Checking environment variables..."

# Check CUDA_HOME
if [ -n "$CUDA_HOME" ]; then
    print_success "CUDA_HOME is set: $CUDA_HOME"
else
    print_failure "CUDA_HOME is not set"
    echo "  Add to ~/.bashrc: export CUDA_HOME=/usr"
fi

# Check CODON_GPU_LIBDEVICE
if [ -n "$CODON_GPU_LIBDEVICE" ]; then
    if [ -f "$CODON_GPU_LIBDEVICE" ]; then
        print_success "CODON_GPU_LIBDEVICE is set and file exists: $CODON_GPU_LIBDEVICE"
    else
        print_failure "CODON_GPU_LIBDEVICE is set but file doesn't exist: $CODON_GPU_LIBDEVICE"
    fi
else
    print_failure "CODON_GPU_LIBDEVICE is not set"
    echo "  Add to ~/.bashrc: export CODON_GPU_LIBDEVICE=/usr/lib/nvidia-cuda-toolkit/libdevice/libdevice.10.bc"
fi

# Check LD_LIBRARY_PATH
if echo "$LD_LIBRARY_PATH" | grep -q "cuda\|nvidia"; then
    print_success "LD_LIBRARY_PATH includes CUDA paths"
else
    print_warning "LD_LIBRARY_PATH may not include CUDA paths"
    echo "  Current LD_LIBRARY_PATH: $LD_LIBRARY_PATH"
fi
echo ""

# ======================================================================
# Test 8: Codon Installation
# ======================================================================
echo "[8/10] Checking Codon installation..."
if command -v codon &> /dev/null; then
    CODON_VERSION=$(codon --version 2>&1 | head -1)
    CODON_PATH=$(which codon)
    print_success "Codon installed: $CODON_VERSION at $CODON_PATH"
else
    print_failure "Codon not found in PATH"
    echo "  Install with: /bin/bash -c \"\$(curl -fsSL https://exaloop.io/install.sh)\""
fi
echo ""

# ======================================================================
# Test 9: Test File Exists
# ======================================================================
echo "[9/10] Checking for test file..."
if [ -f "image_blur_codon_gpu_par.codon" ]; then
    FILE_SIZE=$(ls -lh image_blur_codon_gpu_par.codon | awk '{print $5}')
    print_success "Test file exists: image_blur_codon_gpu_par.codon ($FILE_SIZE)"
else
    print_warning "Test file not found: image_blur_codon_gpu_par.codon"
    echo "  You'll need to create this file to test GPU acceleration"
fi
echo ""

# ======================================================================
# Test 10: Overall System Readiness
# ======================================================================
echo "[10/10] Overall system readiness..."
if [ $FAILED -eq 0 ]; then
    print_success "All critical checks passed! System is ready for Codon GPU."
elif [ $FAILED -le 2 ]; then
    print_warning "System mostly ready, but some issues need attention"
else
    print_failure "Multiple issues detected. System not ready for Codon GPU."
fi
echo ""

# ======================================================================
# Summary
# ======================================================================
echo "======================================================================"
echo "VERIFICATION SUMMARY"
echo "======================================================================"
echo -e "Passed: ${GREEN}$PASSED${NC}"
echo -e "Failed: ${RED}$FAILED${NC}"
echo ""

# ======================================================================
# Recommendations
# ======================================================================
if [ $FAILED -gt 0 ]; then
    echo "======================================================================"
    echo "RECOMMENDED ACTIONS"
    echo "======================================================================"
    
    if ! command -v nvidia-smi &> /dev/null; then
        echo "1. Install NVIDIA driver:"
        echo "   sudo ubuntu-drivers autoinstall"
        echo "   sudo reboot"
        echo ""
    fi
    
    if ! command -v nvcc &> /dev/null; then
        echo "2. Install CUDA toolkit:"
        echo "   sudo apt update"
        echo "   sudo apt install -y nvidia-cuda-toolkit"
        echo ""
    fi
    
    if [ -z "$CUDA_HOME" ] || [ -z "$CODON_GPU_LIBDEVICE" ]; then
        echo "3. Configure environment variables in ~/.bashrc:"
        echo "   cat >> ~/.bashrc << 'EOF'"
        echo "   export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:/usr/lib/nvidia-cuda-toolkit/lib64:\$LD_LIBRARY_PATH"
        echo "   export CUDA_HOME=/usr"
        echo "   export CODON_GPU_LIBDEVICE=/usr/lib/nvidia-cuda-toolkit/libdevice/libdevice.10.bc"
        echo "   EOF"
        echo "   source ~/.bashrc"
        echo ""
    fi
    
    if ! command -v codon &> /dev/null; then
        echo "4. Install Codon:"
        echo "   /bin/bash -c \"\$(curl -fsSL https://exaloop.io/install.sh)\""
        echo ""
    fi
else
    echo "======================================================================"
    echo "NEXT STEPS"
    echo "======================================================================"
    echo "Your system is ready! Run the GPU-accelerated program:"
    echo "  codon run image_blur_codon_gpu_par.codon"
    echo ""
fi

echo "======================================================================"

