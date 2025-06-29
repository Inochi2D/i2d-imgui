cmake_minimum_required(VERSION 3.16)

project(bindbc_imgui)

include(cmake/PullSubmodules.cmake)

PullSubmodules(${CMAKE_CURRENT_LIST_DIR}/.. submodulePrefixPath)

message(STATUS "submodulePrefixPath: ${submodulePrefixPath}")

####################
# Setup
set(CMAKE_DEBUG_POSTFIX "")
set(CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}/cmake")

option(BUILD_SHARED_LIBS "Build shared instead of static libraries." OFF)

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

if (${CMAKE_SYSTEM_NAME} MATCHES "Darwin")
    set(OutputDirectory ${CMAKE_CURRENT_LIST_DIR}/../libs/${PlatformFolder})
else ()
    set(OutputDirectory ${CMAKE_CURRENT_LIST_DIR}/../libs/${PlatformArchitecture}/${PlatformFolder})
endif()

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

option(BUILD_SHARED_LIBS "Build shared instead of static libraries." OFF)
set(IMGUI_SDL "no" CACHE STRING "Build with SDL")
set(IMGUI_OPENGL3 "no" CACHE STRING "Build with OpenGL3")
set(IMGUI_FREETYPE "no" CACHE STRING "Build with freetype library")
set(IMGUI_WCHAR32 ON)


add_subdirectory(${cimgui_SUBMOD_DIR})

set_target_properties(cimgui PROPERTIES DEBUG_POSTFIX "")
set_target_properties(cimgui PROPERTIES ARCHIVE_OUTPUT_DIRECTORY ${OutputDirectory})
set_target_properties(cimgui PROPERTIES LIBRARY_OUTPUT_DIRECTORY ${OutputDirectory})
set_target_properties(cimgui PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${OutputDirectory})
set_target_properties(cimgui PROPERTIES ARCHIVE_OUTPUT_DIRECTORY_RELEASE ${OutputDirectory})
set_target_properties(cimgui PROPERTIES LIBRARY_OUTPUT_DIRECTORY_RELEASE ${OutputDirectory})
set_target_properties(cimgui PROPERTIES RUNTIME_OUTPUT_DIRECTORY_RELEASE ${OutputDirectory})

if (NOT ${CMAKE_SYSTEM_NAME} MATCHES "Windows")
    set_target_properties(cimgui PROPERTIES PREFIX "lib")
endif()