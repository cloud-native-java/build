#!/bin/bash
set -x -e

# clean up keypair if it exists. Still exits 0 if it didn't exist, for some reason.
aws ec2 delete-key-pair --key-name cloud-native-java

# The next line will throw an error if it can't delete the group because it has a running instance:
# A client error (DependencyViolation) occurred when calling the DeleteSecurityGroup operation: resource sg-eaa4a08e has a dependent object
# If the group exists and is in use we'll actually bail out later (when trying to create the group) because I do want to continue if the error is "you're trying to delete something that doesn't exist in the first place"
aws ec2 delete-security-group --group-name cloud-native-java || true

# We don't want to keep the previous pem around. A bit fragile if we're in the corner case of "we shouldn't have run this script and still need to access a previously launched instance", so TODO: fix that before going beyond testing with this.
rm ~/cloud-native-java.pem || true

# make a new cloud-native-java keypair to ensure we have the pem
aws ec2 create-key-pair --key-name cloud-native-java --query 'KeyMaterial' --output text > ~/cloud-native-java.pem
chmod 600 ~/cloud-native-java.pem

# make a new security group any IP can ssh into
aws ec2 create-security-group --group-name cloud-native-java --description cloud-native-java
aws ec2 authorize-security-group-ingress --group-name cloud-native-java --protocol tcp --port 22 --cidr 0.0.0.0/0

# launch instance with ubuntu AMI for us-west-2
# there are assumptions here, about the default region you have set and the instance type you're launching. To whit: not all instance types can be used with all AMIs, and AMIs are region-specific.
aws ec2 run-instances --image-id ami-5189a661 --key-name cloud-native-java --instance-type t2.micro --security-groups cloud-native-java

# get public IP of instance when it has one
#
# This will loop until it gets an IP, with output eventually ending like this:
#
# ++ aws ec2 describe-instances --filter Name=key-name,Values=cloud-native-java Name=instance-state-name,Values=running --query 'Reservations[].Instances[].[PublicIpAddress]' --output text
# + PUBLIC_IP=
# + '[' -z '' ']'
# + sleep 1
# ++ aws ec2 describe-instances --filter Name=key-name,Values=cloud-native-java Name=instance-state-name,Values=running --query 'Reservations[].Instances[].[PublicIpAddress]' --output text
# + PUBLIC_IP=52.26.154.169
# + '[' -z 52.26.154.169 ']'

while [ -z "${PUBLIC_IP}" ]; do
  sleep 1
  PUBLIC_IP=$(aws ec2 describe-instances --filter Name="key-name",Values="cloud-native-java" "Name=instance-state-name,Values=running" --query 'Reservations[].Instances[].[PublicIpAddress]' --output text)
done

# ssh into new instance and run a command
# This example curl is querying the internal metadata server for the instance, but you could instead scp a script up and run it.
ssh -i ~/cloud-native-java.pem -o StrictHostKeyChecking=no ubuntu@$PUBLIC_IP "curl -s http://169.254.169.254/latest/meta-data/instance-id; echo"