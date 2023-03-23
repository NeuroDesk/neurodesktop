
c.ServerProxy.servers = {
  'guacamole': {
    'command': ['/opt/neurodesktop/guacamole.sh'],
    'port': 8080,
    'timeout': 60,
      'request_headers_override': {
          'Authorization': 'Basic am92eWFuOnBhc3N3b3Jk',
      },
      'launcher_entry': {
        'path_info' : 'guacamole',
        'title': 'Guacamole',
        # 'icon_path': '/opt/neurodesk_brain_logo.svg'
      }
    },
  'xpra': {
    'command': ['/opt/neurodesktop/xpra.sh'],
    'port': 9090,
    'timeout': 60,
      'request_headers_override': {
          'Authorization': 'Basic am92eWFuOnBhc3N3b3Jk',
      },
      'launcher_entry': {
        'path_info' : 'xpra',
        'title': 'Xpra',
        # 'icon_path': '/opt/neurodesk_brain_logo.svg'
      }
    }
}
