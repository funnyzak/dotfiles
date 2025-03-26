# Description: MinIO client (mc) aliases for object storage operations, management, and file transfers.

# MinIO host management
alias mc_host='() { 
  if [ $# -eq 0 ]; then 
    echo "Add MinIO host configuration.\nUsage:\n mc_host <alias> <server_url>"
    return 1
  else 
    echo "Adding MinIO host $1 with URL $2"
    mc config host add $1 $2
  fi 
}'  # Add MinIO host configuration

# Bucket and object listing
alias mc_ls='() { 
  if [ $# -eq 0 ]; then 
    echo "List MinIO buckets.\nUsage:\n mc_ls <alias>"
    return 1
  else 
    echo "Listing buckets for host $1"
    mc ls $1
  fi 
}'  # List MinIO buckets

# Bucket creation
alias mc_mb='() { 
  if [ $# -eq 0 ]; then 
    echo "Create MinIO bucket.\nUsage:\n mc_mb <alias> <bucket_name>"
    return 1
  else 
    echo "Creating bucket $2 on host $1"
    mc mb $1/$2
  fi 
}'  # Create MinIO bucket

# Bucket removal
alias mc_rb='() { 
  if [ $# -eq 0 ]; then 
    echo "Remove MinIO bucket.\nUsage:\n mc_rb <alias> <bucket_name>"
    return 1
  else 
    echo "Removing bucket $2 from host $1"
    mc rb $1/$2
  fi 
}'  # Remove MinIO bucket

# Object copying
alias mc_cp='() { 
  if [ $# -eq 0 ]; then 
    echo "Copy MinIO object.\nUsage:\n mc_cp <alias> <source_path> <target_path>"
    return 1
  else 
    echo "Copying object from $1/$2 to $1/$3"
    mc cp $1/$2 $1/$3
  fi 
}'  # Copy MinIO object

# Object removal
alias mc_rm='() { 
  if [ $# -eq 0 ]; then 
    echo "Remove MinIO object.\nUsage:\n mc_rm <alias> <object_path>"
    return 1
  else 
    echo "Removing object $1/$2"
    mc rm $1/$2
  fi 
}'  # Remove MinIO object

# Object content viewing
alias mc_cat='() { 
  if [ $# -eq 0 ]; then 
    echo "View MinIO object content.\nUsage:\n mc_cat <alias> <object_path>"
    return 1
  else 
    echo "Viewing content of object $1/$2"
    mc cat $1/$2
  fi 
}'  # View MinIO object content

# Object sharing
alias mc_share='() { 
  if [ $# -eq 0 ]; then 
    echo "Generate shareable link for MinIO object.\nUsage:\n mc_share <alias> <object_path> [expiry_time:24h]"
    return 1
  else 
    expire=${3:-24h}
    echo "Generating shareable link for $1/$2 with expiry $expire"
    mc share download --expire ${expire} $1/$2
  fi 
}'  # Generate shareable link for MinIO object