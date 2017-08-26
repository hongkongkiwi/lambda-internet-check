#!/bin/bash

###
#
# This script is used for uploading node.js code to Amazon using the aws class-methods-use-this
# It makes it convenient for testing code on your local machine.
#
# To make things easy, consider adding this to the package.json
#   "scripts": {
#    "upload": "./bin/publish.sh"
#  },
# Then you can just "npm run upload" to upload to Amazon
#
###

# Remove Globbing
set -f

# trap ctrl-c and call ctrl_c()
trap ctrl_c INT

function cleanup() {
  if [ -f "$PACKAGE_ZIP" ] && [[ "$KEEP_ZIP" != "yes" ]]; then
    rm "$PACKAGE_ZIP"
    echo "Removed existing package zip"
  fi
}

function ctrl_c() {
  cleanup
  echo "^Aborted"
  exit 1
}

# Setup our Variables
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
RUNDIR=`pwd`
KEEP_ZIP="yes"
PACKAGE_JSON="package.json"
PACKAGE_ZIP="temp/package.zip"
JS_FILES="index.js"
INCLUDE_IN_ZIP=("node_modules" "libs" "plugins")
EXCLUDE_IN_ZIP=(".git" "*.sh" "*.log" "npm-debug.log*" "yarn-debug.log*" "yarn-error.log*" ".npm" "*.zip" "*.tgz")
LINT_BEFORE_UPLOAD="no"
ZIP="zip -q -r -9"
ESLINT="eslint"
NPM="npm install -q --production --loglevel=error ."

cd $RUNDIR

for js_file in "${JS_FILES[@]}"
do
   :
   if [ ! -f "$js_file" ]; then
     echo "Cannot find file $js_file in JS_FILES"
     exit 1
   fi
done

# Check if we have the required programs
if [[ "$LINT_BEFORE_UPLOAD" == "yes" ]]; then
  command -v eslint >/dev/null 2>&1 || { echo "eslint is missing! Install with npm install -g eslint"; LINT_BEFORE_UPLOAD="no"; }
fi
command -v zip >/dev/null 2>&1 || { echo >&2 "I require zip but it's not installed.  Aborting."; exit 1; }
command -v jq >/dev/null 2>&1 || { echo >&2 "I require jq but it's not installed.  Aborting."; exit 1; }
command -v aws >/dev/null 2>&1 || { echo >&2 "I require aws but it's not installed.  Aborting."; exit 1; }
command -v npm >/dev/null 2>&1 || { echo >&2 "I require npm but it's not installed.  Aborting."; exit 1; }

if [ ! -f "$PACKAGE_JSON" ]; then
  echo >&2 "$PACKAGE_JSON does not exist!"
  exit 1
fi

LAMBDA_FUNCTION_NAME=`cat "$PACKAGE_JSON" | jq -r .lambda_function`
if [[ "$LAMBDA_FUNCTION_NAME" == "null" ]]; then
  echo >&2 "Lambda Function Name is missing from $PACKAGE_JSON!"
  echo "add \"lambda_function\": \"FUNCTION_NAME\""
  exit 1
elif [[ $LAMBDA_FUNCTION_NAME == "" ]]; then
  echo >&2 "Lambda Function Name is empty!"
  echo >&2 "Edit your $PACKAGE_JSON to point to the correct lambda funtion"
  exit 1
fi

cleanup

echo "installing node.js packages in package.json..."
$NPM > /dev/null

if [[ "$LINT_BEFORE_UPLOAD" == "yes" ]]; then
  echo "Linting ${#JS_FILES[@]} js files.."
  for js_file in "${JS_FILES[@]}"
  do
     :
     $ESLINT "$js_file"
     if [[ $? != 0 ]]; then
       echo >&2 "Lint Failed on $js_file! Aborting upload"
       exit 1
     fi
  done
fi

echo "Creating package zip..."
mkdir -p `dirname "$PACKAGE_ZIP"`
$ZIP $PACKAGE_ZIP ${INCLUDE_IN_ZIP[@]} ${JS_FILES[@]} "$PACKAGE_JSON" ${EXCLUDE_IN_ZIP[@]/#/-x }

echo "Uploading package zip to Lambda function \"$LAMBDA_FUNCTION_NAME\""
RESULT=`aws lambda update-function-code --function-name "$LAMBDA_FUNCTION_NAME" --zip-file "fileb://$PACKAGE_ZIP"`
UPLOAD_RESULT=$?

if [[ $UPLOAD_RESULT != 0 ]]; then
  echo >&2 "Failed to upload!!"
  echo "$RESULT" | jq
  exit 1
fi

cleanup

if [[ $UPLOAD_RESULT == 0 ]]; then
  echo "All Done! Upload Successful!"
fi

exit $UPLOAD_RESULT
