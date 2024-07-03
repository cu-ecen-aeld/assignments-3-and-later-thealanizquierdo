#!/bin/bash
# Tester script for assignment 1 and assignment 2
# Author: Siddhant Jajoo

set -e
set -u

NUMFILES=10
WRITESTR=AELD_IS_FUN
WRITEDIR=/tmp/aeld-data
username=$(cat conf/username.txt)

if [ $# -lt 3 ]; then
    echo "Using default value '${WRITESTR}' for string to write"
    if [ $# -lt 1 ]; then
        echo "Using default value '${NUMFILES}' for number of files to write"
    else
        NUMFILES=$1
    fi
else
    NUMFILES=$1
    WRITESTR=$2
    WRITEDIR=$3
fi

MATCHSTR="The number of files are ${NUMFILES} and the number of matching lines are ${NUMFILES}"

echo "Writing ${NUMFILES} files containing string '${WRITESTR}' to '${WRITEDIR}'"

# Clean previous build artifacts
make clean

# Compile writer using native compilation
make

# Function to write files
write_files() {
    local num_files="$1"
    local write_str="$2"
    local write_dir="$3"

    rm -rf "${write_dir}"
    mkdir -p "${write_dir}"

    if [ ! -d "${write_dir}" ]; then
        echo "Failed to create ${write_dir}"
        exit 1
    fi

    for (( i=1; i<=num_files; i++ ))
    do
        echo "Writing file: ${write_dir}/${username}${i}.txt"
        ./writer "${write_dir}/${username}${i}.txt" "${write_str}"
    done
}

# Call the function to write files
write_files "${NUMFILES}" "${WRITESTR}" "${WRITEDIR}"

# Uncomment the find_files function and its call once implemented
# Function to find files
# find_files() {
#     local find_dir="$1"
#     local find_str="$2"

#     # Example logic to find files
#     # Replace with your actual implementation
#     for file in "${find_dir}"/*; do
#         if [ -f "$file" ]; then
#             grep -q "${find_str}" "$file" && echo "$file"
#         fi
#     done
# }

# Call the function to find files
# find_files "${WRITEDIR}" "${WRITESTR}"

# Example output check (commented out for now)
# set +e
# OUTPUTSTRING=$(./finder-app/finder.sh "${WRITEDIR}" "${WRITESTR}")
# echo "${OUTPUTSTRING}" | grep "${MATCHSTR}"
# if [ $? -eq 0 ]; then
#     echo "Success: Found '${MATCHSTR}' in output"
#     exit 0
# else
#     echo "Failed: Expected '${MATCHSTR}' in output but instead found"
#     echo "${OUTPUTSTRING}"
#     exit 1
# fi
