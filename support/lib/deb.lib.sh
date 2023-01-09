extract_deb() {
  local deb_file=$1
  local install_dir=$2

  ar x "$deb_file"

  local archive_format=""
  local archive_tar_compression=""
  if [ -f "data.tar.xz" ] ; then
    archive_format="xz"
    archive_tar_compression="xz"
  elif [ -f "data.tar.zst" ] ; then
    archive_format="zst"
    archive_tar_compression="zstd"
  else
    echo "DEB ${deb_file} has invalid archive format: $(ls data*)"
    return -1
  fi

  local data_archive_file="data.tar.${archive_format}"

  tar --extract "--${archive_tar_compression}" --directory "${install_dir}" --file "${data_archive_file}"

  rm "control.tar.${archive_format}"
  rm "${data_archive_file}"

  return 0
}

