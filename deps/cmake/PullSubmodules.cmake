include(FetchContent)

function(PullSubmodules aPath aOutputVar)
    # Read in the git modules file and prepare it.
    file(READ ${aPath}/.gitmodules modulesFileString)
    string(REGEX REPLACE "\n" ";" modulesFileString "${modulesFileString}")

    # Some constant line lengths of parts of strings we don't need so we can compute
    # the substrings of what we do need.
    string(LENGTH "[submodule \"\" " submoduleLineLengthConst)
    string(LENGTH "\tpath = " pathLineLengthConst)
    string(LENGTH "\turl = " urlLineLengthConst)
    string(LENGTH "-0000000000000000000000000000000000000000 " commitHashLengthConst)

    set(currentSubmodule "")
    foreach(line ${modulesFileString})
        # Every parsing case needs this, so might as well set it.
        string(LENGTH ${line} lineLength)
        
        # Find out if the line starts with something we're interesting in.
        string(FIND ${line} "[submodule \"" submoduleCheck)
        string(FIND ${line} "\tpath = " pathCheck)
        string(FIND ${line} "\turl = " urlCheck)

        # Handle the submodule definition case
        if ("${submoduleCheck}" EQUAL 0)
            math(EXPR endOfSubmoduleName "${lineLength} - ${submoduleLineLengthConst}")
            string(SUBSTRING ${line} 12 ${endOfSubmoduleName} submoduleName)

            set(currentSubmodule ${submoduleName})
            list(APPEND submodules ${submoduleName})
            
        # Handle the path definition case
        elseif("${pathCheck}" EQUAL 0)
            math(EXPR endOfSubmoduleName "${lineLength} - ${pathLineLengthConst}")
            string(SUBSTRING ${line} 8 ${endOfSubmoduleName} path)

            set(${currentSubmodule}_PATH ${path})

        # Handle the url definition case
        elseif("${urlCheck}" EQUAL 0)
            math(EXPR endOfSubmoduleName "${lineLength} - ${urlLineLengthConst}")
            string(SUBSTRING ${line} 7 ${endOfSubmoduleName} url)

            set(${currentSubmodule}_URL ${url})
        else()
            message(FATAL_ERROR "If you see this, our git modules parser is broken! Please report it!")
        endif()
    endforeach()
    
    # Read in the status of submodules so we know which commit to check out
    execute_process(COMMAND git submodule status WORKING_DIRECTORY ${aPath} OUTPUT_VARIABLE modulesCheckoutString)
    string(REGEX REPLACE "\n" ";" modulesCheckoutString "${modulesCheckoutString}")
    foreach(line ${modulesCheckoutString})
        string(LENGTH ${line} lineLength)
        math(EXPR lengthOfSubmoduleName "${lineLength} - ${commitHashLengthConst}")

        string(SUBSTRING ${line} 1 40 commitHash)
        string(SUBSTRING ${line} 42 ${lengthOfSubmoduleName} submoduleName)

        set(${submoduleName}_COMMIT_HASH ${commitHash})
    endforeach()

    # Walk each submodule and pull it down by FetchContent if it's not pulled.
    # Right now it's assumed the submodules are all in one folder, and they're 
    # either all there, or not. So this should be augmented in the future to 
    # improve things.
    foreach(submodule ${submodules})
        if (NOT EXISTS ${aPath}/${submodule}/.git)
            message(STATUS ${${submodule}})

            message(STATUS "submodule: ${submodule}")
            message(STATUS "\tpath: ${${submodule}_PATH}")
            message(STATUS "\turl: ${${submodule}_URL}")
            message(STATUS "\tcommitHash: ${${submodule}_COMMIT_HASH}")
            
            string(REGEX REPLACE "/" "_" submoduleNameAdjusted "${submodule}")
            string(REGEX REPLACE "/" "_" submoduleNameAdjusted "${submodule}")

            FetchContent_Declare(${submoduleNameAdjusted}
                GIT_REPOSITORY ${${submodule}_URL}
                GIT_TAG        ${${submodule}_COMMIT_HASH}
                GIT_PROGRESS   TRUE
                SOURCE_DIR     ${CMAKE_CURRENT_BINARY_DIR}/PulledSubmodules/${submodule}

            )
            FetchContent_Populate(${submoduleNameAdjusted})

            # Technically we should maybe do some big output map thing here, but for now
            # we'll assume all submodules are in the same folder.
            if(NOT outputPath)
                string(FIND ${submodule} "/" separatorPosition REVERSE)
                string(SUBSTRING ${submodule} 0 ${separatorPosition} submoduleFolderName)
                set(outputPath ${CMAKE_CURRENT_BINARY_DIR}/PulledSubmodules/${submoduleFolderName}/)
            endif()
        endif()
    endforeach()

    set(${aOutputVar} ${outputPath} PARENT_SCOPE)
endfunction()