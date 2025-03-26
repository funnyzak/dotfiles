# Description: Image processing aliases for resizing, conversion, effects, manipulation and batch operations.

# Image aliases - 图片处理相关的高效别名

# 基本图片处理
alias img_rs='() {
  if [ $# -eq 0 ]; then
    echo "Resize image to specified dimensions.\nUsage:\n img_rs <image_path> [size:200x] [quality:80]"
  else 
    img_rsize $1 ${2:-200x} ${3:-80}
  fi
}'  # Resize image to specified dimensions

# 批量图片尺寸调整
alias img_rs_dir='() {
  if [ $# -eq 0 ]; then
    echo "Batch resize images in directory.\nUsage:\n img_rs_dir <source_dir> <size:100x> <quality:100>"
  else
    mkdir -p $1/$2
    magick mogrify -resize $2 -quality ${3:-100} -path $1/$2 $1/*.(jpg|png|jpeg|bmp|heic|tif|tiff) 2>/dev/null && 
    echo "Resize complete, exported to $1/$2"
  fi
}'  # Batch resize images in directory

# 常用图片尺寸预设
alias img_rs_24x='() {
  if [ $# -eq 0 ]; then
    echo "Resize image(s) to 24px width.\nUsage:\n img_rs_24x <image_path> [more_files...]"
  else
    for i in $@; do 
      img_rsize $i 24x
    done
  fi
}'  # Resize image(s) to 24px width
alias img_rs_28x='() {
  if [ $# -eq 0 ]; then
    echo "Resize image(s) to 28px width.\nUsage:\n img_rs_28x <image_path> [more_files...]"
  else
    for i in $@; do 
      img_rsize $i 28x
    done
  fi
}'  # Resize image(s) to 28px width
alias img_rs_50x='() {
  if [ $# -eq 0 ]; then
    echo "Resize image(s) to 50px width.\nUsage:\n img_rs_50x <image_path> [more_files...]"
  else
    for i in $@; do 
      img_rsize $i 50x
    done
  fi
}'  # Resize image(s) to 50px width
alias img_rs_100x='() {
  if [ $# -eq 0 ]; then
    echo "Resize image(s) to 100px width.\nUsage:\n img_rs_100x <image_path> [more_files...]"
  else
    for i in $@; do 
      img_rsize $i 100x
    done
  fi
}'  # Resize image(s) to 100px width
alias img_rs_200x='() {
  if [ $# -eq 0 ]; then
    echo "Resize image(s) to 200px width.\nUsage:\n img_rs_200x <image_path> [more_files...]"
  else
    for i in $@; do 
      img_rsize $i 200x
    done
  fi
}'  # Resize image(s) to 200px width
alias img_rs_512x='() {
  if [ $# -eq 0 ]; then
    echo "Resize image(s) to 512px width.\nUsage:\n img_rs_512x <image_path> [more_files...]"
  else
    for i in $@; do 
      img_rsize $i 512x
    done
  fi
}'  # Resize image(s) to 512px width
alias img_rs_1024x='() {
  if [ $# -eq 0 ]; then
    echo "Resize image(s) to 1024px width.\nUsage:\n img_rs_1024x <image_path> [more_files...]"
  else
    for i in $@; do 
      img_rsize $i 1024x
    done
  fi
}'  # Resize image(s) to 1024px width

# 转换图片文件格式
alias rext_imgs='() {
  if [ $# -eq 0 ]; then
    echo "Convert image files to different format.\nUsage:\n rext_imgs <source_dir> <new_extension>"
  else
    for img in $1/*.(jpg|png|jpeg|bmp|heic|tif|tiff); do 
      if [ -f "$img" ]; then
        magick convert $img ${img%.*}.$2
        echo "Converted: $img -> ${img%.*}.$2"
      fi
    done
  fi
}'  # Convert image files to different format

# 图片特效处理
alias img_op='() {
  if [ $# -eq 0 ]; then
    echo "Adjust image opacity.\nUsage:\n img_op <source_image> <opacity_percent:50>"
  else
    target_path=$(echo $1 | sed -E "s/(.*)\.(.*)/\1_op$2.\2/")
    magick convert $1 -alpha set -channel A -evaluate set $2% $target_path && 
    echo "Opacity adjustment complete, exported to $target_path"
  fi
}'  # Adjust image opacity

alias img_rt='() {
  if [ $# -eq 0 ]; then
    echo "Rotate image.\nUsage:\n img_rt <source_image> <rotation_degrees:90>"
  else
    target_path=$(echo $1 | sed -E "s/(.*)\.(.*)/\1_rt$2.\2/")
    magick convert -rotate $2 -background none $1 $target_path && 
    echo "Rotation complete, exported to $target_path"
  fi
}'  # Rotate image

alias img_gb='() {
  if [ $# -eq 0 ]; then
    echo "Convert image to grayscale and binarize.\nUsage:\n img_gb <source_image>"
  else
    target_path=$(echo $1 | sed -E "s/(.*)\.(.*)/\1_gb.\2/")
    magick convert $1 -colorspace Gray -threshold 50% $target_path && 
    echo "Grayscale and binarization complete, exported to $target_path"
  fi
}'  # Convert image to grayscale and binarize

alias img_g='() {
  if [ $# -eq 0 ]; then
    echo "Convert image to grayscale.\nUsage:\n img_g <source_image>"
  else
    target_path=$(echo $1 | sed -E "s/(.*)\.(.*)/\1_g.\2/")
    magick convert $1 -colorspace Gray $target_path && 
    echo "Grayscale conversion complete, exported to $target_path"
  fi
}'  # Convert image to grayscale

# 文件夹批量处理
alias img_gb_dir='() {
  if [ $# -eq 0 ]; then
    echo "Convert directory of images to grayscale and binarize.\nUsage:\n img_gb_dir <source_dir>"
  else
    mkdir -p $1/gray_and_binarization
    magick mogrify -colorspace Gray -threshold 50% -path $1/gray_and_binarization $1/*.(jpg|png|jpeg|bmp|heic) 2>/dev/null && 
    echo "Grayscale and binarization complete, exported to $1/gray_and_binarization"
  fi
}'  # Convert directory of images to grayscale and binarize

alias img_g_dir='() {
  if [ $# -eq 0 ]; then
    echo "Convert directory of images to grayscale.\nUsage:\n img_g_dir <source_dir>"
  else
    mkdir -p $1/gray
    magick mogrify -colorspace Gray -path $1/gray $1/*.(jpg|png|jpeg|bmp|heic) 2>/dev/null && 
    echo "Grayscale conversion complete, exported to $1/gray"
  fi
}'  # Convert directory of images to grayscale

# 图片分割
alias img_cut_lr='() { 
  if [ $# -eq 0 ]; then
    echo "Split image into left and right halves.\nUsage:\n img_cut_lr <source_image>"
    return 1
  fi
  source_img_path="$1"
  base_name=${source_img_path%.*}
  ext=${source_img_path##*.}
  
  magick convert $source_img_path -crop 50%x100% +repage ${base_name}_%d.${ext} && 
  echo "Split image into left and right halves complete, exported to ${base_name}_0.${ext} and ${base_name}_1.${ext}"
}'  # Split image into left and right halves

alias img_cut_tb='() { 
  if [ $# -eq 0 ]; then
    echo "Split image into top and bottom halves.\nUsage:\n img_cut_tb <source_image>"
    return 1
  fi
  source_img_path="$1"
  base_name=${source_img_path%.*}
  ext=${source_img_path##*.}
  
  magick convert $source_img_path -crop 100%x50% +repage ${base_name}_%d.${ext} && 
  echo "Split image into top and bottom halves complete, exported to ${base_name}_0.${ext} and ${base_name}_1.${ext}"
}'  # Split image into top and bottom halves

alias img_cut_lr_dir='() { 
  if [ $# -eq 0 ]; then
    echo "Split directory of images into left and right halves.\nUsage:\n img_cut_lr_dir <source_dir>"
    return 1
  fi
  source_img_path="$1"
  mkdir -p ${source_img_path}/lr
  
  for img in ${source_img_path}/*.(jpg|png|jpeg|bmp|heic); do
    if [ -f "$img" ]; then
      base_name=$(basename ${img%.*})
      ext=${img##*.}
      magick convert "$img" -crop 50%x100% +repage "${source_img_path}/lr/${base_name}_%d.${ext}"
    fi
  done
  
  echo "Split directory of images into left and right halves complete, exported to ${source_img_path}/lr"
}'  # Split directory of images into left and right halves

alias img_cut_tb_dir='() { 
  if [ $# -eq 0 ]; then
    echo "Split directory of images into top and bottom halves.\nUsage:\n img_cut_tb_dir <source_dir>"
    return 1
  fi
  source_img_path="$1"
  mkdir -p ${source_img_path}/tb
  
  for img in ${source_img_path}/*.(jpg|png|jpeg|bmp|heic); do
    if [ -f "$img" ]; then
      base_name=$(basename ${img%.*})
      ext=${img##*.}
      magick convert "$img" -crop 100%x50% +repage "${source_img_path}/tb/${base_name}_%d.${ext}"
    fi
  done
  
  echo "Split directory of images into top and bottom halves complete, exported to ${source_img_path}/tb"
}'  # Split directory of images into top and bottom halves

# 图片合并
alias img2pdf='() {
  if [ $# -eq 0 ]; then
    echo "Merge directory of images into PDF.\nUsage:\n img2pdf <source_dir>"
  else
    folder_name=$(basename $1)
    magick convert $1/*.(jpg|png|jpeg|bmp|heic) $folder_name.pdf && 
    echo "Merged directory of images into PDF complete, exported to $folder_name.pdf"
  fi
}'  # Merge directory of images into PDF

alias simg2pdf='() {
  if [ $# -eq 0 ]; then
    echo "Convert single image to PDF.\nUsage:\n simg2pdf <source_image>"
  else
    magick convert $1 ${1%.*}.pdf && 
    echo "Single image to PDF conversion complete, exported to ${1%.*}.pdf"
  fi
}'  # Convert single image to PDF

# 添加水印
alias img_wm='() {
  if [ $# -lt 2 ]; then
    echo "Add watermark to image.\nUsage:\n img_wm <source_image> <watermark_image>"
    return 1
  fi
  
  output_path="${1%.*}_wm.${1##*.}"
  magick convert $1 $2 -gravity southeast -geometry +10+10 -composite $output_path && 
  echo "Watermark added, exported to $output_path"
}'  # Add watermark to image

alias img_wm_dir='() { 
  if [ $# -lt 2 ]; then
    echo "Batch add watermark to images.\nUsage:\n img_wm_dir <watermark_image> <source_dir> [opacity]"
    return 1
  fi
  echo "Batch adding watermark to images.\nUsage:\n img_wm_dir <watermark_image> <source_dir> [opacity]"
  batch_dir_watermark $@
}'  # Batch add watermark to images

# 批量图片优化
alias imgs_rs='() {
  if [ $# -eq 0 ]; then 
    echo "Batch optimize images by size.\nUsage: imgs_rs [directory:.] [width:1024] [quality:85]"
    return 1
  fi
  
  find $1 -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" -o -iname "*.gif" \) | while IFS= read -r file; do 
    magick "$file" -resize ${2:-1024}x -quality ${3:-85} "${file%.*}_${2:-1024}_${3:-85}.${file##*.}"
    echo "Processed: $file -> ${file%.*}_${2:-1024}_${3:-85}.${file##*.}"
  done
  
  echo "Batch image optimization complete"
}'  # Batch optimize images by size