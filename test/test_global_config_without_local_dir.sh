#!/bin/bash 
set -e

# You can run it from any directory.
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Execute common pre-setup, include test functions.
source "$DIR/common.sh"

printTestStarted

# Make sure local config is empty
rm -rf "$CONFIG_DIR"

# Mainframer will take config from global config
echo "$REMOTE_MACHINE_PROPERTY=$TEST_REMOTE_MACHINE" > "$GLOBAL_CONFIG_FILE"

set +e
# Run mainframer that noops to make sure that it exits with error.
"$REPO_DIR"/mainframer 'echo noop'

if [ "$?" == "0" ]; then
        set -e
        echo "Should have failed because local config directory does not exist."
        exit 1
fi

printTestEnded