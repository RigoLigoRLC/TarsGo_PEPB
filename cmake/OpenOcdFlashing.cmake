
add_custom_target(Download_Via_OpenOCD)

function(pepb_generate_debug_target TARGET_NAME OPENOCD_EXECUTABLE OPENOCD_CHIP_CFG OPENOCD_PROGRAMMER_CFG)
    # Ensure launch.json exists
    if(EXISTS ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../.vscode/launch.json)
        # Read .vscode/launch.json
        file(READ ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../.vscode/launch.json LAUNCH_JSON)

        # Check if there's already a configuration named PEPB_CortexDebug
        string(JSON CONFIGURATION_ARRAY ERROR_VARIABLE CONFIGURATION_READ_ERROR LENGTH ${LAUNCH_JSON} "configurations")
        if(NOT CONFIGURATION_READ_ERROR STREQUAL "NOTFOUND")
            message(STATUS "ERROR: ${CONFIGURATION_READ_ERROR}")
        else()
            string(JSON CONFIGURATION_COUNT ERROR_VARIABLE CONFIGURATION_READ_ERROR LENGTH ${LAUNCH_JSON} "configurations")
            math(EXPR CONFIGURATION_COUNT "${CONFIGURATION_COUNT} - 1")
            foreach(INDEX RANGE ${CONFIGURATION_COUNT})
                string(JSON CONFIGURATION_NAME GET ${LAUNCH_JSON} "configurations" ${INDEX} "name")
                if(CONFIGURATION_NAME STREQUAL "PEPB_CortexDebug")
                    set(LAUNCH_CFG_ENTRY_INDEX ${CONFIGURATION_COUNT})
                    break()
                endif()
            endforeach()
        endif()
    endif()

    if(NOT DEFINED LAUNCH_CFG_ENTRY_INDEX)
        message(STATUS " - Generating existing launch configuration...")
        # Add a new configuration
        set(CFG_ENTRY "{}")
        string(JSON CFG_ENTRY SET "${CFG_ENTRY}" "name" "\"PEPB_CortexDebug\"")
        string(JSON CFG_ENTRY SET "${CFG_ENTRY}" "type" "\"cortex-debug\"")
        string(JSON CFG_ENTRY SET "${CFG_ENTRY}" "request" "\"launch\"")
        string(JSON CFG_ENTRY SET "${CFG_ENTRY}" "servertype" "\"openocd\"")
        string(JSON CFG_ENTRY SET "${CFG_ENTRY}" "cwd" "\"\${workspaceRoot}\"")
        string(JSON CFG_ENTRY SET "${CFG_ENTRY}" "executable" "\"\${workspaceRoot}/build/${TARGET_NAME}.elf\"")
        string(JSON CFG_ENTRY SET "${CFG_ENTRY}" "configFiles" "[\"${OPENOCD_PROGRAMMER_CFG}\", \"${OPENOCD_CHIP_CFG}\"]")
        string(JSON CFG_ENTRY SET "${CFG_ENTRY}" "liveWatch" "{\"enabled\": true,\"samplesPerSecond\": 4}")
        string(JSON CFG_ENTRY SET "${CFG_ENTRY}" "runToEntryPoint" "\"main\"")
    else()
        # Update the existing configuration
        message(STATUS " - Updating existing launch configuration...")
        string(JSON CFG_ENTRY GET ${LAUNCH_JSON} "configurations" ${LAUNCH_CFG_ENTRY_INDEX})
        string(JSON CFG_ENTRY SET "${CFG_ENTRY}" "executable" "\"\${workspaceRoot}/build/${TARGET_NAME}.elf\"")
        string(JSON CFG_ENTRY SET "${CFG_ENTRY}" "configFiles" "[\"${OPENOCD_PROGRAMMER_CFG}\", \"${OPENOCD_CHIP_CFG}\"]")
        string(JSON LAUNCH_JSON SET "${LAUNCH_JSON}" "configurations" ${LAUNCH_CFG_ENTRY_INDEX} "${CFG_ENTRY}")
    endif()

    # Update launch.json
    if(NOT EXISTS ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../.vscode/launch.json OR NOT CONFIGURATION_READ_ERROR STREQUAL "NOTFOUND")
        file(WRITE ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../.vscode/launch.json "{\n  \"configurations\":\n    [${CFG_ENTRY}] }")
    else()
    file(WRITE ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../.vscode/launch.json "${LAUNCH_JSON}")
    endif()
endfunction()

function(pepb_add_download_target TARGET_NAME)
    # Read JSON settings
    file(READ ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/Settings.json SETTINGS_JSON)

    string(JSON OPENOCD_BIN GET ${SETTINGS_JSON} "OpenOcd" "Path")
    string(JSON OPENOCD_CHIP GET ${SETTINGS_JSON} "OpenOcd" "Chip")
    string(JSON OPENOCD_PROGRAMMER GET ${SETTINGS_JSON} "OpenOcd" "Programmer")

    # Ensure OpenOCD exists
    set(OPENOCD_EXECUTABLE "${OPENOCD_BIN}/openocd")
    # Because we would specify a baremetal toolchain file, CMAKE_EXECUTABLE_SUFFIX would fail to work
    if(CMAKE_HOST_WIN32)
        set(OPENOCD_EXECUTABLE "${OPENOCD_EXECUTABLE}.exe")
    endif()

    if(NOT EXISTS ${OPENOCD_EXECUTABLE})
        message(FATAL_ERROR "OpenOCD NOT FOUND: ${OPENOCD_EXECUTABLE}")
    endif()
    message(STATUS "Use OpenOCD executable: ${OPENOCD_EXECUTABLE}")

    # Check chip and programmer configuration files
    set(OPENOCD_CONFIG_DIR "${OPENOCD_BIN}/../openocd/scripts/")
    set(OPENOCD_CHIP_CFG "${OPENOCD_CONFIG_DIR}/target/${OPENOCD_CHIP}.cfg")
    set(OPENOCD_PROGRAMMER_CFG "${OPENOCD_CONFIG_DIR}/interface/${OPENOCD_PROGRAMMER}.cfg")
    if(NOT EXISTS ${OPENOCD_CHIP_CFG})
        message(FATAL_ERROR "OpenOCD chip configuration NOT FOUND: ${OPENOCD_CHIP_CFG}")
    endif()
    if(NOT EXISTS ${OPENOCD_PROGRAMMER_CFG})
        message(FATAL_ERROR "OpenOCD programmer configuration NOT FOUND: ${OPENOCD_PROGRAMMER_CFG}")
    endif()

    message(STATUS " - OpenOCD Configured to use Chip: ${OPENOCD_CHIP}; Programmer: ${OPENOCD_PROGRAMMER}")
    
    # Add download target
    add_custom_target(${TARGET_NAME}
        COMMAND ${CMAKE_COMMAND} -E env
            ${OPENOCD_EXECUTABLE} -f ${OPENOCD_PROGRAMMER_CFG} -f ${OPENOCD_CHIP_CFG} -c "init" -c "reset halt" -c "flash write_image erase ${CMAKE_CURRENT_BINARY_DIR}/${TARGET_NAME}.bin 0x08000000" -c "reset run" -c "shutdown"
        DEPENDS ${TARGET_NAME}.elf
        WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
    )
    add_dependencies(Download_Via_OpenOCD ${TARGET_NAME})

    # Update launch.json
    pepb_generate_debug_target(${TARGET_NAME} ${OPENOCD_EXECUTABLE} ${OPENOCD_CHIP_CFG} ${OPENOCD_PROGRAMMER_CFG})
endfunction()