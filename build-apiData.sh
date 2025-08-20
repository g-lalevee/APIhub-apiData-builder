#!/bin/bash

echo "INFO ---------- Get target Apigee Organization and +++ from .env file ----------"

echo "Proxy-name=$proxy_name"
echo "Apigee deployment suffix=$apigee_deployment_suffix"

export X_PROJECT=$apigee_org
echo "Apigee Organization=$X_PROJECT"
export X_REGION=$apihub_region
echo "API hub Region=$X_REGION"

export X_PLUGIN_NAME=$apihub_plugin_name
echo "API hub Plugin Name=$X_PLUGIN_NAME"

export X_INSTANCE_ID=$apihub_instance_id
echo "API hub Instance ID=$X_INSTANCE_ID"

echo " "
echo "INFO ---------- Build apiData needed values ------------------------------------"

# 1-Get Proxy Name --> API ID
# ---------------------------
export X_ORIGINAL_ID="$proxy_name$apigee_deployment_suffix"
echo "ORIGINAL_ID=$X_ORIGINAL_ID"


# 2-Apigee Target Environment --> Life cycle Stage 
# -------------------------------------------------
export X_LIFECYCLE="design"
echo "LIFECYCLE=$X_LIFECYCLE"


# 3- Specification File Name in folder ./specs/oas/proxy --> Specification Filename 
# ---------------------------------------------------------------------------------
# Define the folder and the file pattern
FOLDER="./specs/oas/proxy"
FILE_PATTERN="*.yaml"

# Get the First File Matching the pattern
SPEC_FILE_PATH=$(find "$FOLDER" -maxdepth 1 -type f -name "$FILE_PATTERN" | head -n 1)
echo SPEC_FILE_PATH=$SPEC_FILE_PATH

# Check if a file was found
if [[ -z "$SPEC_FILE_PATH" ]]; then
    echo "No files matching the pattern '$FILE_PATTERN' found in $FOLDER"
    export X_SPEC_FILE_NAME="specification_name"
else
    # Use shell parameter expansion to get just the filename
    export X_SPEC_FILE_NAME="${SPEC_FILE_PATH##*/}"
fi
echo "SPEC_FILE_NAME=$X_SPEC_FILE_NAME"


# 4- From Specification file --> API Display name, API Description, API Owner Name, API Owner email, API version Display name
# ---------------------------------------------------------------------------------------------------------------------------
# export X_API_DISPLAY_NAME=$(cat $SPEC_FILE_PATH | apigee-go-gen transform yaml-to-json | jq -r .info.title)
export X_API_DISPLAY_NAME="$proxy_name$apigee_deployment_suffix"
export X_API_DESCRIPTION=$(cat $SPEC_FILE_PATH | apigee-go-gen transform yaml-to-json | jq -r .info.description)
export X_API_VERSION=$(cat $SPEC_FILE_PATH | apigee-go-gen transform yaml-to-json | jq -r .info.version)
export X_API_OWNER_NAME=$(cat $SPEC_FILE_PATH | apigee-go-gen transform yaml-to-json | jq -r .info.contact.name)
export X_API_OWNER_EMAIL=$(cat $SPEC_FILE_PATH | apigee-go-gen transform yaml-to-json | jq -r .info.contact.email)
export X_CONTENT_B64=$(base64 --wrap=0 $SPEC_FILE_PATH)

echo API_DISPLAY_NAME=$X_API_DISPLAY_NAME
echo API_DESCRIPTION=$X_API_DESCRIPTION
echo API_VERSION=$X_API_VERSION
echo API_OWNER_NAME=$X_API_OWNER_NAME
echo API_OWNER_EMAI=$X_API_OWNER_EMAIL
echo CONTENT_B64=$X_CONTENT_B64


# 5- Get creation date and modification date of the OAS file
# ---------------------------------------------------------- 
# --- Get and format the Creation Timestamp ---

# Get the full timestamp string from stat
# Using %w for birth time (creation time)
creation_time_full=$(stat -c %w "$SPEC_FILE_PATH" 2>/dev/null)

# Fallback to modification time if creation time is not available
if [ -z "$creation_time_full" ]; then
    creation_time_full=$(stat -c %y "$FILE")
fi

# Extract the date, time, and nanoseconds parts
creation_date_part=$(echo "$creation_time_full" | awk '{print $1}')
creation_time_part=$(echo "$creation_time_full" | awk '{print $2}')
# Get the first three digits of nanoseconds for milliseconds
creation_nanos=$(echo "$creation_time_full" | awk '{print $2}' | cut -b 10-12)

# Use `date` to format the timestamp and then append milliseconds and 'Z'
export X_ORIGINAL_CREATE_TIME=$(date -u -d "${creation_date_part} ${creation_time_part}" +"%Y-%m-%dT%H:%M:%S")."${creation_nanos}Z"

# --- Get and format the Modification Timestamp ---

# Get the full timestamp string for modification time (%y)
modification_time_full=$(stat -c %y "$SPEC_FILE_PATH")

# Extract the date, time, and nanoseconds parts
modification_date_part=$(echo "$modification_time_full" | awk '{print $1}')
modification_time_part=$(echo "$modification_time_full" | awk '{print $2}')
# Get the first three digits of nanoseconds for milliseconds
modification_nanos=$(echo "$modification_time_full" | awk '{print $2}' | cut -b 10-12)

# Use `date` to format the timestamp and then append milliseconds and 'Z'
export X_ORIGINAL_UPDATE_TIME=$(date -u -d "${modification_date_part} ${modification_time_part}" +"%Y-%m-%dT%H:%M:%S")."${modification_nanos}Z"

# Output the results
echo "ORIGINAL_CREATE_TIME=$X_ORIGINAL_CREATE_TIME"
echo "ORIGINAL_UPDATE_TIME=$X_ORIGINAL_UPDATE_TIME"


echo " "
echo "INFO ---------- Create apiData file from template -------------------------------------------------"
envsubst < $apihub_apiData_template > apiData.json
