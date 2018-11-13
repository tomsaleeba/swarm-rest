#!/usr/bin/env bash
# This script will create the S3 bucket, IAM user, generate IAM keys, generate user policy
# Requires awscli and local IAM account with sufficient permissions

# Verify AWS CLI Credentials are setup
# http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html
if ! grep -q aws_access_key_id ~/.aws/config; then
  if ! grep -q aws_access_key_id ~/.aws/credentials; then
    echo "AWS config not found or CLI not installed. Please run \"aws configure\"."
    exit 1
  fi
fi
echo 'hint: set AWS_PROFILE env var to control which profile to use for running these commands'
sleep 2

echo "This script will create the S3 IAM user, generate IAM keys, add to IAM group, generate user policy."
FRAGMENT=swarm-es-snapshot-s3
CLIENT=$FRAGMENT-user
BUCKET=swarm-es-snapshots

echo " "
echo "====================================================="
echo "Creating S3 bucket: "$BUCKET
aws s3 mb s3://$BUCKET --output json
echo "====================================================="
echo " "
echo "====================================================="
echo "Creating IAM User: "$CLIENT
aws iam create-user --user-name $CLIENT --output json
echo "====================================================="
echo " "
echo "====================================================="
echo "Generating IAM Access Keys"
aws iam create-access-key --user-name $CLIENT --output json
echo "====================================================="

# policy taken from https://www.elastic.co/guide/en/elasticsearch/plugins/current/repository-s3-repository.html#repository-s3-permissions
cat > userpolicy.json << EOL
{
  "Statement": [
    {
      "Action": [
        "s3:ListBucket",
        "s3:GetBucketLocation",
        "s3:ListBucketMultipartUploads",
        "s3:ListBucketVersions"
      ],
      "Effect": "Allow",
      "Resource": [
        "arn:aws:s3:::$BUCKET"
      ]
    },
    {
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:AbortMultipartUpload",
        "s3:ListMultipartUploadParts"
      ],
      "Effect": "Allow",
      "Resource": [
        "arn:aws:s3:::$BUCKET/*"
      ]
    }
  ],
  "Version": "2012-10-17"
}
EOL
echo " "
echo "====================================================="
echo "Generating User Policy"
aws iam put-user-policy --user-name $CLIENT --policy-name $FRAGMENT-policy --policy-document file://userpolicy.json
rm userpolicy.json
echo " "
echo "====================================================="
echo "Completed!  Created user: "$CLIENT
echo "====================================================="

