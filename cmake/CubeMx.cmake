#
# stm32_create_target
#
# REQUIRED
#   CUBEMX_DIR [directory]
#   TARGET_NAME [string.elf]
#   
# OPTIONAL
#   CPU_TYPE [string] (defaults to cortex-m4)
#   EXTRA_SOURCES [list of files]
#

MACRO(stm32_create_target)
    # Parse arguments
    # set(options OPTIONAL FAST)
    set(oneValueArgs CPU_TYPE CUBEMX_DIR TARGET_NAME)
    set(multiValueArgs EXTRA_SOURCES)
    cmake_parse_arguments(CREATETARGET "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    # Argument sanity check
    if(NOT DEFINED CREATETARGET_CUBEMX_DIR)
        message(FATAL_ERROR "stm32_create_target: CUBEMX_DIR not defined")
    endif()

    if(NOT DEFINED CREATETARGET_TARGET_NAME)
        message(FATAL_ERROR "stm32_create_target: TARGET_NAME not defined")
    endif()

    if(NOT DEFINED CREATETARGET_CPU_TYPE)
        message(ERROR "stm32_create_target: CPU_TYPE not defined, using cortex-m4 as default")
        set(CREATETARGET_CPU_TYPE "cortex-m4")
    endif()

    # Set default values
    SET(BOARD_TARGET_DIR "${CMAKE_CURRENT_LIST_DIR}/${CREATETARGET_CUBEMX_DIR}")
    message(STATUS "Create board target: ${CREATETARGET_TARGET_NAME}")

    # Detect linker scripts. Priorities: *_USER.ld, if not found  *_FLASH.ld, if not found first *.ld
    file(GLOB LINKER_SCRIPTS "${BOARD_TARGET_DIR}/*_USER.ld")
    if (NOT LINKER_SCRIPTS)
        file(GLOB LINKER_SCRIPTS "${BOARD_TARGET_DIR}/*_FLASH.ld")
        if (NOT LINKER_SCRIPTS)
            file(GLOB LINKER_SCRIPTS "${BOARD_TARGET_DIR}/*.ld")
        endif ()
    endif ()
    list(GET LINKER_SCRIPTS 0 LINKER_SCRIPT_${CREATETARGET_TARGET_NAME})
    message(STATUS "Detected Linker Script for ${CREATETARGET_TARGET_NAME}: ${LINKER_SCRIPT_${CREATETARGET_TARGET_NAME}}")

    # Read kernel-specific header paths, defines, and sources from Makefile generated by CubeMX
    file(STRINGS ${BOARD_TARGET_DIR}/Makefile LINES)
    foreach (LINE ${LINES})
        # When iterating a file's lines with foreach(LINE ${LINES}), CMake will
        # AUTOMATICALLY concatenate the lines ending with a backslash (\),
        # remove the backslash, and return as a list (each line separated with a semicolon).
        if (LINE MATCHES "^([A-Za-z0-9_]+) *= *")
            if(CMAKE_MATCH_1 STREQUAL "C_SOURCES")
                list(POP_FRONT LINE)
                while(LINE)
                    list(POP_FRONT LINE C_SOURCE_ENTRY)
                    string(STRIP ${C_SOURCE_ENTRY} C_SOURCE_ENTRY)
                    string(PREPEND C_SOURCE_ENTRY "${BOARD_TARGET_DIR}/")
                    list(APPEND SRC_LIST ${C_SOURCE_ENTRY})
                endwhile()
            elseif(CMAKE_MATCH_1 STREQUAL "ASM_SOURCES")
                list(POP_FRONT LINE)
                while(LINE)
                    list(POP_FRONT LINE ASM_SOURCE_ENTRY)
                    string(STRIP ${ASM_SOURCE_ENTRY} ASM_SOURCE_ENTRY)
                    string(PREPEND ASM_SOURCE_ENTRY "${BOARD_TARGET_DIR}/")
                    list(APPEND SRC_LIST ${ASM_SOURCE_ENTRY})
                endwhile()
            elseif(CMAKE_MATCH_1 STREQUAL "C_INCLUDES")
                list(POP_FRONT LINE)
                while(LINE)
                    list(POP_FRONT LINE C_INCLUDE_ENTRY)
                    string(STRIP ${C_INCLUDE_ENTRY} C_INCLUDE_ENTRY)
                    string(REGEX REPLACE "^-I" "" C_INCLUDE_ENTRY ${C_INCLUDE_ENTRY})
                    string(PREPEND C_INCLUDE_ENTRY "${BOARD_TARGET_DIR}/")
                    list(APPEND INCL_LIST ${C_INCLUDE_ENTRY})
                endwhile()
            elseif(CMAKE_MATCH_1 STREQUAL "C_DEFS")
                list(POP_FRONT LINE)
                while(LINE)
                    list(POP_FRONT LINE C_DEFS_ENTRY)
                    string(STRIP ${C_DEFS_ENTRY} C_DEFS_ENTRY)
                    string(REGEX REPLACE "^-D" "" C_DEFS_ENTRY ${C_DEFS_ENTRY})
                    list(APPEND MX_CDEFS ${C_DEFS_ENTRY})
                endwhile()
            endif()
        endif ()
    endforeach ()
    
    # Globbing user sources
    file(GLOB_RECURSE USER_SOURCES "${BOARD_TARGET_DIR}/Core/*.c" "${BOARD_TARGET_DIR}/Core/*.cpp" "${BOARD_TARGET_DIR}/Core/*.h")
    file(GLOB STARTUP_ASM "${BOARD_TARGET_DIR}/*.s")

    # Add CubeMX target
    add_executable(${CREATETARGET_TARGET_NAME} ${SRC_LIST} ${CREATETARGET_EXTRA_SOURCES})
    target_include_directories(${CREATETARGET_TARGET_NAME} PUBLIC ${INCL_LIST})
    target_compile_definitions(${CREATETARGET_TARGET_NAME} PUBLIC $<$<COMPILE_LANGUAGE:C,CXX>:${MX_CDEFS}>)

    # Kernel-specific build settings
    target_compile_options(${CREATETARGET_TARGET_NAME} PUBLIC -mcpu=${CREATETARGET_CPU_TYPE})
    target_link_options(${CREATETARGET_TARGET_NAME} PUBLIC
            -Wl,-Map=${PROJECT_BINARY_DIR}/${PROJECT_NAME}.map -mcpu=${CREATETARGET_CPU_TYPE} -T ${LINKER_SCRIPT_${CREATETARGET_TARGET_NAME}})
ENDMACRO()

function(stm32_create_hex NAME)
    set(HEX_FILE ${PROJECT_BINARY_DIR}/${NAME}.hex)
    set(BIN_FILE ${PROJECT_BINARY_DIR}/${NAME}.bin)
    add_custom_command(TARGET ${NAME}.elf POST_BUILD
            COMMAND ${CMAKE_OBJCOPY} -Oihex $<TARGET_FILE:${NAME}.elf> ${HEX_FILE}
            COMMAND ${CMAKE_OBJCOPY} -Obinary $<TARGET_FILE:${NAME}.elf> ${BIN_FILE}
            COMMENT " Building ${HEX_FILE} Building ${BIN_FILE}")
endfunction()

#
# stm32_fixup_project
# Do necessary post processings to make sure some CubeMX features work automatically
# without user intervention.
#
# REQUIRED
# [TARGET_NAME] Target name, WITHOUT .elf extension
# [CUBEMX_DIR] CubeMX project directory, relative to CMakeLists.txt, usually just directory name
# [CPU_TYPE] CPU type, e.g. cortex-m4
#
function(stm32_fixup_project TARGET_NAME CUBEMX_DIR CPU_TYPE)
    message(STATUS "Fixing up project ${TARGET_NAME}...")

    # Make CubeMX directory absolute
    set(CUBEMX_DIR ${CMAKE_CURRENT_SOURCE_DIR}/${CUBEMX_DIR})

    # //////////////////  DSP Lib  ////////////////////
    if(EXISTS "${CUBEMX_DIR}/Middlewares/ST/ARM/DSP")
        message(STATUS " - You have selected DSP library in CubeMX. Attempting to fixup linkage.")
        file(GLOB_RECURSE DSP_LIB_ARCHIVE "${CUBEMX_DIR}/Middlewares/ST/ARM/DSP/*.a")
        if(DSP_LIB_ARCHIVE)
            message(STATUS " - Found DSP library archive: ${DSP_LIB_ARCHIVE}")
            target_link_libraries(${PROJECT_NAME}.elf PUBLIC ${DSP_LIB_ARCHIVE})

            # Definitions based on CPU type
            # NOTE: Setting __FPU_PRESENT is not needed because stm32f4xxyy.h will do it for us
            if(CPU_TYPE STREQUAL "cortex-m0")
                target_compile_definitions(${PROJECT_NAME}.elf PUBLIC $<$<COMPILE_LANGUAGE:C,CXX>:ARM_MATH_CM0>)
            elseif(CPU_TYPE STREQUAL "cortex-m4")
                target_compile_definitions(${PROJECT_NAME}.elf PUBLIC $<$<COMPILE_LANGUAGE:C,CXX>:ARM_MATH_CM4>)
            elseif(CPU_TYPE STREQUAL "cortex-m7")
                target_compile_definitions(${PROJECT_NAME}.elf PUBLIC $<$<COMPILE_LANGUAGE:C,CXX>:ARM_MATH_CM7>)
            else()
                message(WARNING " - DSP library not supported for CPU type ${CPU_TYPE}. Please contact PEPB author.")
            endif()
        else()
            message(WARNING " - DSP library archive not found. Please contact PEPB author.")
        endif()
    endif()
    # //////////////////////////////////////////////////
endfunction()
