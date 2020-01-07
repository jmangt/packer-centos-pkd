#!/bin/bash
set -e

sudo yum install epel-release -y
sudo yum makecache fast
sudo yum update -y