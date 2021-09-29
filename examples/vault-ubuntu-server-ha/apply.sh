#!/bin/bash
terraform0.11.14 apply -auto-approve
sleep 10
terraform0.11.14 apply -auto-approve
sleep 10
gcloud beta compute --project "kawsar-kamal-gcp2" ssh --zone "us-east1-b" "vault0-0"
