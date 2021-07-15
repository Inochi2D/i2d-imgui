cmake_minimum_required(VERSION 3.1)

project(bindbc_imgui)

set(CMAKE_DEBUG_POSTFIX "")

add_subdirectory(SDL)

set(OutputDirectory ${CMAKE_CURRENT_LIST_DIR}/../lib)

option(BUILD_SHARED_LIBS     "Build shared instead of static libraries." ON)

add_subdirectory(freetype)

set(IMGUI_FREETYPE "yes" CACHE STRING "Build with freetype library")
set(IMGUI_SDL "yes" CACHE STRING "Build with SDL")
add_subdirectory(cimgui)

set_target_properties(cimgui PROPERTIES DEBUG_POSTFIX "")
set_target_properties(SDL2 PROPERTIES DEBUG_POSTFIX "")

set_target_properties(cimgui PROPERTIES
    ARCHIVE_OUTPUT_DIRECTORY ${aLibraryDirectory}
    LIBRARY_OUTPUT_DIRECTORY ${aLibraryDirectory}
    RUNTIME_OUTPUT_DIRECTORY ${OutputDirectory})

set_target_properties(SDL2 PROPERTIES 
    ARCHIVE_OUTPUT_DIRECTORY ${OutputDirectory}
    LIBRARY_OUTPUT_DIRECTORY ${OutputDirectory}
    RUNTIME_OUTPUT_DIRECTORY ${OutputDirectory})
