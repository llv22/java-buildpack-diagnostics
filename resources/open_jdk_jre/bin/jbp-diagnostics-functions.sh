# based on blog post code http://tmont.com/blargh/2014/1/uploading-to-s3-in-bash
upload_to_s3() {
    filepath="$1"
    filename="$2"
    if [[ -z "$filename" ]]; then
        filename=$(basename "$filepath")
    fi
    s3Bucket=$JBPDIAG_AWS_BUCKET
    s3Key=$JBPDIAG_AWS_ACCESS_KEY
    s3Secret=$JBPDIAG_AWS_SECRET_KEY
    contentType="application/octet-stream"
    resource="/${s3Bucket}/$filename"
    dateValue=`date -R`
    stringToSign="PUT\n\n${contentType}\n${dateValue}\n${resource}"
    signature=`echo -en ${stringToSign} | openssl sha1 -hmac ${s3Secret} -binary | base64`
    curl -X PUT -T "${filepath}" \
      -H "Host: ${s3Bucket}.s3.amazonaws.com" \
      -H "Date: ${dateValue}" \
      -H "Content-Type: ${contentType}" \
      -H "Authorization: AWS ${s3Key}:${signature}" \
      https://${s3Bucket}.s3.amazonaws.com/${filename}
}

upload_oom_heapdump_to_s3() {
    heapdumpfile=$PWD/oom_heapdump.hprof
    if [ -e $heapdumpfile ]; then
        gzip $heapdumpfile
        filename="oom_heapdump_$(date +"%s").hprof.gz"
        upload_to_s3 ${heapdumpfile}.gz $filename && rm ${heapdumpfile}.gz
    fi
}
