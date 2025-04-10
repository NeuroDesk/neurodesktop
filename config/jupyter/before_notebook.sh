#!/bin/bash

# order: start_notebook.sh -> ### before_notebook.sh ###-> jupyter_notebook_config.py -> jupyterlab_startup.sh

if [ "$EUID" -eq 0 ]; then
    # # Overrides Dockerfile changes to NB_USER
    /usr/bin/printf '%s\n%s\n' 'password' 'password' | passwd ${NB_USER}
    usermod --shell /bin/bash ${NB_USER}

    # Make sure binfmt_misc is mounted in the place apptainer expects it. This is most likely a bug in apptainer and is a workaround for now on apple silicon when CVMFS is disabled.
    if [ -d "/proc/sys/fs/binfmt_misc" ]; then
        # Check if binfmt_misc is already mounted
        if ! mountpoint -q /proc/sys/fs/binfmt_misc; then
            echo "binfmt_misc directory exists but is not mounted. Mounting now..."
            sudo mount -t binfmt_misc binfmt /proc/sys/fs/binfmt_misc
        else
            echo "binfmt_misc is already mounted."
        fi
    else
        echo "binfmt_misc directory does not exist in /proc/sys/fs."
    fi

    if [ ! -d "/cvmfs/neurodesk.ardc.edu.au/neurodesk-modules/" ]; then
        # the cvmfs directory is not yet mounted

        # check if we have internet connectivity:
        if nslookup neurodesk.org >/dev/null; then
            echo "Internet is up"
        else
            export CVMFS_DISABLE=true
            echo "No internet connection. Disabling CVMFS."
        fi

        # This is to capture legacy use. If CVMFS_DISABLE is not set, we assume it is false, which was the legacy behaviour.
        if [ -z "$CVMFS_DISABLE" ]; then
            export CVMFS_DISABLE="false"
        fi


        if [[ "$CVMFS_DISABLE" == "false" ]]; then
            # CVMFS_DISABLE is false and CVMFS should be enabled.

            # try to list the directory in case it's autofs mounted outside
            ls /cvmfs/neurodesk.ardc.edu.au/neurodesk-modules/ 2>/dev/null && echo "CVMFS is ready" || echo "CVMFS directory not there. Trying internal fuse mount next."

            if [ ! -d "/cvmfs/neurodesk.ardc.edu.au/neurodesk-modules/" ]; then
                # it is not available outside, so try mounting with fuse inside container
                # Function to get latency, returns 999 on failure
                get_latency() {
                    local url="$1"
                    local server_name="$2"
                    # Redirect informational output to stderr
                    echo "Testing $url" >&2
                    echo "Resolving DNS name for $server_name" >&2
                    local resolved_dns
                    resolved_dns=$(dig +short "$server_name")
                    # Redirect debug output to stderr
                    echo "[DEBUG]: Resolved DNS for $server_name: $resolved_dns" >&2
                    local output
                    local exit_code
                    # Curl output format captures time and status code
                    output=$(curl --connect-timeout 5 -s -w "%{time_total} %{http_code}" -o /dev/null "$url")
                    exit_code=$?
                    if [ $exit_code -eq 0 ]; then
                        local time
                        local status
                        time=$(echo "$output" | awk '{print $1}')
                        status=$(echo "$output" | awk '{print $2}')
                        if [ "$status" -eq 200 ]; then
                            # Echo latency to stdout (captured by command substitution)
                            echo "$time"
                        else
                            # Redirect error message to stderr
                            echo "Curl request to $url failed with HTTP status $status" >&2
                            # Echo fallback value to stdout (captured by command substitution)
                            echo "999"
                        fi
                    else
                        # Handle curl specific errors (e.g., timeout, DNS resolution failure)
                        # Redirect error message to stderr
                        echo "Curl command failed for $url with exit code $exit_code" >&2
                         # Check for timeout error (exit code 28)
                        if [ $exit_code -eq 28 ]; then
                            # Redirect error message to stderr
                            echo "Curl request timed out for $url" >&2
                        fi
                        # Echo fallback value to stdout (captured by command substitution)
                        echo "999"
                    fi
                }

                echo "Probing regional servers (Europe, America, Asia)..."
                EUROPE_HOST=cvmfs-frankfurt.neurodesk.org
                AMERICA_HOST=cvmfs-jetstream.neurodesk.org
                ASIA_HOST=cvmfs-brisbane.neurodesk.org2
                
                EUROPE_url="http://${EUROPE_HOST}/cvmfs/neurodesk.ardc.edu.au/.cvmfspublished" 
                AMERICA_url="http://${AMERICA_HOST}/cvmfs/neurodesk.ardc.edu.au/.cvmfspublished"
                ASIA_url="http://${ASIA_HOST}/cvmfs/neurodesk.ardc.edu.au/.cvmfspublished"

                EUROPE_latency=$(get_latency "$EUROPE_url" "$EUROPE_HOST")
                echo "Europe Latency: $EUROPE_latency"
                AMERICA_latency=$(get_latency "$AMERICA_url" "$AMERICA_HOST")
                echo "America Latency: $AMERICA_latency"
                ASIA_latency=$(get_latency "$ASIA_url" "$ASIA_HOST")
                echo "Asia Latency: $ASIA_latency"

                # Find the fastest region
                printf "%s europe\n%s america\n%s asia\n" "$EUROPE_latency" "$AMERICA_latency" "$ASIA_latency"
                FASTEST_REGION=$(printf "%s europe\n%s america\n%s asia\n" "$EUROPE_latency" "$AMERICA_latency" "$ASIA_latency" | sort -n | head -n 1 | awk '{print $2}')

                echo "Probing connection modes (Direct vs CDN)..."
                DIRECT_HOST=cvmfs-geoproximity.neurodesk.org
                CDN_HOST=cvmfs.neurodesk.org

                DIRECT_url="http://${DIRECT_HOST}/cvmfs/neurodesk.ardc.edu.au/.cvmfspublished" 
                CDN_url="http://${CDN_HOST}/cvmfs/neurodesk.ardc.edu.au/.cvmfspublished"

                DIRECT_latency=$(get_latency "$DIRECT_url" "$DIRECT_HOST")
                echo "Direct Latency: $DIRECT_latency"
                CDN_latency=$(get_latency "$CDN_url" "$CDN_HOST")
                echo "CDN Latency: $CDN_latency"

                # Determine the fastest mode
                FASTEST_MODE=$(printf "%s direct\n%s cdn\n" "$DIRECT_latency" "$CDN_latency" | sort -n | head -n 1 | awk '{print $2}')
                
                echo "Fastest region determined: $FASTEST_REGION"
                echo "Fastest mode determined: $FASTEST_MODE"

                # copying the selected config file
                config_file_suffix="${FASTEST_MODE}.${FASTEST_REGION}"
                source_config="/etc/cvmfs/config.d/neurodesk.ardc.edu.au.conf.${config_file_suffix}"
                target_config="/etc/cvmfs/config.d/neurodesk.ardc.edu.au.conf"
                
                if [ -f "$source_config" ]; then
                    echo "Selected config file: $source_config"
                    cp "$source_config" "$target_config"
                # else
                #     echo "Warning: Config file $source_config not found. Using default."
                    # cp /etc/cvmfs/config.d/neurodesk.ardc.edu.au.conf.default $target_config
                fi
                exit

                echo "\
                ==================================================================
                Mounting CVMFS"
                if ( service autofs status > /dev/null ); then
                    echo "autofs is running - not attempting to mount manually:"
                    ls /cvmfs/neurodesk.ardc.edu.au/neurodesk-modules/ 2>/dev/null && echo "CVMFS is ready after autofs mount" || echo "AutoFS not working!"
                else
                    echo "autofs is NOT running - attempting to mount manually:"
                    mkdir -p /cvmfs/neurodesk.ardc.edu.au
                    mount -t cvmfs neurodesk.ardc.edu.au /cvmfs/neurodesk.ardc.edu.au

                    ls /cvmfs/neurodesk.ardc.edu.au/neurodesk-modules/ 2>/dev/null && echo "CVMFS is ready after manual mount" || echo "Manual CVMFS mount not successful"

                    echo "\
                    ==================================================================
                    CVMFS servers:"
                    if [ "$mode" = "direct" ]; then
                        cvmfs_talk -i neurodesk.ardc.edu.au host probe
                    fi
                    cvmfs_talk -i neurodesk.ardc.edu.au host info
                fi
            fi
        fi
    fi
fi

source /opt/neurodesktop/environment_variables.sh
