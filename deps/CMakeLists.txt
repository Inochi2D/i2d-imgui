cmake_minimum_required(VERSION 3.1)

project(bindbc_imgui)

set(CMAKE_DEBUG_POSTFIX "")

add_subdirectory(SDL)

# This needs to be augmented to detect ARM vs x86
if(CMAKE_SIZEOF_VOID_P EQUAL 8)
    set(PlatformArchitecture x86_64)
elseif(CMAKE_SIZEOF_VOID_P EQUAL 4)
    set(PlatformArchitecture x86)
endif()

if (${CMAKE_SYSTEM_NAME} MATCHES "Windows")
    set(PlatformFolder "win32")
elseif (${CMAKE_SYSTEM_NAME} MATCHES "Darwin")
    set(PlatformFolder "darwin")
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

option(BUILD_SHARED_LIBS     "Build shared instead of static libraries." ON)

add_subdirectory(freetype)

set(IMGUI_FREETYPE_IN_TREE "yes" CACHE STRING "freetype library is being build in-tree")
set(IMGUI_FREETYPE "yes" CACHE STRING "Build with freetype library")
set(IMGUI_SDL_IN_TREE "yes" CACHE STRING "SDL library is built in-tree")
set(IMGUI_SDL "yes" CACHE STRING "Build with SDL")
set(IMGUI_OPENGL3 "yes" CACHE STRING "Build with OpenGL3")
add_subdirectory(cimgui)

set_target_properties(cimgui PROPERTIES DEBUG_POSTFIX "")
set_target_properties(SDL2 PROPERTIES DEBUG_POSTFIX "")

set_target_properties(cimgui PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY_RELEASE ${OutputDirectory})

set_target_properties(SDL2 PROPERTIES 
    RUNTIME_OUTPUT_DIRECTORY_RELEASE ${OutputDirectory})

set_target_properties(freetype PROPERTIES 
    RUNTIME_OUTPUT_DIRECTORY_RELEASE ${OutputDirectory})
    
set_target_properties(cimgui PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY_DEBUG ${OutputDirectory})

set_target_properties(SDL2 PROPERTIES 
    RUNTIME_OUTPUT_DIRECTORY_DEBUG ${OutputDirectory})

set_target_properties(freetype PROPERTIES 
    RUNTIME_OUTPUT_DIRECTORY_DEBUG ${OutputDirectory})
