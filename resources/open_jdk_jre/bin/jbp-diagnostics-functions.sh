# based on blog post code http://tmont.com/blargh/2014/1/uploading-to-s3-in-bash
upload_to_s3() {
    filepath="$1"
    filename="$2"
    if [[ -z "$filename" ]]; then
        filename=$(basename "$filepath")
    fi
	
	dat=$(date +%Y-%m-%d:%H:%M:%S)
	filename=${dat}_${filename}
	if [ ! -z ${APP_NAME+x} ]; then
	    filename=$APP_NAME/$filename
	fi
	
	echo $filename

    if [[ -e $filepath ]]; then
		s3Endpoint="${JBPDIAG_AWS_ENDPOINT:-s3.amazonaws.com}"
		s3Bucket=$JBPDIAG_AWS_BUCKET
		s3Key=$JBPDIAG_AWS_ACCESS_KEY
		contentType="application/octet-stream"
		resource="/${s3Bucket}/$filename"
		dateValue=`date -R`
		stringToSign="PUT\n\n${contentType}\n${dateValue}\n${resource}"
		signature=`sign_s3_string "$stringToSign"`
		
		curl -X PUT -T "${filepath}" \
		  -H "Host: ${s3Bucket}.${s3Endpoint}" \
		  -H "Date: ${dateValue}" \
		  -H "Content-Type: ${contentType}" \
		  -H "Authorization: AWS ${s3Key}:${signature}" \
		  https://${s3Bucket}.${s3Endpoint}/${filename}
    fi
}

sign_s3_string() {
    stringToSign="$1"
    # >&2 echo "stringToSign '$stringToSign'"
    s3Secret=$JBPDIAG_AWS_SECRET_KEY
    echo -en "${stringToSign}" | openssl sha1 -hmac ${s3Secret} -binary | base64
}

jbp_urlencode() {
    python -c "import sys,urllib; print urllib.quote(sys.argv[1])" "$1"
}

upload_stdin_to_s3() {
    filename="$1"
    contentLength="$2"
    s3Endpoint="${JBPDIAG_AWS_ENDPOINT:-s3.amazonaws.com}"
    s3Bucket=$JBPDIAG_AWS_BUCKET
    s3Key=$JBPDIAG_AWS_ACCESS_KEY
    contentType="application/octet-stream"
    resource="/${s3Bucket}/$filename"
    dateValue=`date -R`
    stringToSign="PUT\n\n${contentType}\n${dateValue}\n${resource}"
    signature=`sign_s3_string "$stringToSign"`
    curl -X PUT --data-binary @- \
      -H "Host: ${s3Bucket}.${s3Endpoint}" \
      -H "Date: ${dateValue}" \
      -H "Content-Type: ${contentType}" \
      -H "Content-Length: ${contentLength}" \
      -H "Authorization: AWS ${s3Key}:${signature}" \
      https://${s3Bucket}.${s3Endpoint}/${filename}
}

calculate_presigned_s3_url() {
    filename="$1"
    s3Endpoint="${JBPDIAG_AWS_ENDPOINT:-s3.amazonaws.com}"
    s3Bucket=$JBPDIAG_AWS_BUCKET
    s3Key=$JBPDIAG_AWS_ACCESS_KEY
    resource="/${s3Bucket}/$filename"
    expires=`date --date="+48 hours" +"%s"`
    stringToSign="GET\n\n\n${expires}\n${resource}"
    signature=`sign_s3_string "$stringToSign"`
    echo "https://${s3Bucket}.${s3Endpoint}/${filename}?AWSAccessKeyId=${s3Key}&Expires=${expires}&Signature=`jbp_urlencode ${signature}`"
}

upload_oom_heapdump_to_s3() {
    heapdumpfile=$1
    if [[ -e $heapdumpfile && -n "$JBPDIAG_AWS_BUCKET" ]]; then
		echo "Compressing $heapdumpfile"
		gzip $heapdumpfile
		echo "Uploading to S3."
		upload_to_s3 ${heapdumpfile}.gz
    fi
}

create_stats_file() {
	statsfile=$1
	echo "
	Process Status 
	=======================
	$(ps -ef)

	ulimit (Before)
	===============
	$(ulimit -a)

	Free Disk Space 
	========================
	$(df -h)
	" >> $statsfile
		

	if [ -e  '/home/vcap/app/'  ]; then
	echo "
		OOM Directory 
		=======================
		$(ls /home/vcap/app/ -l)
	" >> $statsfile
	fi

}