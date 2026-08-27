cmake_minimum_required(VERSION 3.11)
project(GKeyComp C)

option(USE_OPTIONAL "Enable the _Optional qualifier" OFF)
option(USE_FORTIFY "Enable Fortify memory-allocation checking" OFF)
option(ENABLE_CLANG_TIDY "Run clang-tidy during compilation" OFF)

include(FetchContent)

FetchContent_Declare(CBUtil GIT_REPOSITORY https://github.com/chrisbazley/CBUtilLib.git GIT_TAG main)
FetchContent_Declare(GKey GIT_REPOSITORY https://github.com/chrisbazley/GKeyLib.git GIT_TAG main)

FetchContent_MakeAvailable(CBUtil GKey)

if(USE_OPTIONAL)
    if(NOT CMAKE_C_COMPILER_ID MATCHES "Clang|AppleClang")
        message(FATAL_ERROR
            "USE_OPTIONAL requires Christopher Bazley's Clang fork")
    endif()

    add_compile_definitions(USE_OPTIONAL)

    if(CMAKE_GENERATOR STREQUAL "Xcode")
        set(CMAKE_XCODE_ATTRIBUTE_RUN_CLANG_STATIC_ANALYZER "YES")
        set(CMAKE_XCODE_ATTRIBUTE_CLANG_ANALYZER_OTHER_FLAGS
            "-analyzer-checker optionality,core -analyzer-max-loop 32")
    endif()
endif()

if(USE_FORTIFY)
    FetchContent_Declare(Fortify
        GIT_REPOSITORY https://github.com/chrisbazley/Fortify.git
        GIT_TAG main
    )

    FetchContent_MakeAvailable(Fortify)
endif()

set(CMAKE_C_STANDARD 99)
set(CMAKE_XCODE_ATTRIBUTE_RUN_CLANG_STATIC_ANALYZER "YES")

if(MSVC)
    # MSVC equivalent of -Wall -Wextra is /W4
    add_compile_options(/W4 /wd4200 /wd4996 /wd4130)
else()
    # For GCC and Clang
    add_compile_options(-Wall -Wextra -Wsign-compare -pedantic)
endif()

if(ENABLE_CLANG_TIDY)
    if(NOT CMAKE_C_COMPILER_ID MATCHES "Clang|AppleClang")
        message(FATAL_ERROR "ENABLE_CLANG_TIDY requires Clang")
    endif()

    find_program(CLANG_TIDY_EXE
        NAMES clang-tidy
        HINTS "/opt/homebrew/opt/llvm/bin"
    )

    if(NOT CLANG_TIDY_EXE)
        message(FATAL_ERROR
            "ENABLE_CLANG_TIDY is ON, but clang-tidy was not found")
    endif()

    set(CMAKE_C_CLANG_TIDY
        "${CLANG_TIDY_EXE}"
        "--checks=-*,clang-analyzer-*,-clang-analyzer-security.insecureAPI.*"
        "--warnings-as-errors=clang-analyzer-optionality.*"
    )

    message(STATUS "clang-tidy: ${CLANG_TIDY_EXE}")
    message(STATUS "_Optional static analysis enabled")
endif()

if(WIN32)
    add_compile_definitions(PATH_SEPARATOR='\\\\')
elseif(CMAKE_SYSTEM_NAME STREQUAL "RISCos")
    add_compile_definitions(PATH_SEPARATOR='.')
else()
    add_compile_definitions(PATH_SEPARATOR='/')
endif()

set(COMMON_SOURCES
    gkcommon.c filetype.c
)

set(COMMON_HEADERS
    gkcommon.h filetype.h misc.h version.h
)

set(GKCOMP_SOURCES
    gkcomp.c ${COMMON_SOURCES} ${COMMON_HEADERS}
)

add_executable(gkcomp ${GKCOMP_SOURCES})

target_link_libraries(gkcomp PRIVATE 
    CBUtil
    GKey
)

target_compile_definitions(gkcomp PRIVATE
    $<$<CONFIG:Debug>:DEBUG_OUTPUT>
)

set(GKDECOMP_SOURCES
    gkdecomp.c ${COMMON_SOURCES} ${COMMON_HEADERS}
)

add_executable(gkdecomp ${GKDECOMP_SOURCES})

target_link_libraries(gkdecomp PRIVATE 
    CBUtil
    GKey
)

target_compile_definitions(gkdecomp PRIVATE
    $<$<CONFIG:Debug>:DEBUG_OUTPUT>
)

enable_testing()
add_test(NAME IntegrationTest COMMAND ${CMAKE_COMMAND}
    -D GKCOMP=$<TARGET_FILE:gkcomp>
    -D GKDECOMP=$<TARGET_FILE:gkdecomp>
    -P ${CMAKE_CURRENT_SOURCE_DIR}/RunTests.cmake
)
