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

echo "${slug}: testing..."

# Run the tests and output to log.jsonl
yath test "${input_dir}/${slug}.t" -qq --log-file $input_dir/log.jsonl

# Transform log data to expected output
cat $input_dir/log.jsonl | jq --slurp '
  {
    version:   2,
    exit_code: (.[].facet_data.harness_job_exit.code // empty),
    message:   (.[].facet_data.harness_job_exit.stderr // empty),
    tests:     ([.[].facet_data | if .assert.pass == 1 then {name: .assert.details, status: "pass"} elif .assert.pass == 0 then {name: .assert.details, status: "fail", message: .info[0].details} else empty end])
  } | if .tests[0] and .exit_code == "0" then
    {version, status: "pass", tests}
  elif .tests[0] and .exit_code != "255" then
    {version, status: "fail", tests}
  elif .tests[0] then
    {version, status: "error", message, tests}
  else
    {version, status: "error", message}
  end
' > ${results_file}

echo "${slug}: done"
