cmake_minimum_required(VERSION 3.26.4)

project(_kernels LANGUAGES CUDA CXX)

# Configure compilers for different platforms.  When building on Windows
# the build system expects to use MSVC/CL and a number of paths are
# supplied through environment variables.  On other platforms we fall
# back to the previous GCC based toolchain.
if(WIN32)
  set(Python_EXECUTABLE $ENV{Python_EXECUTABLE} CACHE FILEPATH "")
  set(Python_LIBRARIES $ENV{Python_LIBRARIES} CACHE FILEPATH "")
  set(CUDA_HOME $ENV{CUDA_HOME} CACHE PATH "")
  set(CUDA_NVCC_EXECUTABLE $ENV{CUDA_NVCC_EXECUTABLE} CACHE FILEPATH "")
  set(CMAKE_C_COMPILER $ENV{CMAKE_C_COMPILER} CACHE FILEPATH "")
  set(CMAKE_CXX_COMPILER $ENV{CMAKE_CXX_COMPILER} CACHE FILEPATH "")
  set(CMAKE_LINKER "$(VCInstallDir)Tools/MSVC/$(VCToolsVersion)/bin/Host$(Platform)/$(PlatformTarget)/link.exe" CACHE FILEPATH "" FORCE)
else()
  set(CMAKE_C_COMPILER "/usr/bin/gcc-11")
  set(CMAKE_CXX_COMPILER "/usr/bin/g++-11")
endif()


set(CMAKE_C_STANDARD 17)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CUDA_STANDARD 17)
set(CMAKE_CUDA_ARCHITECTURES 90a)

# Check: https://stackoverflow.com/questions/68401650/how-can-i-make-a-pytorch-extension-with-cmake
# Fix linking error: https://github.com/pytorch/pytorch/issues/108041
find_package(Python REQUIRED COMPONENTS Interpreter Development)
find_package(Torch REQUIRED)
find_library(TORCH_PYTHON_LIBRARY torch_python PATH "${TORCH_INSTALL_PREFIX}/lib")

# Try combine pybind
# Check: https://qiita.com/syoyo/items/c3e8e6e5c3e2d69c2325
add_subdirectory(${CMAKE_SOURCE_DIR}/3rdparty/pybind ${CMAKE_BINARY_DIR}/pybind11)

file(GLOB PYTORCH_SOURCES "csrc/*.cu")
pybind11_add_module(_kernels MODULE ${PYTORCH_SOURCES})

# Add dependency libraries
target_include_directories(_kernels PRIVATE ${CMAKE_SOURCE_DIR}/3rdparty/cutlass/include)
target_include_directories(_kernels PRIVATE ${CMAKE_SOURCE_DIR}/3rdparty/pybind/include)
target_include_directories(_kernels PRIVATE ${CMAKE_SOURCE_DIR}/3rdparty/flashinfer/include)

# Add customized kernel impl
target_include_directories(_kernels PRIVATE ${CMAKE_SOURCE_DIR}/include)

target_compile_options(_kernels PRIVATE 
    $<$<COMPILE_LANGUAGE:CUDA>:
        --expt-extended-lambda 
        --expt-relaxed-constexpr
        --use_fast_math
        --disable-warnings
    >
    $<$<COMPILE_LANGUAGE:CXX>:-w>
)

if(WIN32)
  get_filename_component(PYTHON_LIBRARY_DIR "${Python_LIBRARIES}" DIRECTORY)
  target_link_directories(_kernels PRIVATE "${PYTHON_LIBRARY_DIR}" "${TORCH_INSTALL_PREFIX}/lib")
endif()
target_link_libraries(
    _kernels PRIVATE ${TORCH_LIBRARIES} ${Python_LIBRARIES} pybind11::module
    ${TORCH_PYTHON_LIBRARY})