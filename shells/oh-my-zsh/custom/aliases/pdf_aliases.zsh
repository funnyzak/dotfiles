# Description: PDF related aliases for conversion, compression, encryption, and manipulation.

# PDF to Image Conversion
alias pdf2pic_f='(){
  if [ $# -eq 0 ]; then
    echo "Convert PDF to images (using pdf2pic).\nUsage:\n pdf2pic_f <pdf_path>"
    return 1
  fi
  pdf_path=$1
  echo "Converting PDF $pdf_path to images using pdf2pic..."
  pdf2pic -i "$@" && echo "Conversion complete"
}'  # Convert PDF to images using pdf2pic

alias pdf2pic_dir='(){
  if [ $# -eq 0 ]; then
    echo "Convert PDF files in directory to images (using pdf2pic).\nUsage:\n pdf2pic_dir <dir_path>"
    return 1
  fi
  dir_path=$1
  echo "Converting PDF files in $dir_path to images using pdf2pic..."
  for file in $(find "$dir_path" -type f -name "*.pdf"); do
    pdf2pic -i "$file"
    echo "Converted $file"
  done
  echo "Batch conversion complete"
}'  # Convert PDF files in a directory to images using pdf2pic

alias pdf2jpg='(){
  if [ $# -eq 0 ]; then
    echo "Convert PDF to JPG images (using ImageMagick).\nUsage:\n pdf2jpg <pdf_path>"
    return 1
  fi
  pdf_path=$1
  output_prefix="$(basename "$pdf_path")"
  echo "Converting PDF $pdf_path to JPG images using ImageMagick, output prefix $output_prefix..."
  magick convert -density 300 "$pdf_path" "${output_prefix}_%02d.jpg" && echo "Conversion complete, exported to ${output_prefix}_%02d.jpg"
}'  # Convert PDF to JPG images using ImageMagick

# PDF Compression
alias gs_pdf='(){
  if [ $# -eq 0 ]; then
    echo "Compress PDF (using Ghostscript).\nUsage:\n gs_pdf <pdf_path> [option:ebook|printer|screen]"
    return 1
  fi
  pdf_path=$1
  option=${2:-"screen"}
  output_file="$(dirname "$pdf_path")/$(basename "$pdf_path" .pdf)_${option}.pdf"
  echo "Compressing PDF $pdf_path using Ghostscript with option '$option', output to $output_file..."
  gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dPDFSETTINGS="/${option}" -dNOPAUSE -dBATCH -sOutputFile="$output_file" "$pdf_path" && 
  echo "Compression complete, saved to $output_file"
}'  # Compress PDF using Ghostscript with different quality settings

alias gs_pdf_dir='(){
  if [ $# -eq 0 ]; then
    echo "Compress PDF files in directory (using Ghostscript).\nUsage:\n gs_pdf_dir <dir_path> [option:ebook|printer|screen]"
    return 1
  fi
  dir_path=$1
  option=${2:-"screen"}
  output_dir="$dir_path/$option"
  mkdir -p "$output_dir"
  echo "Compressing PDF files in $dir_path using Ghostscript with option '$option', output to $output_dir..."
  for file in $(find "$dir_path" -type f -name "*.pdf"); do
    output_file="$output_dir/$(basename "$file" .pdf)_${option}.pdf"
    gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dPDFSETTINGS="/${option}" -dNOPAUSE -dBATCH -sOutputFile="$output_file" "$file"
    echo "Compressed $file to $output_file"
  done
  echo "Batch compression complete"
}'  # Compress multiple PDF files in a directory using Ghostscript

# PDF Encryption
alias pdf_encrypt='(){
  if [ $# -eq 0 ]; then
    echo "Encrypt PDF (using Ghostscript).\nUsage:\n pdf_encrypt <source_pdf_path> [output_pdf_path] [owner_password] [user_password]"
    return 1
  fi
  source_pdf_path=$1
  output_pdf_path="$2"
  owner_password="${3:-"$(openssl rand -base64 12)"}"
  user_password="${4:-"$(openssl rand -base64 12)"}"
  if [ -z "$source_pdf_path" ]; then
    echo "Error: Source PDF path is required."
    return 1
  fi
  if [ -z "$output_pdf_path" ]; then
    output_pdf_path="${source_pdf_path%.*}_$(openssl rand -hex 4).pdf"
  fi
  echo "Encrypting PDF $source_pdf_path, output to $output_pdf_path..."
  gs -q -dNOPAUSE -dBATCH -sDEVICE=pdfwrite -sOutputFile="$output_pdf_path" -dPDFSETTINGS=/prepress -dPassThroughJPEGImages=true -sOwnerPassword="$owner_password" -sUserPassword="$user_password" -dEncryptionR=3 -dKeyLength=128 -dPermissions=-4 "$source_pdf_path" && 
  echo "\nPDF encryption completed successfully.\n--------------------\nSource file: $source_pdf_path\nOutput file: $output_pdf_path\nPdf name: $(basename $output_pdf_path)\nUser password: $user_password\nOwner password: $owner_password\n\n\n$(basename $output_pdf_path)\nPassword: $user_password\n--------------------"
}'  # Encrypt PDF using Ghostscript with password protection