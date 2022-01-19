# If there is an error in the build step, the post_build is still executed
test -f manifest.json || (aws events put-events --entries file://AMIBakery/Scripts/ami_event_fail.json --region $1 ; exit 1)
AMI_ID=$(cut -d':' -f2 <<<"$(jq -r '.builds[0].artifact_id' < manifest.json)")

# The file exist but there is no AMI ID
test "$AMI_ID" != "" && test "$AMI_ID" != "null" || (aws events put-events --entries file://AMIBakery/Scripts/ami_event_fail.json --region $1 ; exit 1)

# Export AMI ID to paramater store
aws ssm put-parameter --cli-input-json '{"Type": "String", "Name": "/'"$2"'/'"$3"'/'"$4"'/web/amiid/latest", "Value": "'"$AMI_ID"'", "Overwrite": true}' --region $1

# Send events
sed -i.bak "s/<<AMI-ID>>/$AMI_ID/g" AMIBakery/Scripts/ami_event_succeed.json
aws events put-events --entries file://AMIBakery/Scripts/ami_event_succeed.json --region $1

#aws events put-events --entries '[{"Source": "com.ami.builder", "Resources": ["$AMI_ID"], "DetailType": "AmiBuilder", "Detail": "{ \"AmiStatus\": \"Created\"}"}]' --region $1

echo "AMI ID $AMI_ID"
echo "Build completed on $(date)"