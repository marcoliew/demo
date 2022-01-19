#ami_type=$1
# security_group_id=$(cat packer_sg_id.txt)
# iam_instance_profile_id=$(cat iam_instance_profile.txt)

#./AMIBakery/Scripts/create_packer_sg_rule.sh
# ./scripts/create_packer_instance_profile.sh

cidr_prefix="32"
winrm_port="5986"
deployment_role=$1
Environment=$2
security_group=$3
lhd=$4

echo "Finding IP address.."
build_agent_public_ip=$(curl -s https://checkip.amazonaws.com)

echo "Adding Ingress WinRM Port $winrm_port to Security Group $security_group with IP Range of $build_agent_public_ip/$cidr_prefix..."
aws ec2 authorize-security-group-ingress \
  --group-id $security_group \
  --protocol tcp \
  --port $winrm_port \
  --cidr $build_agent_public_ip/$cidr_prefix

 
echo Running packer Build...
packer build -var-file="Environments/$Environment/$lhd/Packer/$deployment_role/variables.pkvars.hcl" -var "security_group=$security_group" AMIBakery/Packer/$deployment_role/ami.json -machine-readable | tee build.log
