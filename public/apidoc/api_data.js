define({ "api": [
  {
    "name": "DeleteDevice",
    "group": "Devices",
    "type": "delete",
    "url": "/export/devices/:uuid",
    "title": "Delete a device",
    "version": "1.0.0",
    "description": "<p>Deletes or unregisters a node or device currently registered that you have access to update.</p>",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "uuid",
            "description": "<p>device's uuid</p>"
          }
        ]
      }
    },
    "contentType": "application/json",
    "filename": "src/router.coffee",
    "groupTitle": "Devices",
    "sampleRequest": [
      {
        "url": "{{APIURL}}/export/devices/:uuid"
      }
    ],
    "header": {
      "fields": {
        "Header": [
          {
            "group": "Header",
            "type": "String",
            "optional": false,
            "field": "Authorization",
            "description": "<p>Basic UUID:TOKEN <br> See http://www.ietf.org/rfc/rfc2617.txt</p>"
          }
        ]
      }
    }
  },
  {
    "name": "GetDevice",
    "group": "Devices",
    "type": "get",
    "url": "/export/devices/:uuid",
    "title": "Get a device",
    "version": "1.0.0",
    "description": "<p>Returns all information (except the token) of a specific device or node</p>",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "uuid",
            "description": "<p>device's uuid</p>"
          }
        ]
      }
    },
    "contentType": "application/json",
    "success": {
      "fields": {
        "Success 200": [
          {
            "group": "Success 200",
            "type": "Object",
            "optional": false,
            "field": "device",
            "description": "<p>all information of specific device</p>"
          }
        ]
      }
    },
    "filename": "src/router.coffee",
    "groupTitle": "Devices",
    "sampleRequest": [
      {
        "url": "{{APIURL}}/export/devices/:uuid"
      }
    ],
    "header": {
      "fields": {
        "Header": [
          {
            "group": "Header",
            "type": "String",
            "optional": false,
            "field": "Authorization",
            "description": "<p>Basic UUID:TOKEN <br> See http://www.ietf.org/rfc/rfc2617.txt</p>"
          }
        ]
      }
    }
  },
  {
    "name": "MyDevices",
    "group": "Devices",
    "type": "get",
    "url": "/export/mydevices",
    "title": "Get my devices",
    "version": "1.0.0",
    "description": "<p>Returns all information of all devices or nodes belonging to a user's UUID <br> (identified with an &quot;owner&quot; property and user's UUID i.e. &quot;owner&quot;:&quot;0d1234a0-1234-11e3-b09c-1234e847b2cc&quot;)</p>",
    "contentType": "application/json",
    "filename": "src/router.coffee",
    "groupTitle": "Devices",
    "sampleRequest": [
      {
        "url": "{{APIURL}}/export/mydevices"
      }
    ],
    "header": {
      "fields": {
        "Header": [
          {
            "group": "Header",
            "type": "String",
            "optional": false,
            "field": "Authorization",
            "description": "<p>Basic UUID:TOKEN <br> See http://www.ietf.org/rfc/rfc2617.txt</p>"
          }
        ]
      }
    }
  },
  {
    "name": "RegisterDevice",
    "group": "Devices",
    "type": "post",
    "url": "/export/devices",
    "title": "Register a device",
    "version": "1.0.0",
    "description": "<p>Registers a node or device. <br> It returns a UUID device id and security token. You can pass any key/value pairs.</p>",
    "contentType": "application/json",
    "filename": "src/router.coffee",
    "groupTitle": "Devices",
    "sampleRequest": [
      {
        "url": "{{APIURL}}/export/devices"
      }
    ],
    "header": {
      "fields": {
        "Header": [
          {
            "group": "Header",
            "type": "String",
            "optional": false,
            "field": "Authorization",
            "description": "<p>Basic UUID:TOKEN <br> See http://www.ietf.org/rfc/rfc2617.txt</p>"
          }
        ]
      }
    }
  },
  {
    "name": "UpdateDevice",
    "group": "Devices",
    "type": "patch",
    "url": "/export/devices/:uuid",
    "title": "Update a device",
    "version": "1.0.0",
    "description": "<p>Updates a node or device that you have access to update. <br> You can pass any key/value pairs to update object.</p>",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "uuid",
            "description": "<p>device's uuid</p>"
          }
        ]
      }
    },
    "contentType": "application/json",
    "filename": "src/router.coffee",
    "groupTitle": "Devices",
    "sampleRequest": [
      {
        "url": "{{APIURL}}/export/devices/:uuid"
      }
    ],
    "header": {
      "fields": {
        "Header": [
          {
            "group": "Header",
            "type": "String",
            "optional": false,
            "field": "Authorization",
            "description": "<p>Basic UUID:TOKEN <br> See http://www.ietf.org/rfc/rfc2617.txt</p>"
          }
        ]
      }
    }
  }
] });
