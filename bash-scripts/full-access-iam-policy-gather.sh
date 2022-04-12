#!/bin/bash
# This script aims to gather info about policies which contain full access on some action or full access on resources. 
# (reads policy names in the policy.txt file on the same path) and writes that output to full-access-or-resources.txt. 

policy_count=$(wc -l < policy.txt)
for (( i = 1; i < policy_count+1; ++i ));
do
policy=$(awk 'NR=='$i'' policy.txt)
echo "---> Getting arn of $policy ..."
control_number=$(aws iam list-policies --query 'Policies[*].[PolicyName, Arn]'  --output text |grep $policy | wc -l | awk '{print $1}')
if [[ $control_number -gt 1 ]]; then
	policy_arn=$(aws iam list-policies --query 'Policies[*].[PolicyName, Arn]'  --output text |grep $policy | awk 'NR==1' |awk '{print $2}')
else
 policy_arn=$(aws iam list-policies --query 'Policies[*].[PolicyName, Arn]'  --output text |grep $policy |awk '{print $2}')
fi
echo "---> Getting default policy version of $policy ..."
default_version=$(aws iam get-policy --policy-arn $policy_arn  | jq '.Policy.DefaultVersionId' | sed 's/"//g')
printf "***************************************************************************************************************************\n$i.    Policy Name: $policy && arn: $policy_arn && Default Version: $default_version  \n***************************************************************************************************************************\n"
echo "---> Getting details of $policy ..."
aws iam get-policy-version --policy-arn $policy_arn  --version-id $default_version  > policy.json
aws iam list-entities-for-policy --policy-arn $policy_arn  > list-entities-for-policy.json
users=$(jq -c '.PolicyUsers[]| .UserName' list-entities-for-policy.json | sed 's/"//g' | sed '$!s/$/,/' | tr -d '\n')
roles=$(jq -c '.PolicyRoles[]| .RoleName' list-entities-for-policy.json | sed 's/"//g' | sed '$!s/$/,/' | tr -d '\n')

# We count number of statements in the policy
state_count=$(jq '.PolicyVersion.Document.Statement | length' policy.json)
  for (( j = 0; j < $state_count; j++ )); do
  # We count number of resources 
  resource_count=$(jq '.PolicyVersion.Document.Statement['$j'].Resource | length' policy.json)
    if [[ $resource_count -gt 1 ]]; then
  	  action=$(jq -c '.PolicyVersion.Document.Statement['$j'] | .Action ' policy.json)
        if [[ $action == *"*"* ]];then
           resource=$(jq -c '.PolicyVersion.Document.Statement['$j'] | .Resource ' policy.json)
           echo "$policy $policy_arn $default_version $action $resource USERS:$users ROLES:$roles" >> full-access-or-resource.txt
        fi
  	elif [[ $resource_count = 1 ]]; then
        resource=$(jq '.PolicyVersion.Document.Statement['$j'].Resource' policy.json | sed 's/"//g')
  	    if [[ $resource = "*" ]]; then
  		  action=$(jq -c '.PolicyVersion.Document.Statement['$j'] | .Action ' policy.json)
            if [[ $action == *"*"* ]];then
              resource=$(jq -c '.PolicyVersion.Document.Statement['$j'] | .Resource ' policy.json)
              echo "$policy $policy_arn $default_version $action all-resources USERS:$users ROLES:$roles" >> full-access-or-resource.txt
            else
  		        echo "$policy $policy_arn $default_version $action all-resources USERS:$users ROLES:$roles" >> full-access-or-resource.txt
            fi
        else
  		   :
        fi
    fi
  done
  echo "---> Operation has been completed for $policy ..."
done
