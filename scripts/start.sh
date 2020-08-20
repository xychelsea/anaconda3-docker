#!/bin/bash
# Copyright (c) Jupyter Development Team.
# Distributed under the terms of the Modified BSD License.

set -e

# Exec the specified command or fall back on bash
if [ $# -eq 0 ]; then
    cmd=( "bash" )
else
    cmd=( "$@" )
fi

run-hooks () {
    # Source scripts or run executable files in a directory
    if [[ ! -d "$1" ]] ; then
        return
    fi
    echo "$0: running hooks in $1"
    for f in "$1/"*; do
        case "$f" in
            *.sh)
                echo "$0: running $f"
                source "$f"
                ;;
            *)
                if [[ -x "$f" ]] ; then
                    echo "$0: running $f"
                    "$f"
                else
                    echo "$0: ignoring $f"
                fi
                ;;
        esac
    done
    echo "$0: done running hooks in $1"
}

run-hooks /usr/local/bin/jupyter-start-notebook.d

# Handle special flags if we're root
if [ $(id -u) == 0 ] ; then

    # Only attempt to change the anaconda username if it exists
    if id anaconda &> /dev/null ; then
        echo "Set username to: $ANACONDA_USER"
        usermod -d /home/$ANACONDA_USER -l $ANACONDA_USER anaconda
    fi

    # Handle case where provisioned storage does not have the correct permissions by default
    # Ex: default NFS/EFS (no auto-uid/gid)
    if [[ "$CHOWN_HOME" == "1" || "$CHOWN_HOME" == 'yes' ]]; then
        echo "Changing ownership of /home/$ANACONDA_USER to $ANACONDA_UID:$ANACONDA_GID with options '${CHOWN_HOME_OPTS}'"
        chown $CHOWN_HOME_OPTS $ANACONDA_UID:$ANACONDA_GID /home/$ANACONDA_USER
    fi
    if [ ! -z "$CHOWN_EXTRA" ]; then
        for extra_dir in $(echo $CHOWN_EXTRA | tr ',' ' '); do
            echo "Changing ownership of ${extra_dir} to $ANACONDA_UID:$ANACONDA_GID with options '${CHOWN_EXTRA_OPTS}'"
            chown $CHOWN_EXTRA_OPTS $ANACONDA_UID:$ANACONDA_GID $extra_dir
        done
    fi

    # handle home and working directory if the username changed
    if [[ "$ANACONDA_USER" != "anaconda" ]]; then
        # changing username, make sure homedir exists
        # (it could be mounted, and we shouldn't create it if it already exists)
        if [[ ! -e "/home/$ANACONDA_USER" ]]; then
            echo "Relocating home dir to /home/$ANACONDA_USER"
            mv /home/anaconda "/home/$ANACONDA_USER" || ln -s /home/anaconda "/home/$ANACONDA_USER"
        fi
        # if workdir is in /home/anaconda, cd to /home/$ANACONDA_USER
        if [[ "$PWD/" == "/home/anaconda/"* ]]; then
            newcwd="/home/$ANACONDA_USER/${PWD:13}"
            echo "Setting CWD to $newcwd"
            cd "$newcwd"
        fi
    fi

    # Change UID:GID of ANACONDA_USER to ANACONDA_UID:ANACONDA_GID if it does not match
    if [ "$ANACONDA_UID" != $(id -u $ANACONDA_USER) ] || [ "$ANACONDA_GID" != $(id -g $ANACONDA_USER) ]; then
        echo "Set user $ANACONDA_USER UID:GID to: $ANACONDA_UID:$ANACONDA_GID"
        if [ "$ANACONDA_GID" != $(id -g $ANACONDA_USER) ]; then
            groupadd -g $ANACONDA_GID -o ${ANACONDA_GROUP:-${ANACONDA_USER}}
        fi
        userdel $ANACONDA_USER
        useradd --home /home/$ANACONDA_USER -u $ANACONDA_UID -g $ANACONDA_GID -G 100 -l $ANACONDA_USER
    fi

    # Enable sudo if requested
    if [[ "$GRANT_SUDO" == "1" || "$GRANT_SUDO" == 'yes' ]]; then
        echo "Granting $ANACONDA_USER sudo access and appending $ANACONDA_PATH/bin to sudo PATH"
        echo "$ANACONDA_USER ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/notebook
    fi

    # Add $ANACONDA_PATH/bin to sudo secure_path
    sed -r "s#Defaults\s+secure_path\s*=\s*\"?([^\"]+)\"?#Defaults secure_path=\"\1:$ANACONDA_PATH/bin\"#" /etc/sudoers | grep secure_path > /etc/sudoers.d/path

    # Exec the command as ANACONDA_USER with the PATH and the rest of
    # the environment preserved
    run-hooks /usr/local/bin/jupyter-before-notebook.d
    echo "Executing the command: ${cmd[@]}"
    exec sudo -E -H -u $ANACONDA_USER PATH=$PATH XDG_CACHE_HOME=/home/$ANACONDA_USER/.cache PYTHONPATH=${PYTHONPATH:-} "${cmd[@]}"
else
    if [[ "$ANACONDA_UID" == "$(id -u anaconda 2>/dev/null)" && "$ANACONDA_GID" == "$(id -g anaconda 2>/dev/null)" ]]; then
        # User is not attempting to override user/group via environment
        # variables, but they could still have overridden the uid/gid that
        # container runs as. Check that the user has an entry in the passwd
        # file and if not add an entry.
        STATUS=0 && whoami &> /dev/null || STATUS=$? && true
        if [[ "$STATUS" != "0" ]]; then
            if [[ -w /etc/passwd ]]; then
                echo "Adding passwd file entry for $(id -u)"
                cat /etc/passwd | sed -e "s/^anaconda:/adnocana:/" > /tmp/passwd
                echo "anaconda:x:$(id -u):$(id -g):,,,:/home/anaconda:/bin/bash" >> /tmp/passwd
                cat /tmp/passwd > /etc/passwd
                rm /tmp/passwd
            else
                echo 'Container must be run with group "root" to update passwd file'
            fi
        fi

        # Warn if the user isn't going to be able to write files to $HOME.
        if [[ ! -w /home/anaconda ]]; then
            echo 'Container must be run with group "users" to update files'
        fi
    else
        # Warn if looks like user want to override uid/gid but hasn't
        # run the container as root.
        if [[ ! -z "$ANACONDA_UID" && "$ANACONDA_UID" != "$(id -u)" ]]; then
            echo 'Container must be run as root to set $ANACONDA_UID'
        fi
        if [[ ! -z "$ANACONDA_GID" && "$ANACONDA_GID" != "$(id -g)" ]]; then
            echo 'Container must be run as root to set $ANACONDA_GID'
        fi
    fi

    # Warn if looks like user want to run in sudo mode but hasn't run
    # the container as root.
    if [[ "$GRANT_SUDO" == "1" || "$GRANT_SUDO" == 'yes' ]]; then
        echo 'Container must be run as root to grant sudo permissions'
    fi

    # Execute the command
    run-hooks /usr/local/bin/jupyter-before-notebook.d
    echo "Executing the command: ${cmd[@]}"
    exec "${cmd[@]}"
fi
