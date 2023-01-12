#!/usr/bin/env sh

# Synopsis:
# Run the test runner on a solution.

# Arguments:
# $1: exercise slug
# $2: absolute path to solution folder
# $3: absolute path to output directory

# Output:
# Writes the test results to a results.json file in the passed-in output directory.
# The test results are formatted according to the specifications at https://github.com/exercism/docs/blob/main/building/tooling/test-runners/interface.md

# Example:
# ./bin/run.sh two-fer /absolute/path/to/two-fer/solution/folder/ /absolute/path/to/output/directory/

# If any required arguments is missing, print the usage and exit
if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
    echo "usage: ./bin/run.sh exercise-slug /absolute/path/to/two-fer/solution/folder/ /absolute/path/to/output/directory/"
    exit 1
fi

slug="$1"
input_dir="${2%/}"
output_dir="${3%/}"
results_file="${output_dir}/results.json"

# Create the output directory if it doesn't exist
mkdir -p "${output_dir}"

# Install modules from vendor/cache
if [ -f "$input_dir/cpanfile" ] && [ -f "$input_dir/vendor/cache/modules/02packages.details.txt.gz" ]; then
    cd $input_dir
    HOME=$PWD cpm install --resolver "02packages,file://$input_dir/vendor/cache" --with-recommends --with-suggests --snapshot /dev/null --show-build-log-on-failure
    cd -
fi

echo "${slug}: testing..."

# Move to /tmp for log file creation
cd /tmp
# Run the tests and output to log.jsonl
yath test "${input_dir}/${slug}.t" -qq --log-file /tmp/log.jsonl
# Move back
cd -
# Transform log data to expected output
cat /tmp/log.jsonl | bin/transform_logs.pl > ${results_file}

echo "${slug}: done"
