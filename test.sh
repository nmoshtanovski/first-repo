#!/bin/bash
#Stop on error
#But we can't use it here because AWS CLI returns 0 or 255.
#In the case when no stack update is required it returns 255 that is certainly not an error
#set -e

#Set environment variable
environment=$1

echo "hello, today is $(date) + $environment" > /home/Nikola/Public/first-repo/jenkins_test
