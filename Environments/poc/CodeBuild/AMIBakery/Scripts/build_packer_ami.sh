#ami_type=$1
# security_group_id=$(cat packer_sg_id.txt)
# iam_instance_profile_id=$(cat iam_instance_profile.txt)

#./AMIBakery/Scripts/create_packer_sg_rule.sh
# ./scripts/create_packer_instance_profile.sh

whitelisted_security_group_id="sg-0d04b59d0e337140f"
cidr_prefix="32"
winrm_port="5986"

echo "Finding IP address.."
build_agent_public_ip=$(curl -s https://checkip.amazonaws.com)

echo "Adding Ingress WinRM Port $winrm_port to Security Group $whitelisted_security_group_id with IP Range of $build_agent_public_ip/$cidr_prefix..."
aws ec2 authorize-security-group-ingress \
  --group-id $whitelisted_security_group_id \
  --protocol tcp \
  --port $winrm_port \
  --cidr $build_agent_public_ip/$cidr_prefix

# Run packer for app1 Web AMI
echo Running packer Build...
packer build -color=false -var-file="Environments/poc/CodeBuild/AMIBakery/Packer/variables.pkvars.hcl" Environments/poc/CodeBuild/AMIBakery/Packer/app1_ami.json -machine-readable | tee build.log

