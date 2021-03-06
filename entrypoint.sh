#!/bin/sh

# Copy the matcher to the host system; otherwise "add-matcher" can't find it.
cp /code/flake8-matcher.json /github/workflow/flake8-matcher.json
echo "::add-matcher::${RUNNER_TEMP}/_github_workflow/flake8-matcher.json"

# Run flake8. We add 'error/warning' as GitHub Actions ProblemMatcher needs
# the text 'error/warning' to know how to classify it.
# The weird piping is needed because we want to get the exitcode from flake8,
# but there is no other good universal way of doing so.
# e.g. PIPESTATUS and pipestatus only work in bash/zsh respectively.
echo "Running flake8 on '${INPUT_PATH}' with the following options..."
command_args=""
echo "Ignoring '${INPUT_IGNORE}'"
if [ "x${INPUT_IGNORE}" != "x" ]; then 
    command_args="${command_args} --ignore ${INPUT_IGNORE}"
fi
echo "Max line length '${INPUT_MAX_LINE_LENGTH}'"
if [ "x${INPUT_MAX_LINE_LENGTH}" != "x" ]; then 
    command_args="${command_args} --max-line-length ${INPUT_MAX_LINE_LENGTH}"
fi
echo "Resulting CLI options ${command_args}"
exec 5>&1
res=`{ { flake8 ${command_args} ${INPUT_PATH}; echo $? 1>&4; } | sed -r 's/: ([^W][0-9][0-9][0-9])/: error: \1/;s/: (W[0-9][0-9][0-9])/: warning: \1/' 1>&5; } 4>&1`
if [ "$res" = "0" ]; then
    echo "Flake8 found no problems"
else
    echo "Flake8 found one or more problems"
fi

# Remove the matcher, so no other jobs hit it.
echo "::remove-matcher owner=flake8::"

# If we are in warn-only mode, return always as if we pass
if [ -n "${INPUT_ONLY_WARN}" ]; then
    exit 0
else
    exit $res
fi
