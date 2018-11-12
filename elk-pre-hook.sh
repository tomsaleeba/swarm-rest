#!/bin/bash
# install the S3 plugin to ElasticSearch so we can store snapshots there
: ${AWS_ACCESS_KEY:?}
: ${AWS_SECRET:?}
esDir=/opt/elasticsearch/bin

$esDir/elasticsearch-plugin list | grep repository-s3
rc=$?
if [ $rc != 0 ]; then
  echo '[INFO] installing repository-s3 plugin'
  $esDir/elasticsearch-plugin install --batch repository-s3
fi
echo $AWS_ACCESS_KEY | $esDir/elasticsearch-keystore add -fx s3.client.default.access_key
echo $AWS_SECRET     | $esDir/elasticsearch-keystore add -fx s3.client.default.secret_key
chown elasticsearch:elasticsearch /etc/elasticsearch/elasticsearch.keystore # starts out owned by us (root)

