# Compute Canada data manager

```
  usage: ./cc_data_manager.sh -i input_folder -u email_address
  
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
```
