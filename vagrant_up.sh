#!/bin/bash

EXIT=0
vagrant up edge-1 --color <<< 'edge switch boot' || EXIT=$?
vagrant up edge-2 --color <<< 'edge switch boot' || EXIT=$?
vagrant up wan-1 --color <<< 'wan switch boot' || EXIT=$?
vagrant up wan-2 --color <<< 'wan switch boot' || EXIT=$?
vagrant up fw-1 --color <<< 'fake cisco asa firewall' || EXIT=$?
vagrant up fw-2 --color <<< 'fake cisco asa firewall' || EXIT=$?
vagrant up mgmt-1 --color <<< 'mgmt switch boot' || EXIT=$?
echo $EXIT
exit $EXIT
