#!/bin/bash
set -e

if [ "$DEBUG_MODE_FOR_ALL_TESTS" == "true" ]; then
	set -x
fi

# You can run it from any directory.
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DIR_NAME="$( basename "$DIR")"

# This is how we test, localhost should have sshd running on port 22 and ssh key of current user allowed.
TEST_REMOTE_MACHINE="localhost"

PRIVATE_BUILD_DIR_NAME="run"
PRIVATE_REMOTE_BUILD_ROOT_DIR="~/mainframer"
PRIVATE_REMOTE_BUILD_DIR="$PRIVATE_REMOTE_BUILD_ROOT_DIR/$PRIVATE_BUILD_DIR_NAME"

# Should be used by tests.
REPO_DIR="$DIR/.."
BUILD_DIR="$DIR/$PRIVATE_BUILD_DIR_NAME"
CONFIG_DIR="$BUILD_DIR/.mainframer"
GLOBAL_CONFIG_DIR="$HOME/.mainframer"
CONFIG_FILE="$CONFIG_DIR/config"
GLOBAL_CONFIG_FILE="$GLOBAL_CONFIG_DIR/config"
LOCAL_IGNORE_FILE="$BUILD_DIR/.mainframer/localignore"
REMOTE_IGNORE_FILE="$BUILD_DIR/.mainframer/remoteignore"
REMOTE_MACHINE_PROPERTY="remote_machine"
COMMON_IGNORE_FILE="$BUILD_DIR/.mainframer/ignore"
GLOBAL_LOCAL_IGNORE_FILE="$GLOBAL_CONFIG_DIR/localignore"
GLOBAL_REMOTE_IGNORE_FILE="$GLOBAL_CONFIG_DIR/remoteignore"
GLOBAL_IGNORE_FILE="$GLOBAL_CONFIG_DIR/ignore"

function printTestStarted {
	echo ""
	test_name=`basename "$0"`
	echo "-------- TEST STARTED $test_name -------- "
}

function printTestEnded {
	echo ""
	test_name=`basename "$0"`
	echo "-------- TEST ENDED $test_name -------- "	
}

function cleanBuildDirOnLocalMachine {
	rm -rf "$BUILD_DIR"
}

function cleanMainfamerDirOnRemoteMachine {
	ssh "$TEST_REMOTE_MACHINE" "rm -rf $PRIVATE_REMOTE_BUILD_ROOT_DIR"
}

function cleanGlobalConfig {
	ssh "$TEST_REMOTE_MACHINE" "rm -rf $GLOBAL_CONFIG_DIR"
}

function fileMustExistOnLocalMachine {
	local_file="$BUILD_DIR/$1"
	if [ ! -f "$local_file" ]; then
		echo "$local_file does not exist on local machine $2"
		exit 1
	fi
}

function fileMustNotExistOnLocalMachine {
	local_file="$BUILD_DIR/$1"
	if [ -f "$local_file" ]; then
		echo "$local_file exists on local machine $2"
		exit 1
	fi
}

function fileMustExistOnRemoteMachine {
	# Prevent script from auto-exiting on error code, do it manually.
	set +e

	ssh "$TEST_REMOTE_MACHINE" "test -f $PRIVATE_REMOTE_BUILD_DIR/$1"

	if [ "$?" != "0" ]; then
		echo "$PRIVATE_REMOTE_BUILD_DIR/$1 does not exist on remote machine $2"
		set -e
		exit 1
	fi
	
	set -e
}

function fileMustNotExistOnRemoteMachine {
	# Prevent script from auto-exiting on error code, do it manually.
	set +e
	
	ssh "$TEST_REMOTE_MACHINE" "test -f $PRIVATE_REMOTE_BUILD_DIR/$1"

	if [ "$?" == "0" ]; then
		echo "$PRIVATE_REMOTE_BUILD_DIR/$1 exists on remote machine $2"
		set -e
		exit 1
	fi
	
	set -e
}

function setTestRemoteMachineInConfig {
	echo "$REMOTE_MACHINE_PROPERTY=$TEST_REMOTE_MACHINE" > "$CONFIG_FILE"
}

# Clean build directory after run.
if [ ! "$CLEAN_BUILD_DIRS_AFTER_RUN" == "false" ]; then
	trap "cleanBuildDirOnLocalMachine ; cleanMainfamerDirOnRemoteMachine" EXIT
fi

# Clean build directories.
cleanBuildDirOnLocalMachine
cleanMainfamerDirOnRemoteMachine
cleanGlobalConfig

# Create build directory.
mkdir -p "$BUILD_DIR/.mainframer"
mkdir -p "$GLOBAL_CONFIG_DIR"

# Copy mainframer into build directory.
cp "$DIR/../mainframer" "$BUILD_DIR/"

# Create config that sets remote build machine for the test.
setTestRemoteMachineInConfig

# Set build directory as "working dir".
pushd "$BUILD_DIR"
