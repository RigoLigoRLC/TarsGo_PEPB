#
# clangd_fixup_query_driver
# Fixup Clangd's --query-driver commandline argument in .vscode/settings.json
#
# REQUIRED
# [ARMGCC_BIN_DIR] Path of ARM GCC's bin directory.
#
function(clangd_fixup_query_driver ARMGCC_BIN_DIR)
    # Ensure .vscode/settings.json exists
    if(EXISTS ${CMAKE_SOURCE_DIR}/.vscode/settings.json)
        # Read launch.json
        file(READ ${CMAKE_SOURCE_DIR}/.vscode/settings.json SETTINGS_JSON)

        # Try to read clangd.arguments
        string(JSON CLANGD_ARGS_ARRAY ERROR_VARIABLE JSON_ERR_VAR GET ${SETTINGS_JSON} "clangd.arguments")
        if(JSON_ERR_VAR STREQUAL "NOTFOUND")
            string(JSON CLANGD_ARGS_COUNT ERROR_VARIABLE JSON_ERR_VAR LENGTH ${CLANGD_ARGS_ARRAY})
            message("Arg Count: ${CLANGD_ARGS_COUNT}")
        endif()
    endif()


endfunction(clangd_fixup_query_driver)
