# vim:set ft=sh:

# This file contains functions based on 's3cmd' to manipulate S3 data
# Env var requirement:
# * S3_ACCESS_KEY
# * S3_SECRET_KEY

s3_upload() {
  bucket="$1"
  file="$2"
  object_path="$3"
  s3cmd --access_key="${S3_ACCESS_KEY}" --secret_key="${S3_SECRET_KEY}" --verbose --acl-public put "${file}" "s3://${bucket}${object_path}"
}

s3_download() {
  bucket="$1"
  object_path="$2"
  file="$3"
  s3cmd --access_key="${S3_ACCESS_KEY}" --secret_key="${S3_SECRET_KEY}" --verbose get "s3://${bucket}${object_path}" "$file"
}

s3_list() {
  bucket="$1"
  # prefix can be empty
  prefix="${2:-}"
  s3cmd --access_key="${S3_ACCESS_KEY}" --secret_key="${S3_SECRET_KEY}" ls --recursive "s3://${bucket}${prefix}"
}
