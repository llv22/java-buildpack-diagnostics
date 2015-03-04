# based on blog post code http://tmont.com/blargh/2014/1/uploading-to-s3-in-bash
upload_to_s3() {
    filepath="$1"
    filename="$2"
    if [[ -z "$filename" ]]; then
        filename=$(basename "$filepath")
    fi
    s3Bucket=$JBPDIAG_AWS_BUCKET
    s3Key=$JBPDIAG_AWS_ACCESS_KEY
    contentType="application/octet-stream"
    resource="/${s3Bucket}/$filename"
    dateValue=`date -R`
    stringToSign="PUT\n\n${contentType}\n${dateValue}\n${resource}"
    signature=`sign_s3_string "$stringToSign"`
    curl -X PUT -T "${filepath}" \
      -H "Host: ${s3Bucket}.s3.amazonaws.com" \
      -H "Date: ${dateValue}" \
      -H "Content-Type: ${contentType}" \
      -H "Authorization: AWS ${s3Key}:${signature}" \
      https://${s3Bucket}.s3.amazonaws.com/${filename}
}

sign_s3_string() {
    stringToSign="$1"
    s3Secret=$JBPDIAG_AWS_SECRET_KEY
    echo -en "${stringToSign}" | openssl sha1 -hmac ${s3Secret} -binary | base64
}

upload_stdin_to_s3() {
    filename="$1"
    contentLength="$2"
    s3Bucket=$JBPDIAG_AWS_BUCKET
    s3Key=$JBPDIAG_AWS_ACCESS_KEY
    contentType="application/octet-stream"
    resource="/${s3Bucket}/$filename"
    dateValue=`date -R`
    stringToSign="PUT\n\n${contentType}\n${dateValue}\n${resource}"
    signature=`sign_s3_string "$stringToSign"`
    curl -X PUT --data-binary @- \
      -H "Host: ${s3Bucket}.s3.amazonaws.com" \
      -H "Date: ${dateValue}" \
      -H "Content-Type: ${contentType}" \
      -H "Content-Length: ${contentLength}" \
      -H "Authorization: AWS ${s3Key}:${signature}" \
      https://${s3Bucket}.s3.amazonaws.com/${filename}
}

calculate_presigned_s3_url() {
    filename="$1"
    s3Bucket=$JBPDIAG_AWS_BUCKET
    s3Key=$JBPDIAG_AWS_ACCESS_KEY
    resource="/${s3Bucket}/$filename"
    expires=`date --date="+48 hours" +"%s"`
    stringToSign="GET\n\n\n${expires}\n${resource}"
    signature=`sign_s3_string "$stringToSign"`
    echo "https://${s3Bucket}.s3.amazonaws.com/${filename}?AWSAccessKeyId=${s3Key}&Expires=${expires}&Signature=${signature}"
}

upload_oom_heapdump_to_s3() {
    usetempfile="$1"
    heapdumpfile=$PWD/oom_heapdump.hprof
    if [[ -e $heapdumpfile && -n "$JBPDIAG_AWS_BUCKET" ]]; then
        filename="oom_heapdump_$(date +"%s").hprof.gz"
        s3_presign_url=`calculate_presigned_s3_url $filename`
        echo "$s3_presign_url" >> $PWD/oom_heapdump_download_urls
        if [[ $usetempfile == 1 ]]; then
            # usage of temporary file is allowed
            echo "Compressing $heapdumpfile"
            gzip $heapdumpfile
            echo "Uploading to S3. Presigned access url: $s3_presign_url"
            upload_to_s3 ${heapdumpfile}.gz $filename && rm ${heapdumpfile}.gz
        else
            echo "Calculating compressed size first to minimize disk space usage"
            gzippedsize=`cat $heapdumpfile | gzip -c | wc -c | awk '{print $1}'`
            echo "Compressing and uploading $gzippedsize bytes to S3. Presigned access url: $s3_presign_url"
            cat $heapdumpfile | gzip -c | upload_stdin_to_s3 $filename $gzippedsize && rm $heapdumpfile
        fi
    fi
}
