cmake_minimum_required(VERSION 3.24)

# /////////////////////////////////////////////////////////////////////////////////////////////////
# //
# //   GENERAL CONFIGURATIONS
# //
# /////////////////////////////////////////////////////////////////////////////////////////////////
project(YOUR_PROJECT LANGUAGES C CXX ASM)
set(CUBEMX_PROJECT_DIR YOUR_CUBEMX_PROJECT)
set(STM32_CPU_TYPE cortex-m4)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_C_STANDARD 11)

# Generic compiler settings
add_compile_options($<$<COMPILE_LANGUAGE:C,CXX>:-mthumb>)
add_compile_options($<$<COMPILE_LANGUAGE:C,CXX>:-mthumb-interwork>)
add_compile_options($<$<COMPILE_LANGUAGE:C,CXX>:-ffunction-sections>)
add_compile_options($<$<COMPILE_LANGUAGE:C,CXX>:-fdata-sections>)
add_compile_options($<$<COMPILE_LANGUAGE:C,CXX>:-fno-common>)
add_compile_options($<$<COMPILE_LANGUAGE:C,CXX>:-fmessage-length=0>)
add_link_options(-mthumb -mthumb-interwork)
add_link_options(-Wl,-gc-sections,--print-memory-usage)

# Build types
if ("${CMAKE_BUILD_TYPE}" STREQUAL "Release")
    message(STATUS "Maximum optimization for speed")
    add_compile_options(-Ofast)
elseif ("${CMAKE_BUILD_TYPE}" STREQUAL "RelWithDebInfo")
    message(STATUS "Maximum optimization for speed, debug info included")
    add_compile_options(-Ofast -g)
elseif ("${CMAKE_BUILD_TYPE}" STREQUAL "MinSizeRel")
    message(STATUS "Maximum optimization for size")
    add_compile_options(-Os)
else ()
    message(STATUS "Minimal optimization, debug info included")
    add_compile_options(-Og -g)
endif ()

# Enable hardware FPU
add_compile_definitions($<$<COMPILE_LANGUAGE:C,CXX>:ARM_MATH_MATRIX_CHECK>)
add_compile_definitions($<$<COMPILE_LANGUAGE:C,CXX>:ARM_MATH_ROUNDING>)
add_compile_options(-mfloat-abi=hard -mfpu=fpv4-sp-d16)
add_link_options(-mfloat-abi=hard -mfpu=fpv4-sp-d16)

# /////////////////////////////////////////////////////////////////////////////////////////////////
# //
# //   Add your sources and libraries HERE, and don't forget to add them to
# //   the add_executable() & target_link_libraries() command below
# //   include_directories(lib/libfoo) # Assuming its CMakeLists will set linking option variables for you
# //
# /////////////////////////////////////////////////////////////////////////////////////////////////
# file(GLOB_RECURSE MY_SOURCES src/*.c) ...

# Add subroutines
list(APPEND CMAKE_MODULE_PATH ${PROJECT_SOURCE_DIR}/cmake)
include(CubeMx)
include(OpenOcdFlashing)

# Create CubeMX lib
stm32_create_target(CUBEMX_DIR ${CUBEMX_PROJECT_DIR}
                    TARGET_NAME ${PROJECT_NAME}.elf
                    CPU_TYPE ${STM32_CPU_TYPE}
                    # EXTRA_SOURCES ${MY_SOURCES}
)

# Create Hex & Bin
stm32_create_hex(${PROJECT_NAME})

# Flashing
pepb_add_download_target(${PROJECT_NAME})
