
# Generic compiler settings
add_compile_options($<$<COMPILE_LANGUAGE:C,CXX>:-marm>)
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
    add_compile_options(-Ofast -gdwarf-4)
elseif ("${CMAKE_BUILD_TYPE}" STREQUAL "MinSizeRel")
    message(STATUS "Maximum optimization for size")
    add_compile_options(-Os)
else ()
    message(STATUS "Minimal optimization, debug info included")
    add_compile_options(-Og -gdwarf-4)
endif ()

# Enable hardware FPU
add_compile_definitions($<$<COMPILE_LANGUAGE:C,CXX>:ARM_MATH_MATRIX_CHECK>)
add_compile_definitions($<$<COMPILE_LANGUAGE:C,CXX>:ARM_MATH_ROUNDING>)
add_compile_options(-mfloat-abi=hard -mfpu=fpv4-sp-d16)
add_link_options(-mfloat-abi=hard -mfpu=fpv4-sp-d16)

# Introduce modules
list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_LIST_DIR})
include(CubeMx)
include(DownloadAndDebug)
include(ClangdDriver)
