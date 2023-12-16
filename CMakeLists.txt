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

# /////////////////////////////////////////////////////////////////////////////////////////////////
# //
# //   EXTRA SOURCES
# //
# /////////////////////////////////////////////////////////////////////////////////////////////////
# file(GLOB_RECURSE MY_SOURCES src/*.c) ...
# include_directories(inc)

# Include PEPB
include(cmake/PEPB/PEPBRootInit.cmake)

# Create CubeMX lib
pepb_stm32_create_target(CUBEMX_DIR ${CUBEMX_PROJECT_DIR}
                         TARGET_NAME ${PROJECT_NAME}
                         CPU_TYPE ${STM32_CPU_TYPE}
                         #EXTRA_SOURCES ${MY_SOURCES}
)
# Flashing
pepb_add_download_target(${PROJECT_NAME})