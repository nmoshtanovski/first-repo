#!/bin/bash
#Stop on error
#But we can't use it here because AWS CLI returns 0 or 255.
#In the case when no stack update is required it returns 255 that is certainly not an error
#set -e

#Set environment variable
environment=$1

#Set stack names
security_stack_name="greetings-api-security-stack-$environment"
api_stack_name="greetings-api-stack-$environment"

#Prepare Nodejs code
grunt lambda_package:greetings

rm -rf  /var/lib/jenkins/Projects/first-repo/Greetings/dist/code

unzip /var/lib/jenkins/Projects/first-repo/Greetings/dist/greetings_latest.zip -d /var/lib/jenkins/Projects/first-repo/Greetings/dist/code

#Deploy api security stack
aws cloudformation deploy --template-file /var/lib/jenkins/Projects/first-repo/Greetings/deploy/greetings-api-security-cf.yaml --stack-name $security_stack_name --capabilities CAPABILITY_IAM --parameter-overrides OktaAuthenticationApiUrl="https://dev-816827.oktapreview.com/api/v1/authn" OktaAuthorizationApiUrl="https://dev-816827.oktapreview.com/oauth2/aus9d75t4rxxzOKyo0h7/v1/authorize" ClientId="rpqHwm1gbtVDjfuptnc3" Issuer="https://dev-816827.oktapreview.com/oauth2/aus9d75t4rxxzOKyo0h7" Scope="openid profile Greetings" Keys="eyJrZXlzIjpbeyJhbGciOiJSUzI1NiIsImUiOiJBUUFCIiwibiI6ImtLek43enk3UUxIU0k0QW5qY2FJbFduSEpGUnFxR0U4NmdvVTdIblJzcUY2TzFGNkhWdnM0NEljYkxqdXl3VlpjYmpuS0hmYVQya25BQ1FfUU1JVEJoMVJPd3dqbEZEcEhjaVlhZDAwa3VycU9Kb1pDdTdISU1kdmtpVno4TUNMTEZrTkZZVkF2alJhdjJDMXIzWUpUdkdPZ1hpRU5oRWRHMHVsa01WUjlxeVlvNlZiMHVsM1BzQlYtaEtadjhDbWx6WjNsYnNrYlZ3QUp1UURxR1U3enB6OHBDRkNYV05FS2oycHJHV3NYZEFPNFJ0djk2bmdzTTVTeXlzcXhveGp0WGR1czh1bEdENDFLT1NvZjNIcVg4c0hxc0RmUDJyNHR6aTJBT2RqWU5WdjRUX01CNGxndjEtQ2FvUEZBSEczNmhVU3JiTXpGd0J5RWd1MVlncDhYdyIsImtpZCI6Im5rSGlFRjBrdERvTm9CRUJjTm9NUmtDQm5YaERKLUU1dEdUM1prcldGeXciLCJrdHkiOiJSU0EiLCJ1c2UiOiJzaWcifV19"

#Get authorizer function arn
authorizerFunctionArn=$(aws cloudformation describe-stacks --stack-name $security_stack_name --query 'Stacks[0].Outputs[?OutputKey==`AuthorizerFunctionArn`].OutputValue' --output text)

#Delete previous swagger file
rm -rf /var/lib/jenkins/Projects/first-repo/Greetings/deploy/greetings-swagger.yaml

#Substitute authorizer function ARN placeholder in the template swagger file
sed -e "s/\${authorizerFunctionArn}/$authorizerFunctionArn/" /var/lib/jenkins/Projects/first-repo/Greetings/deploy/greetings-swagger-base.yaml > /var/lib/jenkins/Projects/first-repo/Greetings/deploy/greetings-swagger.yaml

#Package the code
aws cloudformation package --template-file /var/lib/jenkins/Projects/first-repo/Greetings/deploy/greetings-api-cf-template.yaml --output-template-file /var/lib/jenkins/Projects/first-repo/Greetings/deploy/greetings-api-cf.yaml --s3-bucket iw-code-repository --s3-prefix greetings

#Deploy api stack
aws cloudformation deploy --template-file /var/lib/jenkins/Projects/first-repo/Greetings/deploy/greetings-api-cf.yaml --stack-name $api_stack_name --capabilities CAPABILITY_IAM --parameter-overrides SecurityStackName=$security_stack_name Prefix="Hi There!" Suffix="Nice job!"

#Get API id
api_id=$(aws cloudformation describe-stacks --stack-name $api_stack_name --query 'Stacks[0].Outputs[?OutputKey==`GreetingsApiIdentifier`].OutputValue' --output text)

#Dealing with the SAM bug (stage with name 'Stage' is created automatically)
aws apigateway delete-stage --region us-east-1 --rest-api-id $api_id --stage-name Stage

#If we change the API definition, the changes are not automatically deployed at the stage
#That's why we create new deployment here
aws apigateway create-deployment --rest-api-id $api_id --stage-name api --description test
