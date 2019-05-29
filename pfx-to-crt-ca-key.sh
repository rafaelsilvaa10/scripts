#!/bin/bash
#------------------
#  Extract the key, certficiate, and chain in PEM format from a PFX format file
#

# Must supply the input pfx file
PFX_PATH="$1"
if [ "${PFX_PATH}" == "" ]; then
 echo "Must supply pfx file path"
 exit 1
fi

# Read password if not in environment variable
if [[ ! ${PFXPASSWORD+x} ]]; then
  echo -n "Password: " 
  read -s PFXPASSWORD
  echo
  export PFXPASSWORD
fi

# Option supply a prefix for the output files
FILENAME=$(basename "$PFX_PATH")
if [ "$2" != "" ]; then
  FILENAME_BASE=$2
else
  FILENAME_BASE="${FILENAME%.*}"
fi
echo "Using '${FILENAME_BASE}' as base for output filenames"

#
# Extract key, certificate, and chain, going to extra steps to remove the 'Bag attributes'
# Note that openssl dumps the chain in the wrong order! (Anyone have fix?)
#

echo "Extracting ${FILENAME_BASE}.key"
openssl pkcs12 -in "$PFX_PATH" -nocerts -nodes -passin env:PFXPASSWORD \
  | openssl rsa -out "${FILENAME_BASE}.key" 

echo "Extracting ${FILENAME_BASE}.crt"
openssl pkcs12 -in "$PFX_PATH" -nokeys -clcerts -nodes -passin env:PFXPASSWORD \
  | openssl x509 -out "${FILENAME_BASE}.crt" 

echo "Extracting ${FILENAME_BASE}-ca-bundle.crt"
openssl pkcs12 -in "$PFX_PATH" -nokeys -cacerts -nodes -passin env:PFXPASSWORD \
  | grep -v -e '^\s' | grep -v '^\(Bag\|subject\|issuer\)' > "${FILENAME_BASE}-ca-bundle.crt"

# Check if the bundle actually has any certificates
if [[ ! -s "${FILENAME_BASE}-ca-bundle.crt" && -f "${FILENAME_BASE}-ca-bundle.crt" ]]; then
  echo "Bundle ${FILENAME_BASE}-ca-bundle.crt is empty, deleting"
  rm "${FILENAME_BASE}-ca-bundle.crt"
fi

echo "Done."
