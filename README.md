# Wikimedia on AWS
## Requirements (**changed** so this isn't easily searchable via google)
1. You can host this wherever you want.
2. You must leave your history intact.
3. You must provide us with the IP, username and SSH key so we can login as a user with sudo
privileges.
4. You must provide motivations for why you did what you did.
5. This setup must be production quality.

## Answers
1. Hosting on AWS.
2. Not Applicable with my approach.
3. Not going to provide this you can spin this up and self service and read the artifacts.
4. See below for details and insight into my motivations and thinkings.
5. This is very difficult given the fact that different "Production" levels have different requirements but I demonstrate below my thinking and design. Performance and Capacity requirements differ from environment to environment and there is no one size fits all.

----
## Prerequisites
* A DNS Name for a domain owned which is to be used with the WIKI.
* An AWS AMC SSL Certificate for the domain. (https://docs.aws.amazon.com/acm/latest/userguide/gs-acm-request-public.html)
* An S3 Bucket where the CloudFormation Templates and Wikimedia config can be stored and accessed. 
* AWS CLI installed and configured.
* git installed.

## As is Architecture Design Overview:
* Application Load Balancer. (Public Facing):
  * Restricted IP Source via Security Group (A private VPN connection from the Corportate office would be better)
  * HTTPS only (Using ACM Certificate)
  * Cross AZ Load Balancing is always on for this LoadBalancer. 
* ECS Cluster with hosts in private subnets AND multiple AZ's. (ECS Optimised AMI)
* ECS Service:
  * Wikimedia prod based docker images (https://hub.docker.com/r/wikimedia/mediawiki/).
  * Set Scaling after doing load testing.
* EFS volume for file uploads.
* All this deployed in its own disconnected VPC.
* Multi AZ Aurora DB for redundant DB Backend.

- DNS is decoupled intentionally here to allow for Blue/Green style deployments and the like.

## Further things I would like to add but don't have time for at this stage:
* Native S3 plugin for file uploads to replace EFS. (This looks ugly: https://www.mediawiki.org/wiki/Extension:LocalS3Repo)
* A full CI/CD pipeline for this which could be used to deliver changes to this infrastructure.
* The Instance types and infrastructure can be optimised after load testing:
  * Used this to start: https://www.mediawiki.org/wiki/Manual:Installation_requirements
  * Perform Load testing: Locust/Apache ab/Apache Jmeter.
  * Add Scaling Triggers to scale the ECS Service based on benchmarking done in the step above.
  * Memcache layer. (Adding performance if required to the DB Layer as it scales:https://www.mediawiki.org/wiki/Manual:Memcached)
  * Read Replicas for the Aurora DB.
* Decouple the DB component for more flexibility (Potentially Blue Green switch over for new setups etc.)
* A private ECR or Docker Repository with a known image so I know what I am getting in terms of the Container images. Relying on public resources is not good security practice
* This could also be fronted by CloudFront. 
* Security
  * Logging for the Containers shipped to a SIEM/Syslog Service.
  * Logging for Application Load Balancer shipped to a SIEM/Syslog service.
  * Logging OS level logs to a SIEM/Syslog service.   

## Why?
* Instead of creating a single instance with the configuration creating a repeatable pattern which can be versioned and have changes tracked.
* I don't like treating servers as pets and prefer cattle.
* I don't like logging into servers.

## Setting this up:
1. Configure aws cli 
```
  aws configure
```
2. Create S3 Bucket
```
  aws s3api create-bucket --bucket {bucketname} --region {region}
```
3. Clone the repo
```
  git clone https://github.com/ajgargan/wikimedia.git
```
4. Copy CloudFormation templates to the appropriate location in the S3 bucket
```
  aws s3 cp templates s3://{bucketname}/mediawiki/templates/ --recursive 
```
5. Configure CloudFormation parameters in ci/dev-gargana.json
6. Configure the WikiMedia configuration file: LocalSettings.php
7. Send this to S3 Location. (Restrict Access appropriately)
```
  aws s3 cp LocalSettings.php s3://{bucketname}/mediawiki/
```
8. Run cmd.sh to launch the CloudFormation stack
```
  ./cmd.sh
```
9. The Stack Output should contain the URL of the ALB.
10. Configure your DNS to point to this ALB URL endpoints DNS name as CNAME entry.
