#!/bin/bash

# CIDGOH (Hsiao lab): Data transfer 
version="0.1"
logo=$(cat <<-END

░█████╗░██╗██████╗░░██████╗░░█████╗░██╗░░██╗
██╔══██╗██║██╔══██╗██╔════╝░██╔══██╗██║░░██║
██║░░╚═╝██║██║░░██║██║░░██╗░██║░░██║███████║
██║░░██╗██║██║░░██║██║░░╚██╗██║░░██║██╔══██║
╚█████╔╝██║██████╔╝╚██████╔╝╚█████╔╝██║░░██║
░╚════╝░╚═╝╚═════╝░░╚═════╝░░╚════╝░╚═╝░░╚═╝

END
)

default_local_end="54f7d944-2c67-11ec-95dc-853490a236f9"
default_remote_end="9cd65512-2c5b-11ec-9e48-3df4ed83d858"
sync='checksum'

# Sync options:
#   exists   Copy files that do not exist at the destination.
#   size     Copy files if the size of the destination does not match the size of the source.
#   mtime    Copy files if the timestamp of the destination is older than the timestamp of the source.
#   checksum Copy files if checksums of the source and destination do not match. Files on the destination are never deleted


function check_rc () {
    if [ $# -gt 0 ]; then
        abort_message="$1"
    fi

    if [ $rc -ne 0 ]; then
        exit 1
    fi
}


function help_and_exit () {
	echo -e "$logo"
    echo ""
    echo "https://cidgoh.ca/"
    echo ""
    echo "version: $version"

	cat << EOF

    usage: ./data_manager.sh -i input_folder -u email_address

    The following options are available:'

    -s, --local-endpoint: The local endpoint you want to copy data from
    -r, --remote_endpoint: The remote endpoint you want to copy data to
    -i, --$input_dir: The local path for the folder you want to copy from
    -o, --$output_dir: The remote path for the folder you want to copy to
    -u, --user-id: Email for user you want to grant access to your shared (default read only)
    -g, --group-uuid: Group UUID for a group you want to grant read access (default read only)
    -d, --delete: Delete destination folder if it already exists
    -h, --help: Print this help message

    You need to set up local and remote endpoint before using this script. If you have any issues, please contact duanjun1981@gmail.com.

EOF
    exit 0

}

if [ $# -eq 0 ]; then
    help_and_exit
fi


while [ $# -gt 0 ]; do
    key="$1"
    case $1 in
        -s|--local-endpoint)
            shift
            local_endpoint=$1
        ;;
        -r|--remote-endpoint)
            shift
            remote_endpoint=$1
        ;;
        -i|--$input_dir)
            shift
            input_dir=$1
        ;;
        -o|--output_dir)
            shift
            output_dir=$1
        ;;
        -u|--user-id)
            shift
            user_id=$1
        ;;
        -g|--group-uuid)
            shift
            group_uuid=$1
        ;;
        -d|--delete)
            delete='yes'
        ;;
        -h|--help)
            help_and_exit
        ;;
        *)
            echo ''
            echo "Error: Unknown Option: '$1'"
            echo ''
            echo "$0 --help for options and more information."
            exit 1
    esac
    shift
done


if [ -z $local_endpoint ]; then
	local_endpoint=${default_local_end}
    echo "The default local endpoint will be used (${default_local_end})."
fi

if [ -z $remote_endpoint ]; then
	remote_endpoint=${default_remote_end}
    echo "The default source endpoint will be used (${default_remote_end})."
fi

if [ -z $output_dir ]; then
	output_dir="/~/"
    echo "The default destination fold is ${output_dir}."
fi


case "$input_dir" in
    /*)
    ;;
    *)
        echo 'input path must be absolute' >&2
        exit 1
    ;;
esac

globus ls "$remote_endpoint:$output_dir" 1>/dev/null
rc=$?
check_rc
echo "globus ls "$remote_endpoint:$output_dir""

# check if a directory with the same name was already transferred to the destination path
basename=`basename "$input_dir"`

# Add '/' if the user didn't provide one
if [ "${output_dir: -1}" != "/" ]; then
    output_dir="$output_dir/"
fi

destination_directory="$output_dir$basename/"
globus ls "$remote_endpoint:$destination_directory" 1>/dev/null 2>/dev/null



if [ $? == 0 ]; then
    # if it was, delete it
    if [ -n "$delete" ]; then
        echo "Destination directory, $destination_directory, exists and will be deleted"
        task_id=`globus delete --format unix --jmespath 'task_id' --label 'Share Data Example' -r "$remote_endpoint:$destination_directory"`
        globus task wait --timeout 600 $task_id
        rc=$?
        check_rc
    else
        >&2 echo \
            "Error: Destination directory, $output_dir$basename, already exists." \
            "Delete the directory or use --delete option"
        exit 1
    fi
fi

echo "Creating destination directory $output_dir"
globus mkdir "$remote_endpoint:$destination_directory"
rc=$?
check_rc

echo "$remote_endpoint:$destination_directory"

if [ -n "$user_id" ]; then
    echo "Granting user, $user_id, read access to the destination directory"
    globus endpoint permission create --provision-identity "$user_id" --permissions r "$remote_endpoint:$destination_directory" --notify-email "$user_id"
fi
if [ -n "$group_uuid" ]; then
    echo "Granting group, $group_uuid, read access to the destination directory"
    globus endpoint permission create --group $group_uuid --permissions r "$remote_endpoint:$destination_directory"
fi

echo "Submitting a transfer from $local_endpoint:$input_dir to $remote_endpoint:$destination_directory"
exec globus transfer --notify "succeeded" --recursive --sync-level $sync --label 'Share Data' "$local_endpoint:$input_dir" "$remote_endpoint:$destination_directory"