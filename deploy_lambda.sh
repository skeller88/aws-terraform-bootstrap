#!/bin/bash
# Based on script from http://jeremievallee.com/2017/03/26/aws-lambda-terraform/
set -e

ZIPFILE_DIR="dist/lambdas"
# Determines the zipfile name and the main ".py" file that gets zipped
LAMBDA_NAME=$1
echo $LAMBDA_NAME
# Get Virtualenv Directory Path
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ -z "$VIRTUAL_ENV_DIR" ]; then
    VIRTUAL_ENV_DIR="$SCRIPT_DIR/venv"
fi

echo "LAMBDA_NAME is $LAMBDA_NAME"
echo "Using virtualenv located in : $VIRTUAL_ENV_DIR"

# If zip artifact already exists, back it up
if [ -f $SCRIPT_DIR/$ZIPFILE_DIR/$LAMBDA_NAME.zip ]
then
    cp $SCRIPT_DIR/$ZIPFILE_DIR/$LAMBDA_NAME.zip $SCRIPT_DIR/$ZIPFILE_DIR/$LAMBDA_NAME.zip.backup
fi

zip -rg $SCRIPT_DIR/$ZIPFILE_DIR/$LAMBDA_NAME.zip $LAMBDA_NAME.py;

cd $SCRIPT_DIR/venv/lib/python3.6/site-packages;
zip -rg $SCRIPT_DIR/$ZIPFILE_DIR/$LAMBDA_NAME.zip *;

cd $SCRIPT_DIR;
zip -rg $SCRIPT_DIR/$ZIPFILE_DIR/$LAMBDA_NAME.zip src/**

# Run terraform apply
cd terraform/
terraform apply
cd $SCRIPT_DIR