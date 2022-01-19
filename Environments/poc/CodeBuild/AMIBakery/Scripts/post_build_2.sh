# This file is to test the pipeline/codebuild environment, by skipping the time-consuming AMI image generation. 

AMI_ID="ami-07ef68a36a1d703a7"
#echo $AMI_ID
test "$AMI_ID" != "" && test "$AMI_ID" != "null" || aws events put-events --entries file://Environments/poc/CodeBuild/AMIBakery/Scripts/ami_event_fail.json --region $1 ; exit 1


#cat Environments/poc/CodeBuild/AMIBakery/Scripts/ami_builder_event.json

#aws events put-events --entries '[{"Source": "com.ami.builder", "Resources": ["$AMI_ID"], "DetailType": "AmiBuilder", "Detail": "{ \"AmiStatus\": \"Created\"}"}]' --region $1


echo " completed on $(date)"