sudo chmod g+rwxs /home
sudo setfacl -dRm u::rwX,g::rwX,o::0 /home
