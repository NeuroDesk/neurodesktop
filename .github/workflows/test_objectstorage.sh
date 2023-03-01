# set -e

SERVERADDRESS=$1
# SERVERADDRESS=https://objectstorage.us-ashburn-1.oraclecloud.com/n/sd63xuke79z3/b/neurodesk/o/

wget https://raw.githubusercontent.com/NeuroDesk/neurocommand/main/cvmfs/log.txt

mapfile -t arr < log.txt
for LINE in "${arr[@]}";
do
    echo "LINE: $LINE"
    IMAGENAME_BUILDDATE="$(cut -d' ' -f1 <<< ${LINE})"
    echo "IMAGENAME_BUILDDATE: $IMAGENAME_BUILDDATE"

    IMAGENAME="$(cut -d'_' -f1,2 <<< ${IMAGENAME_BUILDDATE})"
    BUILDDATE="$(cut -d'_' -f3 <<< ${IMAGENAME_BUILDDATE})"
    
    if curl --output /dev/null --silent --head --fail "${SERVERADDRESS}${IMAGENAME_BUILDDATE}.simg"; then
            echo "[DEBUG] ${IMAGENAME_BUILDDATE}.simg exists in ${SERVERADDRESS}"
    else
            echo "[DEBUG] ${IMAGENAME_BUILDDATE}.simg does not exist yet in ${SERVERADDRESS}. Something is WRONG"
            exit 2
    fi
done

rm log.txt