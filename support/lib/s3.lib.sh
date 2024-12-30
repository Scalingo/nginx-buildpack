# vim:set ft=sh:

# This file contains functions based on 'aws s3api' to manipulate S3 data
# Env vars requirement:
# - `AWS_ACCESS_KEY_ID`
# - `AWS_SECRET_ACCESS_KEY`
# - `AWS_SESSION_TOKEN`

s3_upload() {
	# https://awscli.amazonaws.com/v2/documentation/api/latest/reference/s3api/put-object.html
	bucket="${1}"
	file="${2}"
	key="${3}"

	aws s3api put-object --acl "public-read" --body "${file}" \
		--bucket "${bucket}" --key "${key}"
}

s3_download() {
	# https://awscli.amazonaws.com/v2/documentation/api/latest/reference/s3api/get-object.html
	bucket="${1}"
	key="${2}"
	output="${3}"

	aws s3api get-object --bucket "${bucket}" --key "${key}" "${output}"
}

s3_list() {
	# https://awscli.amazonaws.com/v2/documentation/api/latest/reference/s3api/list-objects-v2.html
	bucket="${1}"
	# prefix can be empty
	prefix="${2:-}"

	aws s3api list-objects-v2 --bucket "${bucket}" --prefix "${prefix}" --no-paginate
}
