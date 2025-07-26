cmake_minimum_required(VERSION 3.16)

project(bindbc_imgui)

include(cmake/PullSubmodules.cmake)

PullSubmodules(${CMAKE_CURRENT_LIST_DIR}/.. submodulePrefixPath)

message(STATUS "submodulePrefixPath: ${submodulePrefixPath}")

####################
# Setup
set(CMAKE_DEBUG_POSTFIX "")
set(CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}/cmake")

option(BUILD_SHARED_LIBS "Build shared instead of static libraries." ON)

set(PlatformArchitecture ${CMAKE_SYSTEM_PROCESSOR})

if(${CMAKE_GENERATOR} MATCHES "Visual Studio.*")
    add_compile_options(/MP)

    if (CMAKE_GENERATOR_PLATFORM)
        if(${CMAKE_GENERATOR_PLATFORM} STREQUAL ARM64)
            set(PlatformArchitecture arm64)
        endif()
    endif()
endif() 

if (${CMAKE_SYSTEM_NAME} MATCHES "Windows")
    set(PlatformFolder "win32")
elseif (${CMAKE_SYSTEM_NAME} MATCHES "Darwin")
    set(PlatformFolder "darwin")
    set(CMAKE_OSX_ARCHITECTURES "arm64;x86_64")

    # This is neccesary to avoid macports/homebrew libraries to be seen
    # these break universal builds.
    set(CMAKE_IGNORE_PATH
        /opt/local/lib
        /opt/local/include
        /opt/local/bin)
elseif (${CMAKE_SYSTEM_NAME} MATCHES "Linux")
    set(PlatformFolder "linux")
elseif (${CMAKE_SYSTEM_NAME} MATCHES "Android")
    set(PlatformFolder "android")
elseif (${CMAKE_SYSTEM_NAME} MATCHES "FreeBSD")
    set(PlatformFolder "bsd")
elseif (${CMAKE_SYSTEM_NAME} MATCHES "MSYS")
    set(PlatformFolder "win32")
else ()
    set(PlatformFolder "Unknown")
endif()

set(OutputDirectory ${CMAKE_CURRENT_LIST_DIR}/../libs/${PlatformArchitecture}/${PlatformFolder})

if (DEFINED STATIC_CIMGUI)
    set(OutputDirectory ${OutputDirectory}/Static)
    set(IMGUI_STATIC "yes" CACHE STRING "Build as a static library")
else()
    set(OutputDirectory ${OutputDirectory}/Dynamic)
    set(IMGUI_STATIC "no" CACHE STRING "Build as a static library")
endif()

if (MSVC)
    if(DEFINED WINDOWS_STATIC_CRT)
        set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")
        set(OutputDirectory ${OutputDirectory}/StaticCRT)
    else()
        set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>DLL")
        set(OutputDirectory ${OutputDirectory}/DynamicCRT)
    endif()
endif()

# Libraries are built for Mac/Windows, and consumed via the Package Manager for Linux
if (NOT UNIX OR APPLE OR DEFINED USE_SUBMODULE_SOURCES) # Windows and Mac
    add_subdirectory(${freetype_SUBMOD_DIR})
    set_target_properties(freetype PROPERTIES DEBUG_POSTFIX "")
    set_target_properties(freetype PROPERTIES ARCHIVE_OUTPUT_DIRECTORY ${OutputDirectory})
    set_target_properties(freetype PROPERTIES LIBRARY_OUTPUT_DIRECTORY ${OutputDirectory})
    set_target_properties(freetype PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${OutputDirectory})
    set_target_properties(freetype PROPERTIES ARCHIVE_OUTPUT_DIRECTORY_RELEASE ${OutputDirectory})
    set_target_properties(freetype PROPERTIES LIBRARY_OUTPUT_DIRECTORY_RELEASE ${OutputDirectory})
    set_target_properties(freetype PROPERTIES RUNTIME_OUTPUT_DIRECTORY_RELEASE ${OutputDirectory})
    set(IMGUI_FREETYPE "yes" CACHE STRING "Build with freetype library")
    set(IMGUI_FREETYPE_IN_TREE "yes" CACHE STRING "freetype library is being build in-tree")


    add_subdirectory(${SDL_SUBMOD_DIR})

    if (TARGET SDL2)
        set(SDL_target SDL2)
    else()
        set(SDL_target SDL2-static)
    endif()

    set_target_properties(${SDL_target} PROPERTIES DEBUG_POSTFIX "")
    set_target_properties(${SDL_target} PROPERTIES ARCHIVE_OUTPUT_DIRECTORY ${OutputDirectory})
    set_target_properties(${SDL_target} PROPERTIES LIBRARY_OUTPUT_DIRECTORY ${OutputDirectory})
    set_target_properties(${SDL_target} PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${OutputDirectory})
    set_target_properties(${SDL_target} PROPERTIES ARCHIVE_OUTPUT_DIRECTORY_RELEASE ${OutputDirectory})
    set_target_properties(${SDL_target} PROPERTIES LIBRARY_OUTPUT_DIRECTORY_RELEASE ${OutputDirectory})
    set_target_properties(${SDL_target} PROPERTIES RUNTIME_OUTPUT_DIRECTORY_RELEASE ${OutputDirectory})
    set(IMGUI_SDL_IN_TREE "yes" CACHE STRING "SDL library is built in-tree")
else() # Linux
    include(FindFreetype)
    #find_package(freetype MODULE REQUIRED)
    set(IMGUI_FREETYPE "yes" CACHE STRING "Build with freetype library")
    set(IMGUI_FREETYPE_IN_TREE "no" CACHE STRING "freetype library is being build in-tree")

    find_package(SDL2 REQUIRED)
    set(IMGUI_SDL_IN_TREE "no" CACHE STRING "SDL library is built in-tree")
endif()


message(STATUS "IMGUI_FREETYPE = ${IMGUI_FREETYPE}")
message(STATUS "IMGUI_FREETYPE_IN_TREE = ${IMGUI_FREETYPE_IN_TREE}")

option(BUILD_SHARED_LIBS "Build shared instead of static libraries." OFF)

set(IMGUI_SDL "yes" CACHE STRING "Build with SDL")
set(IMGUI_OPENGL3 "yes" CACHE STRING "Build with OpenGL3")
add_subdirectory(${cimgui_SUBMOD_DIR})

set_target_properties(cimgui PROPERTIES DEBUG_POSTFIX "")
set_target_properties(cimgui PROPERTIES ARCHIVE_OUTPUT_DIRECTORY ${OutputDirectory})
set_target_properties(cimgui PROPERTIES LIBRARY_OUTPUT_DIRECTORY ${OutputDirectory})
set_target_properties(cimgui PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${OutputDirectory})
set_target_properties(cimgui PROPERTIES ARCHIVE_OUTPUT_DIRECTORY_RELEASE ${OutputDirectory})
set_target_properties(cimgui PROPERTIES LIBRARY_OUTPUT_DIRECTORY_RELEASE ${OutputDirectory})
set_target_properties(cimgui PROPERTIES RUNTIME_OUTPUT_DIRECTORY_RELEASE ${OutputDirectory})
