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

# Run the tests and transform to results
if [ -f "${input_dir}/t/${slug}.t" ]; then
    test_file="${input_dir}/t/${slug}.t"
else
    test_file="${input_dir}/${slug}.t"
fi
chmod +x $test_file
HARNESS_ACTIVE=1 PERL5OPT='-MXXX=-global' unbuffer perl -I"${input_dir}/lib" -I"${input_dir}/local/lib/perl5" $test_file 2>&1 | tap-parser -j 0 > "${output_dir}/tap.json"
bin/transform-results.pl "${output_dir}/tap.json" "${results_file}" $test_file

echo "${slug}: done"
