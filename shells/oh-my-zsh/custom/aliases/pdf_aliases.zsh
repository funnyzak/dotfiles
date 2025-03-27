# Description: PDF related aliases for conversion, compression, encryption, and manipulation.

# Helper function - Validate PDF file
_validate_pdf_path_pdf() {
  if [ ! -f "$1" ]; then
    echo "Error: File \"$1\" does not exist or is not a regular file"
    return 1
  fi

  if [[ "${1##*.}" != "pdf" ]]; then
    echo "Error: File \"$1\" is not a PDF file"
    return 1
  fi

  return 0
}

# Helper function - Validate directory
_validate_directory_pdf() {
  if [ ! -d "$1" ]; then
    echo "Error: Directory \"$1\" does not exist"
    return 1
  fi

  return 0
}

# PDF to Image Conversion
alias pdf_to_images='(){
  if [ $# -eq 0 ]; then
    echo "Convert PDF to images (using pdf2pic).\nUsage:\n pdf_to_images <pdf_path>"
    return 1
  fi
  pdf_path=$1

  if ! _validate_pdf_path_pdf "$pdf_path"; then
    return 1
  fi

  echo "Converting PDF \"$pdf_path\" to images using pdf2pic..."
  if pdf2pic -i "$@"; then
    echo "Conversion complete"
  else
    echo "Error: Conversion failed, please check if pdf2pic is installed correctly"
    return 1
  fi
}'  # Convert PDF to images using pdf2pic

alias pdf_batch_to_images='(){
  if [ $# -eq 0 ]; then
    echo "Convert all PDF files in a directory to images (using pdf2pic).\nUsage:\n pdf_batch_to_images <directory_path>"
    return 1
  fi
  dir_path=$1

  if ! _validate_directory_pdf "$dir_path"; then
    return 1
  fi

  pdf_count=$(find "$dir_path" -type f -name "*.pdf" | wc -l | tr -d " ")

  if [ "$pdf_count" -eq 0 ]; then
    echo "Warning: No PDF files found in \"$dir_path\""
    return 0
  fi

  echo "Converting $pdf_count PDF files in \"$dir_path\" to images..."
  conversion_count=0

  for file in $(find "$dir_path" -type f -name "*.pdf"); do
    if pdf2pic -i "$file"; then
      conversion_count=$((conversion_count + 1))
      echo "Converted: $file"
    else
      echo "Error: Could not convert \"$file\""
    fi
  done

  echo "Batch conversion complete: Successfully converted $conversion_count/$pdf_count files"
}'  # Batch convert PDF files in a directory to images

alias pdf_to_jpg='(){
  if [ $# -eq 0 ]; then
    echo "Convert PDF to JPG images (using ImageMagick).\nUsage:\n pdf_to_jpg <pdf_path> [resolution=300]"
    return 1
  fi
  pdf_path=$1
  density=${2:-300}

  if ! _validate_pdf_path_pdf "$pdf_path"; then
    return 1
  fi

  if ! command -v magick &> /dev/null; then
    echo "Error: ImageMagick not found, please install it first"
    return 1
  fi

  output_prefix="$(basename "$pdf_path" .pdf)"
  echo "Converting PDF \"$pdf_path\" to JPG images with ${density}DPI resolution using ImageMagick..."

  if magick convert -density "$density" "$pdf_path" "${output_prefix}_%02d.jpg"; then
    echo "Conversion complete, exported as ${output_prefix}_%02d.jpg"
  else
    echo "Error: Conversion failed"
    return 1
  fi
}'  # Convert PDF to JPG images using ImageMagick

# PDF Compression
alias pdf_compress='(){
  if [ $# -eq 0 ]; then
    echo "Compress PDF file (using Ghostscript).\nUsage:\n pdf_compress <pdf_path> [compression_level:ebook|printer|screen]"
    echo "Compression level description:\n - screen: Screen quality (72dpi) - smallest file size\n - ebook: E-book quality (150dpi) - medium size\n - printer: Print quality (300dpi) - larger file size"
    return 1
  fi
  pdf_path=$1
  option=${2:-"screen"}

  if ! _validate_pdf_path_pdf "$pdf_path"; then
    return 1
  fi

  if ! [[ "$option" =~ ^(screen|ebook|printer)$ ]]; then
    echo "Error: Invalid compression level \"$option\", please use screen, ebook, or printer"
    return 1
  fi

  if ! command -v gs &> /dev/null; then
    echo "Error: Ghostscript not found, please install it first"
    return 1
  fi

  output_file="$(dirname "$pdf_path")/$(basename "$pdf_path" .pdf)_${option}.pdf"
  echo "Compressing PDF \"$pdf_path\" with \"$option\" level using Ghostscript, output to \"$output_file\"..."

  if gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dPDFSETTINGS="/${option}" -dNOPAUSE -dBATCH -sOutputFile="$output_file" "$pdf_path"; then
    if [ -f "$output_file" ]; then
      original_size=$(du -h "$pdf_path" | cut -f1)
      compressed_size=$(du -h "$output_file" | cut -f1)
      echo "Compression complete, saved to \"$output_file\""
      echo "Original size: $original_size, Compressed size: $compressed_size"
    else
      echo "Error: Output file not generated"
      return 1
    fi
  else
    echo "Error: Compression failed"
    return 1
  fi
}'  # Compress PDF file using Ghostscript

alias pdf_batch_compress='(){
  if [ $# -eq 0 ]; then
    echo "Batch compress PDF files in a directory (using Ghostscript).\nUsage:\n pdf_batch_compress <directory_path> [compression_level:ebook|printer|screen]"
    echo "Compression level description:\n - screen: Screen quality (72dpi) - smallest file size\n - ebook: E-book quality (150dpi) - medium size\n - printer: Print quality (300dpi) - larger file size"
    return 1
  fi
  dir_path=$1
  option=${2:-"screen"}

  if ! _validate_directory_pdf "$dir_path"; then
    return 1
  fi

  if ! [[ "$option" =~ ^(screen|ebook|printer)$ ]]; then
    echo "Error: Invalid compression level \"$option\", please use screen, ebook, or printer"
    return 1
  fi

  if ! command -v gs &> /dev/null; then
    echo "Error: Ghostscript not found, please install it first"
    return 1
  fi

  output_dir="$dir_path/compressed_${option}"
  mkdir -p "$output_dir"

  pdf_count=$(find "$dir_path" -type f -name "*.pdf" | wc -l | tr -d " ")

  if [ "$pdf_count" -eq 0 ]; then
    echo "Warning: No PDF files found in \"$dir_path\""
    rmdir "$output_dir" 2>/dev/null
    return 0
  fi

  echo "Compressing $pdf_count PDF files in \"$dir_path\" with \"$option\" level, output to \"$output_dir\"..."
  success_count=0

  for file in $(find "$dir_path" -type f -name "*.pdf" -not -path "$output_dir/*"); do
    output_file="$output_dir/$(basename "$file" .pdf)_${option}.pdf"

    if gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dPDFSETTINGS="/${option}" -dNOPAUSE -dBATCH -sOutputFile="$output_file" "$file"; then
      success_count=$((success_count + 1))
      original_size=$(du -h "$file" | cut -f1)
      compressed_size=$(du -h "$output_file" | cut -f1)
      echo "Compressed: \"$file\" (${original_size} → ${compressed_size})"
    else
      echo "Error: Could not compress \"$file\""
    fi
  done

  echo "Batch compression complete: Successfully compressed $success_count/$pdf_count files"
  echo "Compressed files are saved in: \"$output_dir\""
}'  # Batch compress PDF files in a directory

# PDF Encryption
alias pdf_encrypt='(){
  if [ $# -eq 0 ]; then
    echo "Encrypt PDF file (using Ghostscript).\nUsage:\n pdf_encrypt <source_pdf_path> [output_pdf_path] [owner_password] [user_password]"
    echo "Description:\n - If no output path is specified, a new file with a random suffix will be created in the same directory\n - If no password is specified, a random password will be automatically generated"
    return 1
  fi
  source_pdf_path=$1
  output_pdf_path="$2"
  owner_password="${3:-"$(openssl rand -base64 12)"}"
  user_password="${4:-"$(openssl rand -base64 12)"}"

  if ! _validate_pdf_path_pdf "$source_pdf_path"; then
    return 1
  fi

  if ! command -v gs &> /dev/null; then
    echo "Error: Ghostscript not found, please install it first"
    return 1
  fi

  if [ -z "$output_pdf_path" ]; then
    output_pdf_path="$(dirname "$source_pdf_path")/$(basename "$source_pdf_path" .pdf)_encrypted_$(openssl rand -hex 4).pdf"
  fi

  echo "Encrypting PDF \"$source_pdf_path\", output to \"$output_pdf_path\"..."

  if gs -q -dNOPAUSE -dBATCH -sDEVICE=pdfwrite -sOutputFile="$output_pdf_path" \
     -dPDFSETTINGS=/prepress -dPassThroughJPEGImages=true \
     -sOwnerPassword="$owner_password" -sUserPassword="$user_password" \
     -dEncryptionR=3 -dKeyLength=128 -dPermissions=-4 "$source_pdf_path"; then

    if [ -f "$output_pdf_path" ]; then
      echo "\nPDF encryption completed successfully.\n--------------------"
      echo "Source file: $source_pdf_path"
      echo "Output file: $output_pdf_path"
      echo "PDF Name: $(basename "$output_pdf_path")"
      echo "User password: $user_password"
      echo "Owner password: $owner_password"
      echo "\n\n$(basename "$output_pdf_path")"
      echo "Password: $user_password"
      echo "--------------------"
    else
      echo "Error: Output file not generated"
      return 1
    fi
  else
    echo "Error: Encryption failed"
    return 1
  fi
}'  # Add password protection to PDF using Ghostscript
