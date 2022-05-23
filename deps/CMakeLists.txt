cmake_minimum_required(VERSION 3.16)

project(bindbc_imgui)


####################
# Setup
set(CMAKE_DEBUG_POSTFIX "")
set(CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}/cmake")

#option(BUILD_SHARED_LIBS "Build shared instead of static libraries." ON)

message(STATUS Generator: ${CMAKE_GENERATOR})

if(${CMAKE_GENERATOR} MATCHES "Visual Studio.*")
    add_compile_options(/MP)
endif() 

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

# Libraries are built for Mac/Windows, and consumed via the Package Manager for Linux
if (NOT UNIX OR APPLE) # Windows and Mac
    add_subdirectory(freetype)
    set_target_properties(freetype PROPERTIES RUNTIME_OUTPUT_DIRECTORY_RELEASE ${OutputDirectory})
    set_target_properties(freetype PROPERTIES RUNTIME_OUTPUT_DIRECTORY_DEBUG ${OutputDirectory})
    set(IMGUI_FREETYPE "yes" CACHE STRING "Build with freetype library")
    set(IMGUI_FREETYPE_IN_TREE "yes" CACHE STRING "freetype library is being build in-tree")

    add_subdirectory(SDL)
    set_target_properties(SDL2 PROPERTIES DEBUG_POSTFIX "")
    set_target_properties(SDL2 PROPERTIES RUNTIME_OUTPUT_DIRECTORY_RELEASE ${OutputDirectory})
    set_target_properties(SDL2 PROPERTIES RUNTIME_OUTPUT_DIRECTORY_DEBUG ${OutputDirectory})
    set(IMGUI_SDL_IN_TREE "yes" CACHE STRING "SDL library is built in-tree")
else() # Linux
    include(FindFreetype)
    #find_package(freetype MODULE REQUIRED)
    set(IMGUI_FREETYPE "yes" CACHE STRING "Build with freetype library")
    set(IMGUI_FREETYPE_IN_TREE "no" CACHE STRING "freetype library is being build in-tree")

    find_package(SDL2 REQUIRED)
    set(IMGUI_SDL_IN_TREE "no" CACHE STRING "SDL library is built in-tree")
endif()

set(IMGUI_SDL "yes" CACHE STRING "Build with SDL")
set(IMGUI_OPENGL3 "yes" CACHE STRING "Build with OpenGL3")
add_subdirectory(cimgui)

set_target_properties(cimgui PROPERTIES DEBUG_POSTFIX "")
set_target_properties(cimgui PROPERTIES RUNTIME_OUTPUT_DIRECTORY_RELEASE ${OutputDirectory})
set_target_properties(cimgui PROPERTIES RUNTIME_OUTPUT_DIRECTORY_DEBUG ${OutputDirectory})
