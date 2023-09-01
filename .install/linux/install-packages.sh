#!/bin/bash

set -e

sudo -s eval 'apt-get update && apt-get -y install $(cat .apt)'
