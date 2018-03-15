#!/usr/bin/env bash
# Run all test suites with various combinations of environment variables to test that the app works in against
# production and local environments. Currently the only test suite is test_hello_world.py.
# Nosetests doesn't have a straightforward way to modify environment variables in a test suite, so wrap the Nosetests
# suite in a bash script.
# https://stackoverflow.com/questions/27966420/nosetests-framework-how-to-pass-environment-variables-to-my-tests
source venv/bin/activate
source ./.app_bash_profile
export USE_AWS='False'
export STORAGE_TYPE='csv'
nosetests --nocapture

export USE_AWS='False'
export STORAGE_TYPE='postgres'
nosetests --nocapture

export USE_AWS='True'
export STORAGE_TYPE='csv'
nosetests --nocapture