import os
import subprocess

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
    }
}
c.ServerApp.root_dir = '/'
c.ServerApp.preferred_dir = os.getcwd()
c.FileContentsManager.allow_hidden = True
c.KubeSpawner.supplemental_gids = [101]

before_notebook = subprocess.call("/opt/neurodesktop/jupyterlab_startup.sh")
