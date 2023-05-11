# Copy homedirectory files if they don't exist yet. 
if [ ! -f "/home/jovyan/.bashrc" ] 
then
    cp -r /tmp/jovyan/ /home/ 
fi

cp /tmp/jovyan/.jupyter/jupyter_notebook_config.py /home/jovyan/.jupyter/jupyter_notebook_config.py
cp /tmp/jovyan/.bashrc /home/jovyan/.bashrc
cp /tmp/README.md /home/jovyan/README.md

# Generate SSH keys
ssh-keygen -t rsa -f /home/jovyan/.ssh/guacamole_rsa -b 4096 -m PEM -N '' <<< n
ssh-keygen -t rsa -f /home/jovyan/.ssh/id_rsa -b 4096 -m PEM -N '' <<< n
ssh-keygen -t rsa -f /home/jovyan/.ssh/ssh_host_rsa_key -N '' <<< n
cat /home/jovyan/.ssh/guacamole_rsa.pub >> /home/jovyan/.ssh/authorized_keys
cat /home/jovyan/.ssh/id_rsa.pub >> /home/jovyan/.ssh/authorized_keys

# Set .ssh directory permissions
chmod -R 700 .ssh && chown -R jovyan:users .ssh

# Insert guacamole private key into user-mapping for ssh/sftp support
sed -i "/private-key/ r /home/jovyan/.ssh/guacamole_rsa" /etc/guacamole/user-mapping.xml

# Start and stop SSH server to initialize host
sudo service ssh restart
sudo service ssh stop
