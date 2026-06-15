# RunTests.cmake
cmake_minimum_required(VERSION 3.10)

if(GKCOMP)
    cmake_path(NATIVE_PATH GKCOMP GKCOMP)
else()
    set(GKCOMP "./gkcomp")
endif()

if(GKDECOMP)
    cmake_path(NATIVE_PATH GKDECOMP GKDECOMP)
else()
    set(GKDECOMP "./gkdecomp")
endif()

message(STATUS "DEBUG: Current working directory is: ${CMAKE_CURRENT_BINARY_DIR}")
message(STATUS "DEBUG: Path to gkcomp executable is: ${GKCOMP}")
message(STATUS "DEBUG: Path to gkdecomp executable is: ${GKDECOMP}")

message(STATUS "Starting History Buffer Sizes Verification...")
# Create a text file to test the history window boundaries
set(TEXT_BLOCK "Acorn RISC OS Fourth Dimension FedNet Chocks Away Stunt Racer Star Fighter GKeyLib. ")
set(LARGE_TEXT "")
foreach(i RANGE 1 500)
    string(APPEND LARGE_TEXT "${TEXT_BLOCK}")
endforeach()
file(WRITE "buffer_original.txt" "${LARGE_TEXT}")

# =====================================================================
# STAGE 1: Non-Batch Mode Testing with a Variety of History Buffer Sizes
# =====================================================================

# Define base-2 logarithm history values to test (0=1B, 4=16B, 9=512B default, 12=4KB)
set(HISTORY_VALUES 0 4 9 12 14 16 20)

foreach(HIST_VAL ${HISTORY_VALUES})
    message(STATUS "Testing Non-Batch Mode with History Size: Log2(${HIST_VAL})...")

    # 1. Compress using current history log-2 value
    execute_process(
        COMMAND ${GKCOMP} -history ${HIST_VAL} "buffer_original.txt" "buffer_squeezed.bin"
        RESULT_VARIABLE cmd_res
    )
    if(NOT cmd_res EQUAL 0)
        message(FATAL_ERROR "Compression failed at history value ${HIST_VAL} with code ${cmd_res}")
    endif()

    # 2. Decompress using current history log-2 value
    execute_process(
        COMMAND ${GKDECOMP} -history ${HIST_VAL} "buffer_squeezed.bin" "buffer_restored.txt"
        RESULT_VARIABLE cmd_res
    )
    if(NOT cmd_res EQUAL 0)
        message(FATAL_ERROR "Decompression failed for history value ${HIST_VAL} with code ${cmd_res}")
    endif()

    # 3. Verify the file round-trip remains lossless
    execute_process(
        COMMAND ${CMAKE_COMMAND} -E compare_files "buffer_original.txt" "buffer_restored.txt"
        RESULT_VARIABLE diff_res
    )
    if(diff_res)
        message(FATAL_ERROR "FAILURE: File corruption detected using history value ${HIST_VAL}!")
    else()
        message(STATUS "SUCCESS: Lossless match verified for history value ${HIST_VAL}.")
    endif()

    # Clean up files from this loop step
    file(REMOVE "buffer_squeezed.bin" "buffer_restored.txt")
endforeach()

# =====================================================================
# STAGE 2: Non-Batch Mode Testing with Mismatching History Buffer Sizes
# =====================================================================
message(STATUS "Starting Mismatching History Buffer Sizes Verification...")

# 1. Compress using one history log-2 value
execute_process(
    COMMAND ${GKCOMP} -history 8 "buffer_original.txt" "buffer_squeezed.bin"
    RESULT_VARIABLE cmd_res
)
if(NOT cmd_res EQUAL 0)
    message(FATAL_ERROR "Compression failed with code ${cmd_res}")
endif()

# 2. Decompress using another history log-2 value
execute_process(
    COMMAND ${GKDECOMP} -history 9 "buffer_squeezed.bin" "buffer_restored.txt"
    RESULT_VARIABLE cmd_res
)
if(cmd_res EQUAL 0)
    message(FATAL_ERROR "Expected decompression failure did not happen")
endif()

# Clean up file from this stage
file(REMOVE "buffer_squeezed.bin" "buffer_restored.txt")

# =====================================================================
# STAGE 3: Output file name before input file name
# =====================================================================
message(STATUS "Starting output file name before input file name verification...")

# 1. Compress with output file name specified by an option
execute_process(
    COMMAND ${GKCOMP} -outfile "buffer_squeezed.bin" "buffer_original.txt"
    RESULT_VARIABLE cmd_res
)
if(NOT cmd_res EQUAL 0)
    message(FATAL_ERROR "Compression with output file name first failed with code ${cmd_res}")
endif()

# 2. Decompress with output file name specified by an option
execute_process(
    COMMAND ${GKDECOMP} -outfile "buffer_restored.txt" "buffer_squeezed.bin"
    RESULT_VARIABLE cmd_res
)
if(NOT cmd_res EQUAL 0)
    message(FATAL_ERROR "Decompression with output file name first failed with code ${cmd_res}")
endif()

# 3. Verify the file round-trip remains lossless
execute_process(
    COMMAND ${CMAKE_COMMAND} -E compare_files "buffer_original.txt" "buffer_restored.txt"
    RESULT_VARIABLE diff_res
)
if(diff_res)
    message(FATAL_ERROR "FAILURE: File corruption detected with output file name first!")
else()
    message(STATUS "SUCCESS: Lossless match verified with output file name first.")
endif()

# Clean up files from this stage
file(REMOVE "buffer_squeezed.bin" "buffer_restored.txt")

# =====================================================================
# STAGE 4: Output file name and input from stream
# =====================================================================
message(STATUS "Starting output file name and input from stream verification...")

# 1. Compress with output file name specified by an option
execute_process(
    COMMAND ${GKCOMP} -outfile "buffer_squeezed.bin"
    INPUT_FILE "buffer_original.txt"
    RESULT_VARIABLE cmd_res
)
if(NOT cmd_res EQUAL 0)
    message(FATAL_ERROR "Compression from stream failed with code ${cmd_res}")
endif()

# 2. Decompress with output file name specified by an option
execute_process(
    COMMAND ${GKDECOMP} -outfile "buffer_restored.txt"
    INPUT_FILE "buffer_squeezed.bin"
    RESULT_VARIABLE cmd_res
)
if(NOT cmd_res EQUAL 0)
    message(FATAL_ERROR "Decompression from stream failed with code ${cmd_res}")
endif()

# 3. Verify the file round-trip remains lossless
execute_process(
    COMMAND ${CMAKE_COMMAND} -E compare_files "buffer_original.txt" "buffer_restored.txt"
    RESULT_VARIABLE diff_res
)
if(diff_res)
    message(FATAL_ERROR "FAILURE: File corruption detected with output file name and input from stream!")
else()
    message(STATUS "SUCCESS: Lossless match verified with output file name and input from stream")
endif()

# Clean up files from this stage
file(REMOVE "buffer_squeezed.bin" "buffer_restored.txt")

# =====================================================================
# STAGE 5: Input from a stream and output to a stream
# =====================================================================
message(STATUS "Starting input from a stream and output to a stream verification...")

# 1. Compress with no file names
execute_process(
    COMMAND ${GKCOMP}
    INPUT_FILE "buffer_original.txt"
    OUTPUT_FILE "buffer_squeezed.bin"
    RESULT_VARIABLE cmd_res
)
if(NOT cmd_res EQUAL 0)
    message(FATAL_ERROR "Compression from/to stream failed with code ${cmd_res}.")
endif()

# 2. Decompress with no file names
execute_process(
    COMMAND ${GKDECOMP}
    INPUT_FILE "buffer_squeezed.bin"
    OUTPUT_FILE "buffer_restored.txt"
    RESULT_VARIABLE cmd_res
)
if(NOT cmd_res EQUAL 0)
    message(FATAL_ERROR "Decompression from/to stream failed with code ${cmd_res}.")
endif()

# 3. Verify the file round-trip remains lossless
execute_process(
    COMMAND ${CMAKE_COMMAND} -E compare_files "buffer_original.txt" "buffer_restored.txt"
    RESULT_VARIABLE diff_res
)
if(diff_res)
    message(FATAL_ERROR "FAILURE: File corruption detected with input from and output to stream!")
else()
    message(STATUS "SUCCESS: Lossless match verified with input from and output to stream")
endif()

# Clean up files from this stage
file(REMOVE "buffer_squeezed.bin" "buffer_restored.txt")

# =====================================================================
# STAGE 6: Input file name and output to stream
# =====================================================================
message(STATUS "Starting input file name and output to stream verification...")

# 1. Compress with no output file name
execute_process(
    COMMAND ${GKCOMP} "buffer_original.txt"
    OUTPUT_FILE "buffer_squeezed.bin"
    RESULT_VARIABLE cmd_res
)
if(NOT cmd_res EQUAL 0)
    message(FATAL_ERROR "Compression to stream failed with code ${cmd_res}")
endif()

# 2. Decompress with no output file name
execute_process(
    COMMAND ${GKDECOMP} "buffer_squeezed.bin"
    OUTPUT_FILE "buffer_restored.txt"
    RESULT_VARIABLE cmd_res
)
if(NOT cmd_res EQUAL 0)
    message(FATAL_ERROR "Decompression to stream failed with code ${cmd_res}")
endif()

# 3. Verify the file round-trip remains lossless
execute_process(
    COMMAND ${CMAKE_COMMAND} -E compare_files "buffer_original.txt" "buffer_restored.txt"
    RESULT_VARIABLE diff_res
)
if(diff_res)
    message(FATAL_ERROR "FAILURE: File corruption detected with input file name and output to stream!")
else()
    message(STATUS "SUCCESS: Lossless match verified with input file name and output to stream")
endif()

# Clean up files from this stage
file(REMOVE "buffer_squeezed.bin" "buffer_restored.txt")

# =====================================================================
# STAGE 7: Input file name and output filename are the same
# =====================================================================
message(STATUS "Starting same input and output filename verification...")

execute_process(COMMAND ${CMAKE_COMMAND} -E copy "buffer_original.txt" "buffer_copy.txt")

# 1. Compress with output file name same as input file name
execute_process(
    COMMAND ${GKCOMP} "buffer_copy.txt" "buffer_copy.txt"
    RESULT_VARIABLE cmd_res
)
if(NOT cmd_res EQUAL 0)
    message(FATAL_ERROR "Compression with same input and output filename failed with code ${cmd_res}")
endif()

# 2. Decompress with output file name same as input file name
execute_process(
    COMMAND ${GKDECOMP} "buffer_copy.txt" "buffer_copy.txt"
    RESULT_VARIABLE cmd_res
)
if(NOT cmd_res EQUAL 0)
    message(FATAL_ERROR "Decompression with same input and output filename failed with code ${cmd_res}")
endif()

# 3. Verify the file round-trip remains lossless
execute_process(
    COMMAND ${CMAKE_COMMAND} -E compare_files "buffer_original.txt" "buffer_copy.txt"
    RESULT_VARIABLE diff_res
)
if(diff_res)
    message(FATAL_ERROR "FAILURE: File corruption detected with same input and output filename!")
else()
    message(STATUS "SUCCESS: Lossless match verified with same input and output filename")
endif()

# Clean up global non-batch input artifact
file(REMOVE "buffer_copy.txt")

# =====================================================================
# STAGE 8: Input file name and output filename are the same but reversed
# =====================================================================
message(STATUS "Starting same but reversed input and output filename verification...")

execute_process(COMMAND ${CMAKE_COMMAND} -E copy "buffer_original.txt" "buffer_copy.txt")

# 1. Compress with output file name specified by an option
execute_process(
    COMMAND ${GKCOMP} -outfile "buffer_copy.txt" "buffer_copy.txt"
    RESULT_VARIABLE cmd_res
)
if(NOT cmd_res EQUAL 0)
    message(FATAL_ERROR "Compression with same but reversed input and output filename failed with code ${cmd_res}")
endif()

# 2. Decompress with output file name specified by an option
execute_process(
    COMMAND ${GKDECOMP} -outfile "buffer_copy.txt" "buffer_copy.txt"
    RESULT_VARIABLE cmd_res
)
if(NOT cmd_res EQUAL 0)
    message(FATAL_ERROR "Decompression with same but reversed input and output filename failed with code ${cmd_res}")
endif()

# 3. Verify the file round-trip remains lossless
execute_process(
    COMMAND ${CMAKE_COMMAND} -E compare_files "buffer_original.txt" "buffer_copy.txt"
    RESULT_VARIABLE diff_res
)
if(diff_res)
    message(FATAL_ERROR "FAILURE: File corruption detected with same but reversed input and output filename!")
else()
    message(STATUS "SUCCESS: Lossless match verified with same but reversed input and output filename")
endif()

# Clean up global non-batch input artifact
file(REMOVE "buffer_copy.txt")

# =====================================================================
# STAGE 9: Batch In-Place Processing with one file
# =====================================================================
message(STATUS "Starting Batch In-Place Processing with One File Verification...")

execute_process(COMMAND ${CMAKE_COMMAND} -E copy "buffer_original.txt" "buffer_copy.txt")

# 1. Compress with output file name specified by an option
execute_process(
    COMMAND ${GKCOMP} -batch "buffer_copy.txt"
    RESULT_VARIABLE cmd_res
)
if(NOT cmd_res EQUAL 0)
    message(FATAL_ERROR "Compression with Batch In-Place Processing with One File failed with code ${cmd_res}")
endif()

# 2. Decompress with output file name specified by an option
execute_process(
    COMMAND ${GKDECOMP} -batch "buffer_copy.txt"
    RESULT_VARIABLE cmd_res
)
if(NOT cmd_res EQUAL 0)
    message(FATAL_ERROR "Decompression with Batch In-Place Processing with One File failed with code ${cmd_res}")
endif()

# 3. Verify the file round-trip remains lossless
execute_process(
    COMMAND ${CMAKE_COMMAND} -E compare_files "buffer_original.txt" "buffer_copy.txt"
    RESULT_VARIABLE diff_res
)
if(diff_res)
    message(FATAL_ERROR "FAILURE: File corruption detected with Batch In-Place Processing with One File!")
else()
    message(STATUS "SUCCESS: Lossless match verified with Batch In-Place Processing with One File")
endif()

# =====================================================================
# STAGE 11: Help text
# =====================================================================
message(STATUS "Starting Help Verification...")
execute_process(COMMAND ${GKCOMP} -help RESULT_VARIABLE cmd_res OUTPUT_VARIABLE comp_stdout)
if(NOT cmd_res EQUAL 0)
    message(FATAL_ERROR "Compression help failed with exit code ${cmd_res}")
endif()

# Check that the output contains the exact help string
if(NOT comp_stdout MATCHES "usage: gkcomp \\[switches\\] inputfile \\[outputfile\\]")
    message(FATAL_ERROR "Failure: unexpected help message. Received: '${comp_stdout}'")
else()
    message(STATUS "Success: help message verified.")
endif()

execute_process(COMMAND ${GKDECOMP} -help RESULT_VARIABLE cmd_res OUTPUT_VARIABLE decomp_stdout)
if(NOT cmd_res EQUAL 0)
    message(FATAL_ERROR "Decompression help failed with exit code ${cmd_res}")
endif()

# Check that the output contains the exact help string
if(NOT decomp_stdout MATCHES "usage: gkdecomp \\[switches\\] inputfile \\[outputfile\\]")
    message(FATAL_ERROR "Failure: unexpected help message. Received: '${decomp_stdout}'")
else()
    message(STATUS "Success: help message verified.")
endif()

# =====================================================================
# STAGE 12: Timed operations
# =====================================================================
message(STATUS "Starting Timed Operations Verification...")

# 1. Time compress with no output filename
execute_process(
    COMMAND ${GKCOMP} -time "buffer_original.txt"
    RESULT_VARIABLE cmd_res
    ERROR_VARIABLE comp_stderr
)
if(cmd_res EQUAL 0)
    message(FATAL_ERROR "Timed compression unexpectedly succeeded")
endif()

# Check that the stderr output contains the exact error string
if(NOT comp_stderr MATCHES "Must specify an output file in verbose/timer mode")
    message(FATAL_ERROR "Failure: unexpected error output. Received: '${comp_stderr}'")
else()
    message(STATUS "Success: error output message verified.")
endif()

# 2. Time compress with an output filename
execute_process(
    COMMAND ${GKCOMP} -time "buffer_original.txt" "buffer_squeezed.bin"
    OUTPUT_VARIABLE comp_stdout
    RESULT_VARIABLE cmd_res
)
if(NOT cmd_res EQUAL 0)
    message(FATAL_ERROR "Timed compression failed with code ${cmd_res}")
endif()

if(NOT comp_stdout MATCHES "Time taken: [0-9]+\\.[0-9]+ seconds")
    message(FATAL_ERROR "Failure: compression time output format is invalid. Received: '${comp_stdout}'")
else()
    message(STATUS "Success: compression time output format verified.")
endif()

# 3. Time decompress with no output filename
execute_process(
    COMMAND ${GKDECOMP} -time "buffer_squeezed.bin"
    RESULT_VARIABLE cmd_res
    ERROR_VARIABLE decomp_stderr
)
if(cmd_res EQUAL 0)
    message(FATAL_ERROR "Timed decompression unexpectedly succeeded")
endif()

# Check that the stderr output contains the exact error string
if(NOT decomp_stderr MATCHES "Must specify an output file in verbose/timer mode")
    message(FATAL_ERROR "Failure: unexpected error output. Received: '${decomp_stderr}'")
else()
    message(STATUS "Success: error output message verified.")
endif()

# 4. Time decompress with an output filename
execute_process(
    COMMAND ${GKDECOMP} -time "buffer_squeezed.bin" "buffer_restored.txt"
    OUTPUT_VARIABLE decomp_stdout
    RESULT_VARIABLE cmd_res
)
if(NOT cmd_res EQUAL 0)
    message(FATAL_ERROR "Timed decompression failed with code ${cmd_res}")
endif()

if(NOT decomp_stdout MATCHES "Time taken: [0-9]+\\.[0-9]+ seconds")
    message(FATAL_ERROR "Failure: decompression time output format is invalid. Received: '${decomp_stdout}'")
else()
    message(STATUS "Success: decompression time output format verified.")
endif()

# 5. Verify the file round-trip remains lossless
execute_process(
    COMMAND ${CMAKE_COMMAND} -E compare_files "buffer_original.txt" "buffer_restored.txt"
    RESULT_VARIABLE diff_res
)
if(diff_res)
    message(FATAL_ERROR "FAILURE: File corruption detected with timed operations!")
else()
    message(STATUS "SUCCESS: Lossless match verified with timed operations")
endif()

# Clean up files from this stage
file(REMOVE "buffer_squeezed.bin" "buffer_restored.txt")

# =====================================================================
# STAGE 12: Verbose output
# =====================================================================
message(STATUS "Starting Verbose Operations Verification...")

# 1. Verbose compress with no output filename
execute_process(
    COMMAND ${GKCOMP} -verbose "buffer_original.txt"
    RESULT_VARIABLE cmd_res
    ERROR_VARIABLE comp_stderr
)
if(cmd_res EQUAL 0)
    message(FATAL_ERROR "Verbose compression unexpectedly succeeded")
endif()

# Check that the stderr output contains the exact error string
if(NOT comp_stderr MATCHES "Must specify an output file in verbose/timer mode")
    message(FATAL_ERROR "Failure: unexpected error output. Received: '${comp_stderr}'")
else()
    message(STATUS "Success: error output message verified.")
endif()

# 2. Verbose compress with an output filename
execute_process(
    COMMAND ${GKCOMP} -verbose "buffer_original.txt" "buffer_squeezed.bin"
    OUTPUT_VARIABLE comp_stdout
    RESULT_VARIABLE cmd_res
)
if(NOT cmd_res EQUAL 0)
    message(FATAL_ERROR "Verbose compression failed with code ${cmd_res}")
endif()

# 3. Verbose decompress with no output filename
execute_process(
    COMMAND ${GKDECOMP} -verbose "buffer_squeezed.bin"
    RESULT_VARIABLE cmd_res
    ERROR_VARIABLE decomp_stderr
)
if(cmd_res EQUAL 0)
    message(FATAL_ERROR "Timed decompression unexpectedly succeeded")
endif()

# Check that the stderr output contains the exact error string
if(NOT decomp_stderr MATCHES "Must specify an output file in verbose/timer mode")
    message(FATAL_ERROR "Failure: unexpected error output. Received: '${decomp_stderr}'")
else()
    message(STATUS "Success: error output message verified.")
endif()

# 4. Verbose decompress with an output filename
execute_process(
    COMMAND ${GKDECOMP} -verbose "buffer_squeezed.bin" "buffer_restored.txt"
    OUTPUT_VARIABLE decomp_stdout
    RESULT_VARIABLE cmd_res
)
if(NOT cmd_res EQUAL 0)
    message(FATAL_ERROR "Timed decompression failed with code ${cmd_res}")
endif()

# =====================================================================
# STAGE 13: Debug output
# =====================================================================
message(STATUS "Starting Debug Operations Verification...")

# 1. Debug compress with no output filename
execute_process(
    COMMAND ${GKCOMP} -debug "buffer_original.txt"
    RESULT_VARIABLE cmd_res
    ERROR_VARIABLE comp_stderr
)
if(cmd_res EQUAL 0)
    message(FATAL_ERROR "Debug compression unexpectedly succeeded")
endif()

# Check that the stderr output contains the exact error string
if(NOT comp_stderr MATCHES "Must specify an output file in verbose/timer mode")
    message(FATAL_ERROR "Failure: unexpected error output. Received: '${comp_stderr}'")
else()
    message(STATUS "Success: error output message verified.")
endif()

# 2. Debug compress with an output filename
execute_process(
    COMMAND ${GKCOMP} -debug "buffer_original.txt" "buffer_squeezed.bin"
    OUTPUT_VARIABLE comp_stdout
    RESULT_VARIABLE cmd_res
)
if(NOT cmd_res EQUAL 0)
    message(FATAL_ERROR "Debug compression failed with code ${cmd_res}")
endif()

# 3. Debug decompress with no output filename
execute_process(
    COMMAND ${GKDECOMP} -debug "buffer_squeezed.bin"
    RESULT_VARIABLE cmd_res
    ERROR_VARIABLE decomp_stderr
)
if(cmd_res EQUAL 0)
    message(FATAL_ERROR "Debug decompression unexpectedly succeeded")
endif()

# Check that the stderr output contains the exact error string
if(NOT decomp_stderr MATCHES "Must specify an output file in verbose/timer mode")
    message(FATAL_ERROR "Failure: unexpected error output. Received: '${decomp_stderr}'")
else()
    message(STATUS "Success: error output message verified.")
endif()

# 4. Debug decompress with an output filename
execute_process(
    COMMAND ${GKDECOMP} -debug "buffer_squeezed.bin" "buffer_restored.txt"
    OUTPUT_VARIABLE decomp_stdout
    RESULT_VARIABLE cmd_res
)
if(NOT cmd_res EQUAL 0)
    message(FATAL_ERROR "Debug decompression failed with code ${cmd_res}")
endif()










# =====================================================================
# STAGE 14: Non-Batch Mode Testing with a Variety of History Buffer Sizes
# =====================================================================

# Define base-2 logarithm history values to test (0=1B, 4=16B, 9=512B default, 12=4KB)
set(HISTORY_VALUES 0 4 9 12 14 16 20)

foreach(HIST_VAL ${HISTORY_VALUES})
    message(STATUS "Testing Non-Batch Mode with History Size: Log2(${HIST_VAL})...")

    # 1. Compress using current history log-2 value
    execute_process(
        COMMAND ${GKCOMP} -hi ${HIST_VAL} "buffer_original.txt" "buffer_squeezed.bin"
        RESULT_VARIABLE cmd_res
    )
    if(NOT cmd_res EQUAL 0)
        message(FATAL_ERROR "Compression failed at history value ${HIST_VAL} with code ${cmd_res}")
    endif()

    # 2. Decompress using current history log-2 value
    execute_process(
        COMMAND ${GKDECOMP} -hi ${HIST_VAL} "buffer_squeezed.bin" "buffer_restored.txt"
        RESULT_VARIABLE cmd_res
    )
    if(NOT cmd_res EQUAL 0)
        message(FATAL_ERROR "Decompression failed for history value ${HIST_VAL} with code ${cmd_res}")
    endif()

    # 3. Verify the file round-trip remains lossless
    execute_process(
        COMMAND ${CMAKE_COMMAND} -E compare_files "buffer_original.txt" "buffer_restored.txt"
        RESULT_VARIABLE diff_res
    )
    if(diff_res)
        message(FATAL_ERROR "FAILURE: File corruption detected using history value ${HIST_VAL}!")
    else()
        message(STATUS "SUCCESS: Lossless match verified for history value ${HIST_VAL}.")
    endif()

    # Clean up files from this loop step
    file(REMOVE "buffer_squeezed.bin" "buffer_restored.txt")
endforeach()

# =====================================================================
# STAGE 15: Output file name before input file name
# =====================================================================
message(STATUS "Starting output file name before input file name verification...")

# 1. Compress with output file name specified by an option
execute_process(
    COMMAND ${GKCOMP} -o "buffer_squeezed.bin" "buffer_original.txt"
    RESULT_VARIABLE cmd_res
)
if(NOT cmd_res EQUAL 0)
    message(FATAL_ERROR "Compression with output file name first failed with code ${cmd_res}")
endif()

# 2. Decompress with output file name specified by an option
execute_process(
    COMMAND ${GKDECOMP} -o "buffer_restored.txt" "buffer_squeezed.bin"
    RESULT_VARIABLE cmd_res
)
if(NOT cmd_res EQUAL 0)
    message(FATAL_ERROR "Decompression with output file name first failed with code ${cmd_res}")
endif()

# 3. Verify the file round-trip remains lossless
execute_process(
    COMMAND ${CMAKE_COMMAND} -E compare_files "buffer_original.txt" "buffer_restored.txt"
    RESULT_VARIABLE diff_res
)
if(diff_res)
    message(FATAL_ERROR "FAILURE: File corruption detected with output file name first!")
else()
    message(STATUS "SUCCESS: Lossless match verified with output file name first.")
endif()

# Clean up files from this stage
file(REMOVE "buffer_squeezed.bin" "buffer_restored.txt")

# =====================================================================
# STAGE 16: Output file name and input from stream
# =====================================================================
message(STATUS "Starting output file name and input from stream verification...")

# 1. Compress with output file name specified by an option
execute_process(
    COMMAND ${GKCOMP} -o "buffer_squeezed.bin"
    INPUT_FILE "buffer_original.txt"
    RESULT_VARIABLE cmd_res
)
if(NOT cmd_res EQUAL 0)
    message(FATAL_ERROR "Compression from stream failed with code ${cmd_res}")
endif()

# 2. Decompress with output file name specified by an option
execute_process(
    COMMAND ${GKDECOMP} -outfile "buffer_restored.txt"
    INPUT_FILE "buffer_squeezed.bin"
    RESULT_VARIABLE cmd_res
)
if(NOT cmd_res EQUAL 0)
    message(FATAL_ERROR "Decompression from stream failed with code ${cmd_res}")
endif()

# 3. Verify the file round-trip remains lossless
execute_process(
    COMMAND ${CMAKE_COMMAND} -E compare_files "buffer_original.txt" "buffer_restored.txt"
    RESULT_VARIABLE diff_res
)
if(diff_res)
    message(FATAL_ERROR "FAILURE: File corruption detected with output file name and input from stream!")
else()
    message(STATUS "SUCCESS: Lossless match verified with output file name and input from stream")
endif()

# Clean up files from this stage
file(REMOVE "buffer_squeezed.bin" "buffer_restored.txt")

# =====================================================================
# STAGE 17: Batch In-Place Processing with one file
# =====================================================================
message(STATUS "Starting Batch In-Place Processing with One File Verification...")

execute_process(COMMAND ${CMAKE_COMMAND} -E copy "buffer_original.txt" "buffer_copy.txt")

# 1. Compress with output file name specified by an option
execute_process(
    COMMAND ${GKCOMP} -b "buffer_copy.txt"
    RESULT_VARIABLE cmd_res
)
if(NOT cmd_res EQUAL 0)
    message(FATAL_ERROR "Compression with Batch In-Place Processing with One File failed with code ${cmd_res}")
endif()

# 2. Decompress with output file name specified by an option
execute_process(
    COMMAND ${GKDECOMP} -b "buffer_copy.txt"
    RESULT_VARIABLE cmd_res
)
if(NOT cmd_res EQUAL 0)
    message(FATAL_ERROR "Decompression with Batch In-Place Processing with One File failed with code ${cmd_res}")
endif()

# 3. Verify the file round-trip remains lossless
execute_process(
    COMMAND ${CMAKE_COMMAND} -E compare_files "buffer_original.txt" "buffer_copy.txt"
    RESULT_VARIABLE diff_res
)
if(diff_res)
    message(FATAL_ERROR "FAILURE: File corruption detected with Batch In-Place Processing with One File!")
else()
    message(STATUS "SUCCESS: Lossless match verified with Batch In-Place Processing with One File")
endif()

# =====================================================================
# STAGE 18: Help text
# =====================================================================
message(STATUS "Starting Help Verification...")
execute_process(COMMAND ${GKCOMP} -he RESULT_VARIABLE cmd_res OUTPUT_VARIABLE comp_stdout)
if(NOT cmd_res EQUAL 0)
    message(FATAL_ERROR "Compression help failed with exit code ${cmd_res}")
endif()

# Check that the output contains the exact help string
if(NOT comp_stdout MATCHES "usage: gkcomp \\[switches\\] inputfile \\[outputfile\\]")
    message(FATAL_ERROR "Failure: unexpected help message. Received: '${comp_stdout}'")
else()
    message(STATUS "Success: help message verified.")
endif()

execute_process(COMMAND ${GKDECOMP} -he RESULT_VARIABLE cmd_res OUTPUT_VARIABLE decomp_stdout)
if(NOT cmd_res EQUAL 0)
    message(FATAL_ERROR "Decompression help failed with exit code ${cmd_res}")
endif()

# Check that the output contains the exact help string
if(NOT decomp_stdout MATCHES "usage: gkdecomp \\[switches\\] inputfile \\[outputfile\\]")
    message(FATAL_ERROR "Failure: unexpected help message. Received: '${decomp_stdout}'")
else()
    message(STATUS "Success: help message verified.")
endif()

# =====================================================================
# STAGE 19: Timed operations
# =====================================================================
message(STATUS "Starting Timed Operations Verification...")

# 1. Time compress with no output filename
execute_process(
    COMMAND ${GKCOMP} -t "buffer_original.txt"
    RESULT_VARIABLE cmd_res
    ERROR_VARIABLE comp_stderr
)
if(cmd_res EQUAL 0)
    message(FATAL_ERROR "Timed compression unexpectedly succeeded")
endif()

# Check that the stderr output contains the exact error string
if(NOT comp_stderr MATCHES "Must specify an output file in verbose/timer mode")
    message(FATAL_ERROR "Failure: unexpected error output. Received: '${comp_stderr}'")
else()
    message(STATUS "Success: error output message verified.")
endif()

# 2. Time compress with an output filename
execute_process(
    COMMAND ${GKCOMP} -t "buffer_original.txt" "buffer_squeezed.bin"
    OUTPUT_VARIABLE comp_stdout
    RESULT_VARIABLE cmd_res
)
if(NOT cmd_res EQUAL 0)
    message(FATAL_ERROR "Timed compression failed with code ${cmd_res}")
endif()

if(NOT comp_stdout MATCHES "Time taken: [0-9]+\\.[0-9]+ seconds")
    message(FATAL_ERROR "Failure: compression time output format is invalid. Received: '${comp_stdout}'")
else()
    message(STATUS "Success: compression time output format verified.")
endif()

# 3. Time decompress with no output filename
execute_process(
    COMMAND ${GKDECOMP} -t "buffer_squeezed.bin"
    RESULT_VARIABLE cmd_res
    ERROR_VARIABLE decomp_stderr
)
if(cmd_res EQUAL 0)
    message(FATAL_ERROR "Timed decompression unexpectedly succeeded")
endif()

# Check that the stderr output contains the exact error string
if(NOT decomp_stderr MATCHES "Must specify an output file in verbose/timer mode")
    message(FATAL_ERROR "Failure: unexpected error output. Received: '${decomp_stderr}'")
else()
    message(STATUS "Success: error output message verified.")
endif()

# 4. Time decompress with an output filename
execute_process(
    COMMAND ${GKDECOMP} -t "buffer_squeezed.bin" "buffer_restored.txt"
    OUTPUT_VARIABLE decomp_stdout
    RESULT_VARIABLE cmd_res
)
if(NOT cmd_res EQUAL 0)
    message(FATAL_ERROR "Timed decompression failed with code ${cmd_res}")
endif()

if(NOT decomp_stdout MATCHES "Time taken: [0-9]+\\.[0-9]+ seconds")
    message(FATAL_ERROR "Failure: decompression time output format is invalid. Received: '${decomp_stdout}'")
else()
    message(STATUS "Success: decompression time output format verified.")
endif()

# 5. Verify the file round-trip remains lossless
execute_process(
    COMMAND ${CMAKE_COMMAND} -E compare_files "buffer_original.txt" "buffer_restored.txt"
    RESULT_VARIABLE diff_res
)
if(diff_res)
    message(FATAL_ERROR "FAILURE: File corruption detected with timed operations!")
else()
    message(STATUS "SUCCESS: Lossless match verified with timed operations")
endif()

# Clean up files from this stage
file(REMOVE "buffer_squeezed.bin" "buffer_restored.txt")

# =====================================================================
# STAGE 20: Verbose output
# =====================================================================
message(STATUS "Starting Verbose Operations Verification...")

# 1. Verbose compress with no output filename
execute_process(
    COMMAND ${GKCOMP} -v "buffer_original.txt"
    RESULT_VARIABLE cmd_res
    ERROR_VARIABLE comp_stderr
)
if(cmd_res EQUAL 0)
    message(FATAL_ERROR "Verbose compression unexpectedly succeeded")
endif()

# Check that the stderr output contains the exact error string
if(NOT comp_stderr MATCHES "Must specify an output file in verbose/timer mode")
    message(FATAL_ERROR "Failure: unexpected error output. Received: '${comp_stderr}'")
else()
    message(STATUS "Success: error output message verified.")
endif()

# 2. Verbose compress with an output filename
execute_process(
    COMMAND ${GKCOMP} -v "buffer_original.txt" "buffer_squeezed.bin"
    OUTPUT_VARIABLE comp_stdout
    RESULT_VARIABLE cmd_res
)
if(NOT cmd_res EQUAL 0)
    message(FATAL_ERROR "Verbose compression failed with code ${cmd_res}")
endif()

if(NOT comp_stdout MATCHES "Compression ratio [0-9]+\\.[0-9]+% \\([0-9]+ bytes in, [0-9]+ bytes out\\)")
    message(FATAL_ERROR "Failure: compression verbose output format is invalid. Received: '${comp_stdout}'")
else()
    message(STATUS "Success: compression verbose output format verified.")
endif()

# 3. Verbose decompress with no output filename
execute_process(
    COMMAND ${GKDECOMP} -v "buffer_squeezed.bin"
    RESULT_VARIABLE cmd_res
    ERROR_VARIABLE decomp_stderr
)
if(cmd_res EQUAL 0)
    message(FATAL_ERROR "Timed decompression unexpectedly succeeded")
endif()

# Check that the stderr output contains the exact error string
if(NOT decomp_stderr MATCHES "Must specify an output file in verbose/timer mode")
    message(FATAL_ERROR "Failure: unexpected error output. Received: '${decomp_stderr}'")
else()
    message(STATUS "Success: error output message verified.")
endif()

# 4. Verbose decompress with an output filename
execute_process(
    COMMAND ${GKDECOMP} -v "buffer_squeezed.bin" "buffer_restored.txt"
    OUTPUT_VARIABLE decomp_stdout
    RESULT_VARIABLE cmd_res
)
if(NOT cmd_res EQUAL 0)
    message(FATAL_ERROR "Timed decompression failed with code ${cmd_res}")
endif()

if(NOT decomp_stdout MATCHES "Compression ratio [0-9]+\\.[0-9]+% \\([0-9]+ bytes in, [0-9]+ bytes out\\)")
    message(FATAL_ERROR "Failure: decompression verbose output format is invalid. Received: '${decomp_stdout}'")
else()
    message(STATUS "Success: decompression verbose output format verified.")
endif()

# Clean up files from this stage
file(REMOVE "buffer_squeezed.bin" "buffer_restored.txt")

# =====================================================================
# STAGE 21: Debug output
# =====================================================================
message(STATUS "Starting Debug Operations Verification...")

# 1. Debug compress with no output filename
execute_process(
    COMMAND ${GKCOMP} -d "buffer_original.txt"
    RESULT_VARIABLE cmd_res
    ERROR_VARIABLE comp_stderr
)
if(cmd_res EQUAL 0)
    message(FATAL_ERROR "Debug compression unexpectedly succeeded")
endif()

# Check that the stderr output contains the exact error string
if(NOT comp_stderr MATCHES "Must specify an output file in verbose/timer mode")
    message(FATAL_ERROR "Failure: unexpected error output. Received: '${comp_stderr}'")
else()
    message(STATUS "Success: error output message verified.")
endif()

# 2. Debug compress with an output filename
execute_process(
    COMMAND ${GKCOMP} -d "buffer_original.txt" "buffer_squeezed.bin"
    OUTPUT_VARIABLE comp_stdout
    RESULT_VARIABLE cmd_res
)
if(NOT cmd_res EQUAL 0)
    message(FATAL_ERROR "Debug compression failed with code ${cmd_res}")
endif()

if(NOT comp_stdout MATCHES "Compression ratio [0-9]+\\.[0-9]+% \\([0-9]+ bytes in, [0-9]+ bytes out\\)")
    message(FATAL_ERROR "Failure: compression verbose output format is invalid. Received: '${comp_stdout}'")
else()
    message(STATUS "Success: compression verbose output format verified.")
endif()

# 3. Debug decompress with no output filename
execute_process(
    COMMAND ${GKDECOMP} -d "buffer_squeezed.bin"
    RESULT_VARIABLE cmd_res
    ERROR_VARIABLE decomp_stderr
)
if(cmd_res EQUAL 0)
    message(FATAL_ERROR "Debug decompression unexpectedly succeeded")
endif()

# Check that the stderr output contains the exact error string
if(NOT decomp_stderr MATCHES "Must specify an output file in verbose/timer mode")
    message(FATAL_ERROR "Failure: unexpected error output. Received: '${decomp_stderr}'")
else()
    message(STATUS "Success: error output message verified.")
endif()

# 4. Debug decompress with an output filename
execute_process(
    COMMAND ${GKDECOMP} -d "buffer_squeezed.bin" "buffer_restored.txt"
    OUTPUT_VARIABLE decomp_stdout
    RESULT_VARIABLE cmd_res
)
if(NOT cmd_res EQUAL 0)
    message(FATAL_ERROR "Debug decompression failed with code ${cmd_res}")
endif()

if(NOT decomp_stdout MATCHES "Compression ratio [0-9]+\\.[0-9]+% \\([0-9]+ bytes in, [0-9]+ bytes out\\)")
    message(FATAL_ERROR "Failure: decompression verbose output format is invalid. Received: '${decomp_stdout}'")
else()
    message(STATUS "Success: decompression verbose output format verified.")
endif()

# Clean up files from this stage
file(REMOVE "buffer_squeezed.bin" "buffer_restored.txt")

# =====================================================================
# STAGE 22: Missing history operand
# =====================================================================
message(STATUS "Starting Missing history operand Verification...")

# 1. Compress with missing history operand
execute_process(
    COMMAND ${GKCOMP} -history "buffer_original.txt" "buffer_squeezed.bin"
    RESULT_VARIABLE cmd_res
    ERROR_VARIABLE comp_stderr
)
if(cmd_res EQUAL 0)
    message(FATAL_ERROR "Compression unexpectedly succeeded")
endif()

# Check that the stderr output contains the exact error string
if(NOT comp_stderr MATCHES "Missing value for history")
    message(FATAL_ERROR "Failure: unexpected error output. Received: '${comp_stderr}'")
else()
    message(STATUS "Success: error output message verified.")
endif()

# 2. Compress with history operand
execute_process(
    COMMAND ${GKCOMP} -history 9 "buffer_original.txt" "buffer_squeezed.bin"
    RESULT_VARIABLE cmd_res
)
if(NOT cmd_res EQUAL 0)
    message(FATAL_ERROR "Compression failed with code ${cmd_res}")
endif()

# 3. Decompress with missing history operand
execute_process(
    COMMAND ${GKDECOMP} -history "buffer_squeezed.bin" "buffer_restored.txt"
    RESULT_VARIABLE cmd_res
    ERROR_VARIABLE decomp_stderr
)
if(cmd_res EQUAL 0)
    message(FATAL_ERROR "Decompression unexpectedly succeeded")
endif()

# Check that the stderr output contains the exact error string
if(NOT decomp_stderr MATCHES "Missing value for history")
    message(FATAL_ERROR "Failure: unexpected error output. Received: '${decomp_stderr}'")
else()
    message(STATUS "Success: error output message verified.")
endif()

# 4. Decompress with history operand
execute_process(
    COMMAND ${GKDECOMP} -history 9 "buffer_squeezed.bin" "buffer_restored.txt"
    RESULT_VARIABLE cmd_res
)
if(NOT cmd_res EQUAL 0)
    message(FATAL_ERROR "Decompression failed with code ${cmd_res}")
endif()

# Clean up files from this stage
file(REMOVE "buffer_squeezed.bin" "buffer_restored.txt")

# =====================================================================
# STAGE 23: Invalid Switches
# =====================================================================
message(STATUS "Starting Invalid Switch Verification...")

# 1. Compress with invalid switch
execute_process(
    COMMAND ${GKCOMP} -verboid "buffer_original.txt" "buffer_squeezed.bin"
    RESULT_VARIABLE cmd_res
    ERROR_VARIABLE comp_stderr
)
if(cmd_res EQUAL 0)
    message(FATAL_ERROR "Compression unexpectedly succeeded")
endif()

# Check that the stderr output contains the exact error string
if(NOT comp_stderr MATCHES "Unrecognised switch 'verboid'")
    message(FATAL_ERROR "Failure: unexpected error output. Received: '${comp_stderr}'")
else()
    message(STATUS "Success: error output message verified.")
endif()

# 2. Compress
execute_process(
    COMMAND ${GKCOMP} "buffer_original.txt" "buffer_squeezed.bin"
    RESULT_VARIABLE cmd_res
)
if(NOT cmd_res EQUAL 0)
    message(FATAL_ERROR "Compression failed with code ${cmd_res}")
endif()

# 3. Decompress with invalid switch
execute_process(
    COMMAND ${GKDECOMP} -verboid "buffer_squeezed.bin" "buffer_restored.txt"
    RESULT_VARIABLE cmd_res
    ERROR_VARIABLE decomp_stderr
)
if(cmd_res EQUAL 0)
    message(FATAL_ERROR "Decompression unexpectedly succeeded")
endif()

# Check that the stderr output contains the exact error string
if(NOT decomp_stderr MATCHES "Unrecognised switch 'verboid'")
    message(FATAL_ERROR "Failure: unexpected error output. Received: '${decomp_stderr}'")
else()
    message(STATUS "Success: error output message verified.")
endif()

# 4. Decompress
execute_process(
    COMMAND ${GKDECOMP} "buffer_squeezed.bin" "buffer_restored.txt"
    RESULT_VARIABLE cmd_res
)
if(NOT cmd_res EQUAL 0)
    message(FATAL_ERROR "Decompression failed with code ${cmd_res}")
endif()

# Clean up files from this stage
file(REMOVE "buffer_squeezed.bin" "buffer_restored.txt")




# Clean up global non-batch input artifact
file(REMOVE "buffer_copy.txt")
