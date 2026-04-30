cmake_minimum_required(VERSION 3.11)
project(GKeyComp C)

include(FetchContent)

FetchContent_Declare(CBUtil GIT_REPOSITORY https://github.com/chrisbazley/CBUtilLib.git GIT_TAG main)
FetchContent_Declare(GKey GIT_REPOSITORY https://github.com/chrisbazley/GKeyLib.git GIT_TAG main)

FetchContent_MakeAvailable(CBUtil GKey)

set(CMAKE_C_STANDARD 99)

if(MSVC)
    # MSVC equivalent of -Wall -Wextra is /W4
    add_compile_options(/W4)
else()
    # For GCC and Clang
    add_compile_options(-Wall -Wextra -pedantic)
endif()

if(WIN32)
    add_compile_definitions(PATH_SEPARATOR='\\\\')
elseif(CMAKE_SYSTEM_NAME STREQUAL "RISCos")
    add_compile_definitions(PATH_SEPARATOR='.')
else()
    add_compile_definitions(PATH_SEPARATOR='/')
endif()

set(GKCOMPSOURCES 
    gkcomp.c gkcommon.c filetype.c
)

add_executable(gkcomp ${GKCOMPSOURCES})

target_link_libraries(gkcomp PRIVATE 
    CBUtil
    GKey
)

target_compile_definitions(gkcomp PRIVATE
    $<$<CONFIG:Debug>:DEBUG_OUTPUT>
    $<$<CONFIG:Release>:NDEBUG>
)

target_compile_options(gkcomp PRIVATE
    $<$<CONFIG:Release>:-O3>
)

set(GKDECOMPSOURCES 
    gkdecomp.c gkcommon.c filetype.c
)

add_executable(gkdecomp ${GKDECOMPSOURCES})

target_link_libraries(gkdecomp PRIVATE 
    CBUtil
    GKey
)

target_compile_definitions(gkdecomp PRIVATE
    $<$<CONFIG:Debug>:DEBUG_OUTPUT>
    $<$<CONFIG:Release>:NDEBUG>
)

target_compile_options(gkdecomp PRIVATE
    $<$<CONFIG:Release>:-O3>
)
