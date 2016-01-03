!/bin/bash
set -x -e

PROJECT="cloud-native-java"

# clean up keypair if it exists. Still exits 0 if it didn't exist, for some reason.
aws ec2 delete-key-pair --key-name $PROJECT

# The next line will throw an error if it can't delete the group because it has a running instance
# We aren't exiting here; if the previous instance is still running we'll exit at group creation
aws ec2 delete-security-group --group-name $PROJECT || true

# We don't want to keep any previous pem around. Instances won't be reused.
rm ~/$PROJECT.pem || true

# make a new keypair to ensure we have the pem
aws ec2 create-key-pair --key-name $PROJECT --query "KeyMaterial" --output text > ~/$PROJECT.pem
chmod 600 ~/$PROJECT.pem

# make a new security group any IP can ssh into
# bail out if the group exists because that means we may already have an instance in place.
aws ec2 create-security-group --group-name $PROJECT --description $PROJECT
aws ec2 authorize-security-group-ingress --group-name $PROJECT --protocol tcp --port 22 --cidr 0.0.0.0/0

# launch instance with centos AMI for us-west-2
# there are assumptions here, about the default region you have set and the instance type you're launching.
# To whit: not all instance types can be used with all AMIs, and AMIs are region-specific.
aws ec2 run-instances --image-id ami-f0091d91 --key-name $PROJECT --instance-type t2.micro --security-groups $PROJECT

# make output less verbose
set +x

# Loop until the instance gets a public IP
while [ -z "${PUBLIC_IP}" ]; do
  echo "Waiting for public IP..."
  sleep 1
  PUBLIC_IP=$(aws ec2 describe-instances --filter Name="key-name",Values="$PROJECT" "Name=instance-state-name,Values=running" --query "Reservations[].Instances[].[PublicIpAddress]" --output text)
done

# Continue until sshd accepts connections
while [ -z ${SSH_READY} ]; do
  echo "Trying to connect..."
  if [ "$(nc -z -w 4 $(aws ec2 describe-instances --filter Name="key-name",Values="$PROJECT" "Name=instance-state-name,Values=running" --query "Reservations[].Instances[].[PublicIpAddress]" --output text) 22; echo $?)" = 0 ]; then
      SSH_READY=true;
  fi
  sleep 1
done

# Poll SSH to get instance ID to ensure that SSH connection can be acquired
while [ -z "${INSTANCE_ID}" ]; do
  sleep 1
  INSTANCE_ID=$(ssh -i ~/$PROJECT.pem -o StrictHostKeyChecking=no ec2-user@$PUBLIC_IP "curl -s http://169.254.169.254/latest/meta-data/instance-id; echo")
done

# turn verbose output back on
set -x

# Tag instance with project name
aws ec2 create-tags --resources $INSTANCE_ID --tags Key=Name,Value=$PROJECT

# ssh in, update yum, install & start docker, allow ec2-user to use docker.
ssh -tt -i ~/$PROJECT.pem -o StrictHostKeyChecking=no ec2-user@$PUBLIC_IP "sudo yum update -y && sudo yum install -y docker && sudo service docker start && sudo usermod -a -G docker ec2-user"

# putting this on its own line as sometimes docker takes too long to start and then the script exits with:
# Cannot connect to the Docker daemon. Is the docker daemon running on this host?
ssh -tt -i ~/$PROJECT.pem -o StrictHostKeyChecking=no ec2-user@$PUBLIC_IP "docker ps" || true

# clean up
aws ec2 terminate-instances --instance-ids $INSTANCE_ID