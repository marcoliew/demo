packer_version="$1"
packer_zip_file="packer_${packer_version}_linux_amd64.zip"

echo "Downloading Packer..."
curl -O https://releases.hashicorp.com/packer/$packer_version/$packer_zip_file

echo "Installing Packer..."
unzip $packer_zip_file -d /usr/local/bin

echo "Installed, removing zip file..."
rm $packer_zip_file