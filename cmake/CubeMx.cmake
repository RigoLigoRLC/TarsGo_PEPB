MACRO(stm32_create_cube_lib BOARD_NAME CPU_TYPE)
    SET(BOARD_TARGET_NAME "board_${BOARD_NAME}")
    SET(BOARD_TARGET_DIR "${CMAKE_CURRENT_LIST_DIR}/${BOARD_NAME}")
    message(STATUS "Create board target: board_${BOARD_NAME}")

    # Detect linker scripts. Priorities: *_USER.ld, if not found  *_FLASH.ld, if not found first *.ld
    file(GLOB LINKER_SCRIPTS "${BOARD_TARGET_DIR}/*_USER.ld")
    if (NOT LINKER_SCRIPTS)
        file(GLOB LINKER_SCRIPTS "${BOARD_TARGET_DIR}/*_FLASH.ld")
        if (NOT LINKER_SCRIPTS)
            file(GLOB LINKER_SCRIPTS "${BOARD_TARGET_DIR}/*.ld")
        endif ()
    endif ()
    list(GET LINKER_SCRIPTS 0 LINKER_SCRIPT_${BOARD_TARGET_NAME})
    message(STATUS "Detected Linker Script for ${BOARD_TARGET_NAME}: ${LINKER_SCRIPT_${BOARD_TARGET_NAME}}")

    # Read kernel-specific header paths, defines, and sources from ".mxproject"
    file(STRINGS ${BOARD_TARGET_DIR}/.mxproject LINES)
    foreach (LINE ${LINES})
        # Makefile group is only used to extract includes and defines,
        # Lib group is only used to extract base library source files.
        if (LINE MATCHES "\\[(PreviousUsedMakefileFiles|PreviousLibFiles)\\]") # Detect relevant groups
            set(CUBE_PRJ_GROUP "C${CMAKE_MATCH_1}")
        elseif (LINE MATCHES "^\\[.*\\]$") # Detect non-relevant groups
            unset(CUBE_PRJ_GROUP)
        elseif (CUBE_PRJ_GROUP)
            if (LINE MATCHES "^\\s*CDefines=\\s*(.*)")
                # Compiler definitions
                set(MX_CDEFS ${CMAKE_MATCH_1})
            elseif (LINE MATCHES "^\\s*HeaderPath=\\s*(.*)\\s*")
                # Header paths
                string(REGEX MATCHALL "[^;]+" INCL_UNFILTERED_LIST "${CMAKE_MATCH_1}")
                list(TRANSFORM INCL_UNFILTERED_LIST PREPEND ${BOARD_TARGET_DIR}/)
                
                # Normalize paths
                foreach (INCL_DIR ${INCL_UNFILTERED_LIST})
                    cmake_path(SET INCL_DIR NORMALIZE ${INCL_DIR})
                    list(APPEND INCL_LIST ${INCL_DIR})
                endforeach()
            elseif (LINE MATCHES "^\\s*LibFiles=\\s*(.*)\\s*")
                # Library files, HAL/LL, CMSIS etc
                string(REGEX MATCHALL "[^;]+" SRC_UNFILTERED_LIST "${CMAKE_MATCH_1}")
                list(TRANSFORM SRC_UNFILTERED_LIST PREPEND ${BOARD_TARGET_DIR}/)

                # Normalize paths
                foreach (SRC_FILE ${SRC_UNFILTERED_LIST})
                    if (EXISTS "${SRC_FILE}")
                        cmake_path(SET SRC_FILE NORMALIZE ${SRC_FILE})
                        list(APPEND SRC_LIST ${SRC_FILE})
                    endif ()
                endforeach ()
            endif ()
        endif ()
    endforeach ()
    
    # Globbing user sources
    file(GLOB_RECURSE USER_SOURCES "${BOARD_TARGET_DIR}/Core/*.c" "${BOARD_TARGET_DIR}/Core/*.cpp" "${BOARD_TARGET_DIR}/Core/*.h")

    # Add CubeMX library
    add_library(${BOARD_TARGET_NAME} STATIC ${SRC_LIST} ${USER_SOURCES})
    target_include_directories(${BOARD_TARGET_NAME} PUBLIC ${INCL_LIST})
    target_compile_definitions(${BOARD_TARGET_NAME} PUBLIC $<$<COMPILE_LANGUAGE:C,CXX>:${MX_CDEFS}>)

    # Kernel-specific build settings
    target_compile_options(${BOARD_TARGET_NAME} PUBLIC -mcpu=${CPU_TYPE})
    target_link_options(${BOARD_TARGET_NAME} PUBLIC
            -Wl,-Map=${PROJECT_BINARY_DIR}/${PROJECT_NAME}.map -mcpu=${CPU_TYPE} -T ${LINKER_SCRIPT_${BOARD_TARGET_NAME}})
ENDMACRO()

function(stm32_create_hex NAME)
    set(HEX_FILE ${PROJECT_BINARY_DIR}/${NAME}.hex)
    set(BIN_FILE ${PROJECT_BINARY_DIR}/${NAME}.bin)
    add_custom_command(TARGET ${NAME}.elf POST_BUILD
            COMMAND ${CMAKE_OBJCOPY} -Oihex $<TARGET_FILE:${NAME}.elf> ${HEX_FILE}
            COMMAND ${CMAKE_OBJCOPY} -Obinary $<TARGET_FILE:${NAME}.elf> ${BIN_FILE}
            COMMENT " Building ${HEX_FILE} Building ${BIN_FILE}")
endfunction()