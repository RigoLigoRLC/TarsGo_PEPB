
function(pepb_generate_debug_target TARGET_NAME OPENOCD_EXECUTABLE OPENOCD_CHIP_CFG OPENOCD_PROGRAMMER_CFG)
    # Ensure launch.json exists
    if(EXISTS ${CMAKE_SOURCE_DIR}/.vscode/launch.json)
        # Read .vscode/launch.json
        file(READ ${CMAKE_SOURCE_DIR}/.vscode/launch.json LAUNCH_JSON)

        # Check if there's already a configuration named "Debug (PEPB)"
        string(JSON CONFIGURATION_ARRAY ERROR_VARIABLE CONFIGURATION_READ_ERROR LENGTH ${LAUNCH_JSON} "configurations")
        if(NOT CONFIGURATION_READ_ERROR STREQUAL "NOTFOUND")
            message(STATUS "ERROR: ${CONFIGURATION_READ_ERROR}")
        else()
            string(JSON CONFIGURATION_COUNT ERROR_VARIABLE CONFIGURATION_READ_ERROR LENGTH ${LAUNCH_JSON} "configurations")
            math(EXPR CONFIGURATION_COUNT "${CONFIGURATION_COUNT} - 1")
            foreach(INDEX RANGE ${CONFIGURATION_COUNT})
                string(JSON CONFIGURATION_NAME GET ${LAUNCH_JSON} "configurations" ${INDEX} "name")
                if(CONFIGURATION_NAME STREQUAL "Debug (PEPB)")
                    set(LAUNCH_CFG_ENTRY_INDEX ${CONFIGURATION_COUNT})
                elseif(CONFIGURATION_NAME STREQUAL "Attach (PEPB)")
                    set(ATTACH_CFG_ENTRY_INDEX ${CONFIGURATION_COUNT})
                endif()
            endforeach()
        endif()
    else()
        set(LAUNCH_JSON "{\"configurations\":[]}")
    endif()
    
    # Create configuration template
    set(CFG_ENTRY "{}")
    string(JSON CFG_ENTRY SET "${CFG_ENTRY}" "name" "\"Debug (PEPB)\"")
    string(JSON CFG_ENTRY SET "${CFG_ENTRY}" "type" "\"cortex-debug\"")
    string(JSON CFG_ENTRY SET "${CFG_ENTRY}" "request" "\"launch\"")
    string(JSON CFG_ENTRY SET "${CFG_ENTRY}" "servertype" "\"openocd\"")
    string(JSON CFG_ENTRY SET "${CFG_ENTRY}" "cwd" "\"\${workspaceRoot}\"")
    string(JSON CFG_ENTRY SET "${CFG_ENTRY}" "executable" "\"\${workspaceRoot}/build/${TARGET_NAME}.elf\"")
    string(JSON CFG_ENTRY SET "${CFG_ENTRY}" "configFiles" "[\"${OPENOCD_PROGRAMMER_CFG}\", \"${OPENOCD_CHIP_CFG}\"]")
    string(JSON CFG_ENTRY SET "${CFG_ENTRY}" "liveWatch" "{\"enabled\": true,\"samplesPerSecond\": 4}")
    string(JSON CFG_ENTRY SET "${CFG_ENTRY}" "rttConfig" "{\"enabled\":true,\"address\":\"auto\",\"decoders\":[{\"label\":\"\",\"port\":0,\"type\":\"console\",\"inputmode\":\"raw\"}]}")

    # Modify Launch configuration
    if (NOT DEFINED LAUNCH_CFG_ENTRY_INDEX)
        set(LAUNCH_CFG_ENTRY_INDEX 999999)
    endif()
    string(JSON LAUNCH_JSON SET "${LAUNCH_JSON}" "configurations" ${LAUNCH_CFG_ENTRY_INDEX} "${CFG_ENTRY}")

    # Modify Attach configuration
    string(JSON CFG_ENTRY SET "${CFG_ENTRY}" "name" "\"Attach (PEPB)\"")
    string(JSON CFG_ENTRY SET "${CFG_ENTRY}" "request" "\"attach\"")
    if (NOT DEFINED ATTACH_CFG_ENTRY_INDEX)
        set(ATTACH_CFG_ENTRY_INDEX 999999)
    endif()
    string(JSON LAUNCH_JSON SET "${LAUNCH_JSON}" "configurations" ${ATTACH_CFG_ENTRY_INDEX} "${CFG_ENTRY}")

    # Update launch.json
    file(WRITE ${CMAKE_SOURCE_DIR}/.vscode/launch.json "${LAUNCH_JSON}")
endfunction()

function(pepb_add_download_target TARGET_NAME)
    # Read JSON settings
    file(READ ${CMAKE_SOURCE_DIR}/.vscode/PEPBSettings.json SETTINGS_JSON)

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
    add_custom_target(Download
        COMMAND ${CMAKE_COMMAND} -E env
            ${OPENOCD_EXECUTABLE} -f ${OPENOCD_PROGRAMMER_CFG} -f ${OPENOCD_CHIP_CFG} -c "init" -c "reset halt" -c "flash write_image erase ${CMAKE_CURRENT_BINARY_DIR}/${TARGET_NAME}.bin 0x08000000" -c "reset run" -c "shutdown"
        DEPENDS ${TARGET_NAME}
        WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
    )

    # Update launch.json
    pepb_generate_debug_target(${TARGET_NAME} ${OPENOCD_EXECUTABLE} ${OPENOCD_CHIP_CFG} ${OPENOCD_PROGRAMMER_CFG})
endfunction()