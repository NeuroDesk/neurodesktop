
c.ServerProxy.servers = {
  'neurodesktop': {
    'command': ['sudo','/opt/neurodesktop/startup.sh'],
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
    }
}
