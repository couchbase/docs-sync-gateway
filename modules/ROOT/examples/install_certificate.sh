#!/usr/bin/env bash

set -e

CHAIN=chain
INBOX=/home/sync_gateway/
ip=${1:-192.168.33.11}
NODE=pkey
ROOT_CA=ca
SSH="ssh -o StrictHostKeyChecking=no"
SCP="scp -o StrictHostKeyChecking=no"

${SSH} vagrant@${ip} "sudo mkdir ${INBOX}" 2>/dev/null || true
${SCP} ca.pem vagrant@${ip}:ca.pem
${SCP} chain.pem vagrant@${ip}:chain.pem
${SCP} pkey.key vagrant@${ip}:pkey.key
${SSH} vagrant@${ip} "sudo mv ca.pem ${INBOX}${ROOT_CA}.pem"
${SSH} vagrant@${ip} "sudo mv chain.pem ${INBOX}${CHAIN}.pem"
${SSH} vagrant@${ip} "sudo mv pkey.key ${INBOX}${NODE}.key"
${SSH} vagrant@${ip} "sudo chmod a+x ${INBOX}${ROOT_CA}.pem"
${SSH} vagrant@${ip} "sudo chmod a+x ${INBOX}${CHAIN}.pem"
${SSH} vagrant@${ip} "sudo chmod a+x ${INBOX}${NODE}.key"
