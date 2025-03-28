# Description: PDF related aliases for conversion, compression, encryption, and manipulation.

# Helper Functions
_validate_pdf_path() {
  if [ ! -f "$1" ]; then
    echo "Error: File \"$1\" does not exist or is not a regular file" >&2
    return 1
  fi

  if [[ "${1##*.}" != "pdf" ]]; then
    echo "Error: File \"$1\" is not a PDF file" >&2
    return 1
  fi

  return 0
}

_validate_directory() {
  if [ ! -d "$1" ]; then
    echo "Error: Directory \"$1\" does not exist" >&2
    return 1
  fi

  return 0
}

# PDF Information
alias pdf-info='() {
  if [ $# -eq 0 ]; then
    echo "Display PDF file information.\nUsage:\n pdf-info <pdf_path>"
    return 1
  fi
  pdf_path=$1

  if ! _validate_pdf_path "$pdf_path"; then
    return 1
  fi

  if ! command -v pdfinfo &> /dev/null; then
    echo "Error: pdfinfo not found, please install poppler-utils first" >&2
    return 1
  fi

  echo "Fetching information for PDF \"$pdf_path\"..."
  if ! pdfinfo "$pdf_path"; then
    echo "Error: Could not get PDF information" >&2
    return 1
  fi
}' # Display PDF file information using pdfinfo

# PDF to Image Conversion
alias pdf-to-images='() {
  if [ $# -eq 0 ]; then
    echo "Convert PDF to images.\nUsage:\n pdf-to-images <pdf_path>"
    return 1
  fi
  pdf_path=$1

  if ! _validate_pdf_path "$pdf_path"; then
    return 1
  fi

  echo "Converting PDF \"$pdf_path\" to images using pdf2pic..."
  if pdf2pic -i "$@"; then
    echo "Conversion complete"
  else
    echo "Error: Conversion failed, please check if pdf2pic is installed correctly" >&2
    return 1
  fi
}' # Convert PDF to images using pdf2pic

alias pdf-batch-to-images='(){
  if [ $# -eq 0 ]; then
    echo "Convert all PDF files in a directory to images (using pdf2pic).\nUsage:\n pdf_batch_to_images <directory_path>"
    return 1
  fi
  dir_path=$1

  if ! _validate_directory "$dir_path"; then
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

alias pdf-to-jpg='(){
  if [ $# -eq 0 ]; then
    echo "Convert PDF to JPG images (using ImageMagick).\nUsage:\n pdf_to_jpg <pdf_path> [resolution=300]"
    return 1
  fi
  pdf_path=$1
  density=${2:-300}

  if ! _validate_pdf_path "$pdf_path"; then
    return 1
  fi

  if ! command -v magick &> /dev/null; then
    echo "Error: ImageMagick not found, please install it first" >&2
    return 1
  fi

  output_prefix="$(basename "$pdf_path" .pdf)"
  echo "Converting PDF \"$pdf_path\" to JPG images with ${density}DPI resolution using ImageMagick..."

  if magick convert -density "$density" "$pdf_path" "${output_prefix}_%02d.jpg"; then
    echo "Conversion complete, exported as ${output_prefix}_%02d.jpg"
  else
    echo "Error: Conversion failed" >&2
    return 1
  fi
}'  # Convert PDF to JPG images using ImageMagick

# PDF Compression
alias pdf-compress='(){
  if [ $# -eq 0 ]; then
    echo "Compress PDF file (using Ghostscript).\nUsage:\n pdf_compress <pdf_path> [compression_level:ebook|printer|screen]"
    echo "Compression level description:\n - screen: Screen quality (72dpi) - smallest file size\n - ebook: E-book quality (150dpi) - medium size\n - printer: Print quality (300dpi) - larger file size"
    return 1
  fi
  pdf_path=$1
  option=${2:-"screen"}

  if ! _validate_pdf_path "$pdf_path"; then
    return 1
  fi

  if ! [[ "$option" =~ ^(screen|ebook|printer)$ ]]; then
    echo "Error: Invalid compression level \"$option\", please use screen, ebook, or printer"
    return 1
  fi

  if ! command -v gs &> /dev/null; then
    echo "Error: Ghostscript not found, please install it first" >&2
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
    echo "Error: Compression failed" >&2
    return 1
  fi
}'  # Compress PDF file using Ghostscript

alias pdf-batch-compress='(){
  if [ $# -eq 0 ]; then
    echo "Batch compress PDF files in a directory (using Ghostscript).\nUsage:\n pdf_batch_compress <directory_path> [compression_level:ebook|printer|screen]"
    echo "Compression level description:\n - screen: Screen quality (72dpi) - smallest file size\n - ebook: E-book quality (150dpi) - medium size\n - printer: Print quality (300dpi) - larger file size"
    return 1
  fi
  dir_path=$1
  option=${2:-"screen"}

  if ! _validate_directory "$dir_path"; then
    return 1
  fi

  if ! [[ "$option" =~ ^(screen|ebook|printer)$ ]]; then
    echo "Error: Invalid compression level \"$option\", please use screen, ebook, or printer"
    return 1
  fi

  if ! command -v gs &> /dev/null; then
    echo "Error: Ghostscript not found, please install it first" >&2
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
alias pdf-encrypt='(){
  if [ $# -eq 0 ]; then
    echo "Encrypt PDF file (using Ghostscript).\nUsage:\n pdf_encrypt <source_pdf_path> [output_pdf_path] [owner_password] [user_password]"
    echo "Description:\n - If no output path is specified, a new file with a random suffix will be created in the same directory\n - If no password is specified, a random password will be automatically generated"
    return 1
  fi
  source_pdf_path=$1
  output_pdf_path="$2"
  owner_password="${3:-"$(openssl rand -base64 12)"}"
  user_password="${4:-"$(openssl rand -base64 12)"}"

  if ! _validate_pdf_path "$source_pdf_path"; then
    return 1
  fi

  if ! command -v gs &> /dev/null; then
    echo "Error: Ghostscript not found, please install it first" >&2
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
    echo "Error: Encryption failed" >&2
    return 1
  fi
}'  # Add password protection to PDF using Ghostscript

# PDF Merging
alias pdf-merge='() {
  if [ $# -lt 2 ]; then
    echo "Merge multiple PDF files into one.\nUsage:\n pdf-merge <output_pdf> <input_pdf1> <input_pdf2> [input_pdf3...]"
    return 1
  fi
  output_pdf=$1
  shift

  if ! command -v gs &> /dev/null; then
    echo "Error: Ghostscript not found, please install it first" >&2
    return 1
  fi

  for pdf in "$@"; do
    if ! _validate_pdf_path "$pdf"; then
      return 1
    fi
  done

  echo "Merging PDFs into \"$output_pdf\"..."
  if gs -dBATCH -dNOPAUSE -q -sDEVICE=pdfwrite -sOutputFile="$output_pdf" "$@"; then
    echo "Merge complete: \"$output_pdf\""
  else
    echo "Error: Merge failed" >&2
    return 1
  fi
}' # Merge multiple PDF files into one using Ghostscript

# PDF Split
alias pdf-split='() {
  if [ $# -lt 1 ]; then
    echo "Split PDF file into separate pages.\nUsage:\n pdf-split <pdf_path>"
    return 1
  fi
  pdf_path=$1

  if ! _validate_pdf_path "$pdf_path"; then
    return 1
  fi

  if ! command -v pdftk &> /dev/null; then
    echo "Error: pdftk not found, please install it first" >&2
    return 1
  fi

  output_pattern="$(basename "$pdf_path" .pdf)_page_%04d.pdf"
  echo "Splitting PDF \"$pdf_path\" into separate pages..."
  if pdftk "$pdf_path" burst output "$output_pattern"; then
    rm -f doc_data.txt
    echo "Split complete: Pages saved as ${output_pattern%_*}_page_*.pdf"
  else
    echo "Error: Split failed" >&2
    return 1
  fi
}' # Split PDF into separate pages using pdftk

# PDF Rotation
alias pdf-rotate='() {
  if [ $# -lt 2 ]; then
    echo "Rotate PDF pages.\nUsage:\n pdf-rotate <pdf_path> <degrees> [output_path]"
    echo "Degrees must be one of: 90, 180, 270"
    return 1
  fi
  pdf_path=$1
  degrees=$2
  output_path="${3:-${pdf_path%.*}_rotated.pdf}"

  if ! _validate_pdf_path "$pdf_path"; then
    return 1
  fi

  if ! [[ "$degrees" =~ ^(90|180|270)$ ]]; then
    echo "Error: Invalid rotation degree. Must be 90, 180, or 270" >&2
    return 1
  fi

  if ! command -v pdftk &> /dev/null; then
    echo "Error: pdftk not found, please install it first" >&2
    return 1
  fi

  echo "Rotating PDF \"$pdf_path\" by $degrees degrees..."
  if pdftk "$pdf_path" rotate allpages $degrees output "$output_path"; then
    echo "Rotation complete: \"$output_path\""
  else
    echo "Error: Rotation failed" >&2
    return 1
  fi
}' # Rotate all pages in a PDF file using pdftk

# PDF Extract Pages
alias pdf-extract='() {
  if [ $# -lt 3 ]; then
    echo "Extract pages from PDF file.\nUsage:\n pdf-extract <pdf_path> <start_page> <end_page> [output_path]"
    return 1
  fi
  pdf_path=$1
  start_page=$2
  end_page=$3
  output_path="${4:-${pdf_path%.*}_p${start_page}-${end_page}.pdf}"

  if ! _validate_pdf_path "$pdf_path"; then
    return 1
  fi

  if ! command -v pdftk &> /dev/null; then
    echo "Error: pdftk not found, please install it first" >&2
    return 1
  fi

  if ! [[ "$start_page" =~ ^[0-9]+$ ]] || ! [[ "$end_page" =~ ^[0-9]+$ ]]; then
    echo "Error: Page numbers must be positive integers" >&2
    return 1
  fi

  echo "Extracting pages $start_page-$end_page from \"$pdf_path\"..."
  if pdftk "$pdf_path" cat $start_page-$end_page output "$output_path"; then
    echo "Extraction complete: \"$output_path\""
  else
    echo "Error: Extraction failed" >&2
    return 1
  fi
}' # Extract page range from PDF file using pdftk

# PDF to Text
alias pdf-to-text='() {
  if [ $# -eq 0 ]; then
    echo "Extract text from PDF file.\nUsage:\n pdf-to-text <pdf_path> [output_path]"
    return 1
  fi
  pdf_path=$1
  output_path="${2:-${pdf_path%.*}.txt}"

  if ! _validate_pdf_path "$pdf_path"; then
    return 1
  fi

  if ! command -v pdftotext &> /dev/null; then
    echo "Error: pdftotext not found, please install poppler-utils first" >&2
    return 1
  fi

  echo "Extracting text from \"$pdf_path\"..."
  if pdftotext "$pdf_path" "$output_path"; then
    echo "Text extraction complete: \"$output_path\""
  else
    echo "Error: Text extraction failed" >&2
    return 1
  fi
}' # Extract text from PDF file using pdftotext

# Update help function
alias pdf-help='() {
  echo "PDF Manipulation Aliases Help\n"
  echo "Available commands:"
  echo "  pdf-info           - Display PDF file information"
  echo "  pdf-to-images      - Convert PDF to images"
  echo "  pdf-to-jpg         - Convert PDF to JPG images"
  echo "  pdf-compress       - Compress PDF file"
  echo "  pdf-batch-compress - Batch compress PDF files"
  echo "  pdf-encrypt        - Add password protection to PDF"
  echo "  pdf-merge         - Merge multiple PDF files"
  echo "  pdf-split         - Split PDF into separate pages"
  echo "  pdf-rotate        - Rotate all pages in PDF file"
  echo "  pdf-extract       - Extract page range from PDF"
  echo "  pdf-to-text       - Extract text from PDF file"
  echo "\nUse <command> without arguments to see detailed usage information."
}' # Show help information for PDF aliases
