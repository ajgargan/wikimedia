#!/bin/sh

aws cloudformation create-stack \
  --stack-name "MediaWiki" \
  --template-body file://./templates/mediawiki-master.template \
  --parameters file://./ci/dev-gargana.json \
  --capabilities "CAPABILITY_IAM" \
  --disable-rollback \
  --region eu-west-1

