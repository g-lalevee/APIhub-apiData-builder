#!/bin/bash

  echo "INFO ---------- Get target Apigee Organization and Environment from .env file"
          set -a
          source .env
          set +a
          
          # 1-Get Proxy Name --> API ID
          # ---------------------------
          export ORIGINAL_ID="$proxy_name$APIGEE_DEPLOYMENT_SUFFIX"
          echo "ORIGINAL_ID=$ORIGINAL_ID"


          # 2-Apigee Target Environment --> Life cycle Stage 
          # -------------------------------------------------
          export LIFECYCLE="design"
          echo "LIFECYCLE=$LIFECYCLE"


          # 3- Specification File Name in folder ./specs/oas/proxy --> Specification Filename 
          # ---------------------------------------------------------------------------------
          # Define the folder and the file pattern
          FOLDER="./specs/oas/proxy"
          FILE_PATTERN="*.yaml"

          # Get the First File Matching the pattern
          SPEC_FILE_PATH=$(find "$FOLDER" -maxdepth 1 -type f -name "$FILE_PATTERN" | head -n 1)
          echo $SPEC_FILE_PATH

          # Check if a file was found
          if [[ -z "$SPEC_FILE_PATH" ]]; then
              echo "No files matching the pattern '$FILE_PATTERN' found in $FOLDER"
              SPEC_FILE_NAME="specification_name"
          else
              # Use shell parameter expansion to get just the filename
              SPEC_FILE_NAME="${SPEC_FILE_PATH##*/}"
          fi
          echo "SPEC_FILE_NAME=$SPEC_FILE_NAME"


          # 4- From Specification file --> API Display name, API Description, API Owner Name, API Owner email, API version Display name
          # ---------------------------------------------------------------------------------------------------------------------------
          export api_url=$(cat ./specs/oas/proxy/airports-spec.yaml | apigee-go-gen transform yaml-to-json | jq -r .servers[0].url | cut -c 9-)

          export API_DISPLAY_NAME=$(cat $SPEC_FILE_PATH | apigee-go-gen transform yaml-to-json | jq -r .info.title)
          export API_DESCRIPTION=$(cat $SPEC_FILE_PATH | apigee-go-gen transform yaml-to-json | jq -r .info.description)
          export API_VERSION=$(cat $SPEC_FILE_PATH | apigee-go-gen transform yaml-to-json | jq -r .info.version)
          export API_OWNER_NAME=$(cat $SPEC_FILE_PATH | apigee-go-gen transform yaml-to-json | jq -r .info.contact.name)
          export API_OWNER_EMAIL=$(cat $SPEC_FILE_PATH | apigee-go-gen transform yaml-to-json | jq -r .info.contact.email)
          export CONTENT_B64=$(base64 --wrap=0 $SPEC_FILE_PATH)

          echo $API_DISPLAY_NAME
          echo $API_DESCRIPTION
          echo $API_VERSION
          echo $API_OWNER_NAME
          echo $API_OWNER_EMAIL
          echo $CONTENT_B64


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
          export ORIGINAL_CREATE_TIME=$(date -u -d "${creation_date_part} ${creation_time_part}" +"%Y-%m-%dT%H:%M:%S")."${creation_nanos}Z"

          # --- Get and format the Modification Timestamp ---

          # Get the full timestamp string for modification time (%y)
          modification_time_full=$(stat -c %y "$SPEC_FILE_PATH")

          # Extract the date, time, and nanoseconds parts
          modification_date_part=$(echo "$modification_time_full" | awk '{print $1}')
          modification_time_part=$(echo "$modification_time_full" | awk '{print $2}')
          # Get the first three digits of nanoseconds for milliseconds
          modification_nanos=$(echo "$modification_time_full" | awk '{print $2}' | cut -b 10-12)

          # Use `date` to format the timestamp and then append milliseconds and 'Z'
          export ORIGINAL_UPDATE_TIME=$(date -u -d "${modification_date_part} ${modification_time_part}" +"%Y-%m-%dT%H:%M:%S")."${modification_nanos}Z"

          # Output the results
          echo "ORIGINAL_CREATE_TIME=$ORIGINAL_CREATE_TIME"
          echo "ORIGINAL_UPDATE_TIME=$ORIGINAL_UPDATE_TIME"
          