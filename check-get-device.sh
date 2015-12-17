#!/bin/bash
# MESHBLU_SERVER=meshblu.octoblu.com
# MESHBLU_HTTP_SERVER=meshblu.octoblu.com

MESHBLU_SERVER=meshblu.octoblu.com
MESHBLU_HTTP_SERVER=meshblu.octoblu.com


AUTH_DEVICE=`meshblu-util register -s $MESHBLU_SERVER  -t device:auth `
AUTH_DEVICE_UUID=`echo $AUTH_DEVICE | jq -r '.uuid'`
AUTH_DEVICE_TOKEN=`echo $AUTH_DEVICE | jq -r '.token'`

DISCOVERER=`meshblu-util register -s $MESHBLU_SERVER -d "{ \"discoverAsWhitelist\": [\"$AUTH_DEVICE_UUID\"]}" -t device:discoverer`
DISCOVERER_UUID=`echo $DISCOVERER | jq -r '.uuid'`

DISCOVEREE=`meshblu-util register -s $MESHBLU_SERVER -d "{ \"discoverWhitelist\": [\"$DISCOVERER_UUID\"] }" -t device:discoveree`
DISCOVEREE_UUID=`echo $DISCOVEREE | jq -r '.uuid'`

echo "AUTH_DEVICE: "
echo $AUTH_DEVICE | jq '.'

echo "DISCOVERER: "
echo $DISCOVERER | jq '.'

echo "DISCOVEREE: "
echo $DISCOVEREE | jq '.'

# echo "whoami as auth device get auth:"
# curl http://$AUTH_DEVICE_UUID:$AUTH_DEVICE_TOKEN@$MESHBLU_HTTP_SERVER/v2/whoami | jq '.type'


echo "get discoverer should fail:"
curl -v http://$AUTH_DEVICE_UUID:$AUTH_DEVICE_TOKEN@$MESHBLU_HTTP_SERVER/v3/devices/$DISCOVERER_UUID

echo "get discoverer as discoverer device should fail:"
curl http://$AUTH_DEVICE_UUID:$AUTH_DEVICE_TOKEN@$MESHBLU_HTTP_SERVER/v3/devices/$DISCOVERER_UUID -H "X-AS: $DISCOVERER_UUID"

echo "get discoveree as discoverer device should work:"
curl http://$AUTH_DEVICE_UUID:$AUTH_DEVICE_TOKEN@$MESHBLU_HTTP_SERVER/v3/devices/$DISCOVEREE_UUID -H "X-AS: $DISCOVERER_UUID" | jq '.type'

echo "whoami as discoverer device get discoverer should fail:"
curl http://$AUTH_DEVICE_UUID:$AUTH_DEVICE_TOKEN@$MESHBLU_HTTP_SERVER/v2/whoami -H "X-AS: $DISCOVERER_UUID" | jq '.type'

echo "whoami as discoveree device should fail:"
curl -v http://$AUTH_DEVICE_UUID:$AUTH_DEVICE_TOKEN@$MESHBLU_HTTP_SERVER/v2/whoami -H "X-AS: $DISCOVEREE_UUID"
