
c.ServerProxy.servers = {
  'neurodesktop': {
    'command': ['/opt/neurodesktop/guacamole.sh'],
    'port': 8080,
    'timeout': 60,
      'request_headers_override': {
          'Authorization': 'Basic am92eWFuOnBhc3N3b3Jk',
      },
      'launcher_entry': {
        'path_info' : 'neurodesktop',
        'title': 'Neurodesktop',
        'icon_path': '/opt/neurodesk_brain_logo.svg'
      }
    },
  # 'xneurodesk': {
  #   'command': ['/opt/neurodesktop/xpra.sh'],
  #   'port': 9090,
  #   'timeout': 60,
  #     'request_headers_override': {
  #         'Authorization': 'Basic am92eWFuOnBhc3N3b3Jk',
  #     },
  #     'launcher_entry': {
  #       'path_info' : 'xneurodesk',
  #       'title': 'XNeurodesk',
  #       'icon_path': '/opt/neurodesk_brain_icon.svg'
  #     }
  #   }
}
