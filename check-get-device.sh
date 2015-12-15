#!/bin/bash

AUTH_DEVICE=`meshblu-util register -s localhost:3000  -t aaron:sucks `
AUTH_DEVICE_UUID=`echo $AUTH_DEVICE | jq -r '.uuid'`
AUTH_DEVICE_TOKEN=`echo $AUTH_DEVICE | jq -r '.token'`

DISCOVERER=`meshblu-util register -s localhost:3000 -d "{ \"discoverAsWhitelist\": [\"$AUTH_DEVICE_UUID\"]}" -t great:ya`
DISCOVERER_UUID=`echo $DISCOVERER | jq -r '.uuid'`

DISCOVEREE=`meshblu-util register -s localhost:3000 -d "{ \"discoverWhitelist\": [\"$DISCOVERER_UUID\"] }" -t peter:rocks`
DISCOVEREE_UUID=`echo $DISCOVEREE | jq -r '.uuid'`

echo "AUTH_DEVICE: "
echo $AUTH_DEVICE | jq '.'

echo "DISCOVERER: "
echo $DISCOVERER | jq '.'

echo "DISCOVEREE: "
echo $DISCOVEREE | jq '.'


# curl -vvv http://$AUTH_DEVICE_UUID:$AUTH_DEVICE_TOKEN@localhost:5000/v2/devices/$DISCOVERER_UUID
# curl -vvv http://$AUTH_DEVICE_UUID:$AUTH_DEVICE_TOKEN@localhost:5000/v2/devices/$DISCOVERER_UUID -H "X-AS: $DISCOVERER_UUID"
curl -vvv http://$AUTH_DEVICE_UUID:$AUTH_DEVICE_TOKEN@localhost:5000/v2/devices/$DISCOVEREE_UUID -H "X-AS: $DISCOVERER_UUID"
# curl -vvv http://$AUTH_DEVICE_UUID:$AUTH_DEVICE_TOKEN@localhost:5000/v2/whoami -H "X-AS: $DISCOVERER_UUID"
# curl -vvv http://$AUTH_DEVICE_UUID:$AUTH_DEVICE_TOKEN@localhost:5000/v2/whoami -H "X-AS: $DISCOVEREE"
# curl -vvvv http://$AUTH_DEVICE_UUID:$AUTH_DEVICE_TOKEN@localhost:5000/v2/whoami -H "X-AS: $DISCOVERER"
