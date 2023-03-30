
webpage=$(curl -L -s https://raw.githubusercontent.com/NeuroDesk/neurodesk.github.io/hugo-docsy/data/neurodesktop.toml  | head -n 1)
user=$(cat /etc/hostname)

echo

retainw=`echo $webpage | sed 's/[^0-9]*//g'`;
retainu=`echo $user | sed 's/[^0-9]*//g'`;
echo $retainw
echo $retainu

echo

if [ "$retainw" == "$retainu" ]; then
    echo "Your version is up to date."
else
    if [ "$retainu" == "latest" ]; then
        echo "Your version is up to date."
    else
        echo "There is a newer version available. Please refer to website https://neurodesk.github.io"
    fi
fi

echo

read -p "Press enter to continue"

echo
