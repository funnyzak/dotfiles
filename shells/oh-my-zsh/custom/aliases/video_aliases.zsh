# Description: Video processing aliases for conversion, compression, merging, and format transformation using ffmpeg.

# Video file merging
alias merge_vdo='() { 
  if [ $# -eq 0 ]; then
    echo "Merge video files in a directory.\nUsage:\n merge_vdo <source_dir> <video_extension:mp4>"
    return 1
  fi
  vdo_folder="${1:-$(pwd)}"
  vdo_ext="${2:-mp4}"
  
  # Create a temporary file list
  temp_list=$(mktemp)
  for f in $(ls -1 ${vdo_folder}/*.${vdo_ext} | sort); do 
    echo "file '$f'" >> $temp_list
  done
  
  # Execute merge
  ffmpeg -f concat -safe 0 -i $temp_list -c copy ${vdo_folder}/merged_video.${vdo_ext} && 
  echo "Video merge complete, exported to ${vdo_folder}/merged_video.${vdo_ext}"
  
  # Clean up temporary file
  rm $temp_list
}'  # Merge multiple video files into one

# Video format conversion
alias vdo2mp4='() { 
  if [ $# -eq 0 ]; then
    echo "Convert video to MP4 format.\nUsage:\n vdo2mp4 <video_file_path>"
    return 1
  else 
    input_file=$1
    output_file=${input_file%.*}.mp4
    echo "Converting $input_file to MP4 format..."
    ffmpeg -i $input_file -c:v libx264 -crf 18 -preset slow -c:a aac -b:a 256k -ac 2 $output_file && 
    echo "Conversion complete, exported to $output_file"
  fi
}'  # Convert video to MP4 format with high quality

alias vdo2mp4_dir='() { 
  if [ $# -eq 0 ]; then
    echo "Convert videos in directory to MP4 format.\nUsage:\n vdo2mp4_dir <video_directory> <source_extension:mp4>"
    return 1
  else 
    vdo_folder="${1:-.}"
    vdo_ext="${2:-mp4}"
    mkdir -p ${vdo_folder}/mp4
    
    for file in $(find $vdo_folder -type f -name "*.${vdo_ext}" -maxdepth 1); do
      output_file="$vdo_folder/mp4/$(basename $file .${vdo_ext}).mp4"
      echo "Converting $file to $output_file..."
      ffmpeg -i $file -c:v libx264 -crf 18 -preset slow -c:a aac -b:a 256k -ac 2 $output_file
    done
    
    echo "Directory video conversion complete, exported to $vdo_folder/mp4"
  fi
}'  # Convert all videos in a directory to MP4 format

# Video to audio extraction
alias vdo2mp3='() { 
  if [ $# -eq 0 ]; then
    echo "Extract audio from video to MP3 format.\nUsage:\n vdo2mp3 <video_file_path>"
    return 1
  else 
    input_file=$1
    output_file=${input_file%.*}.mp3
    echo "Extracting audio from $input_file to MP3 format..."
    ffmpeg -i $input_file -vn -acodec libmp3lame -ab 128k -ar 44100 -y $output_file && 
    echo "Extraction complete, exported to $output_file"
  fi
}'  # Extract audio from video to MP3 format

alias vdo2mp3_dir='() { 
  if [ $# -eq 0 ]; then
    echo "Extract audio from videos in directory to MP3 format.\nUsage:\n vdo2mp3_dir <video_directory> <source_extension:mp4>"
    return 1
  else 
    vdo_folder="${1:-.}"
    vdo_ext="${2:-mp4}"
    mkdir -p ${vdo_folder}/mp3
    
    for file in $(find $vdo_folder -type f -name "*.${vdo_ext}" -maxdepth 1); do
      output_file="$vdo_folder/mp3/$(basename $file .${vdo_ext}).mp3"
      echo "Extracting audio from $file to $output_file..."
      ffmpeg -i $file -vn -acodec libmp3lame -ab 128k -ar 44100 -y $output_file
    done
    
    echo "Directory audio extraction complete, exported to $vdo_folder/mp3"
  fi
}'  # Extract audio from all videos in a directory to MP3 format

# Video compression
alias vdo_compress='() { 
  if [ $# -eq 0 ]; then
    echo "Compress video.\nUsage:\n vdo_compress <video_file_path> [quality:30]"
    return 1
  else 
    quality=${2:-30}
    input_file=$1
    output_file=${input_file%.*}_compressed.mp4
    echo "Compressing $input_file with quality factor $quality..."
    ffmpeg -i $input_file -c:v libx264 -tag:v avc1 -movflags faststart -crf $quality -preset superfast $output_file && 
    echo "Compression complete, exported to $output_file"
  fi
}'  # Compress video to reduce file size

alias vdo_compress_dir='() { 
  if [ $# -eq 0 ]; then
    echo "Compress videos in directory.\nUsage:\n vdo_compress_dir <video_directory> <source_extension:mp4> [quality:30]"
    return 1
  else 
    vdo_folder="${1:-.}"
    vdo_ext="${2:-mp4}"
    quality=${3:-30}
    mkdir -p ${vdo_folder}/compressed
    
    for file in $(find $vdo_folder -type f -name "*.${vdo_ext}" -maxdepth 1); do
      output_file="$vdo_folder/compressed/$(basename $file .${vdo_ext})_compressed.mp4"
      echo "Compressing $file to $output_file with quality factor $quality..."
      ffmpeg -i $file -c:v libx264 -tag:v avc1 -movflags faststart -crf $quality -preset superfast $output_file
    done
    
    echo "Directory video compression complete, exported to $vdo_folder/compressed"
  fi
}'  # Compress all videos in a directory

# Video resolution conversion
alias vdo2p320='() { 
  if [ $# -eq 0 ]; then
    echo "Convert video to 320p resolution.\nUsage:\n vdo2p320 <video_file_path>"
    return 1
  else 
    input_file=$1
    output_file=${input_file%.*}_320p.mp4
    echo "Converting $input_file to 320p resolution..."
    ffmpeg -i $input_file -vf "scale=-2:320" -c:a copy $output_file && 
    echo "Conversion complete, exported to $output_file"
  fi
}'  # Convert video to 320p resolution

alias vdo2p480='() { 
  if [ $# -eq 0 ]; then
    echo "Convert video to 480p resolution.\nUsage:\n vdo2p480 <video_file_path>"
    return 1
  else 
    input_file=$1
    output_file=${input_file%.*}_480p.mp4
    echo "Converting $input_file to 480p resolution..."
    ffmpeg -i $input_file -vf "scale=-2:480" -c:a copy $output_file && 
    echo "Conversion complete, exported to $output_file"
  fi
}'  # Convert video to 480p resolution

alias vdo2p720='() { 
  if [ $# -eq 0 ]; then
    echo "Convert video to 720p resolution.\nUsage:\n vdo2p720 <video_file_path>"
    return 1
  else 
    input_file=$1
    output_file=${input_file%.*}_720p.mp4
    echo "Converting $input_file to 720p resolution..."
    ffmpeg -i $input_file -vf "scale=-2:720" -c:a copy $output_file && 
    echo "Conversion complete, exported to $output_file"
  fi
}'  # Convert video to 720p resolution

alias vdo2p1080='() { 
  if [ $# -eq 0 ]; then
    echo "Convert video to 1080p resolution.\nUsage:\n vdo2p1080 <video_file_path>"
    return 1
  else 
    input_file=$1
    output_file=${input_file%.*}_1080p.mp4
    echo "Converting $input_file to 1080p resolution..."
    ffmpeg -i $input_file -vf "scale=-2:1080" -c:a copy $output_file && 
    echo "Conversion complete, exported to $output_file"
  fi
}'  # Convert video to 1080p resolution

# Batch video resolution conversion
alias vdo2p320_dir='() { 
  if [ $# -eq 0 ]; then
    echo "Convert videos in directory to 320p resolution.\nUsage:\n vdo2p320_dir <video_directory> <source_extension:mp4>"
    return 1
  else 
    vdo_folder="${1:-.}"
    vdo_ext="${2:-mp4}"
    mkdir -p ${vdo_folder}/320p
    
    for file in $(find $vdo_folder -type f -name "*.${vdo_ext}" -maxdepth 1); do
      output_file="$vdo_folder/320p/$(basename $file .${vdo_ext})_320p.mp4"
      echo "Converting $file to 320p resolution..."
      ffmpeg -i $file -vf "scale=-2:320" -c:a copy $output_file
    done
    
    echo "Directory video resolution conversion complete, exported to $vdo_folder/320p"
  fi
}'  # Convert all videos in a directory to 320p resolution

alias vdo2p480_dir='() { 
  if [ $# -eq 0 ]; then
    echo "Convert videos in directory to 480p resolution.\nUsage:\n vdo2p480_dir <video_directory> <source_extension:mp4>"
    return 1
  else 
    vdo_folder="${1:-.}"
    vdo_ext="${2:-mp4}"
    mkdir -p ${vdo_folder}/480p
    
    for file in $(find $vdo_folder -type f -name "*.${vdo_ext}" -maxdepth 1); do
      output_file="$vdo_folder/480p/$(basename $file .${vdo_ext})_480p.mp4"
      echo "Converting $file to 480p resolution..."
      ffmpeg -i $file -vf "scale=-2:480" -c:a copy $output_file
    done
    
    echo "Directory video resolution conversion complete, exported to $vdo_folder/480p"
  fi
}'  # Convert all videos in a directory to 480p resolution

alias vdo2p720_dir='() { 
  if [ $# -eq 0 ]; then
    echo "Convert videos in directory to 720p resolution.\nUsage:\n vdo2p720_dir <video_directory> <source_extension:mp4>"
    return 1
  else 
    vdo_folder="${1:-.}"
    vdo_ext="${2:-mp4}"
    mkdir -p ${vdo_folder}/720p
    
    for file in $(find $vdo_folder -type f -name "*.${vdo_ext}" -maxdepth 1); do
      output_file="$vdo_folder/720p/$(basename $file .${vdo_ext})_720p.mp4"
      echo "Converting $file to 720p resolution..."
      ffmpeg -i $file -vf "scale=-2:720" -c:a copy $output_file
    done
    
    echo "Directory video resolution conversion complete, exported to $vdo_folder/720p"
  fi
}'  # Convert all videos in a directory to 720p resolution

alias vdo2p1080_dir='() { 
  if [ $# -eq 0 ]; then
    echo "Convert videos in directory to 1080p resolution.\nUsage:\n vdo2p1080_dir <video_directory> <source_extension:mp4>"
    return 1
  else 
    vdo_folder="${1:-.}"
    vdo_ext="${2:-mp4}"
    mkdir -p ${vdo_folder}/1080p
    
    for file in $(find $vdo_folder -type f -name "*.${vdo_ext}" -maxdepth 1); do
      output_file="$vdo_folder/1080p/$(basename $file .${vdo_ext})_1080p.mp4"
      echo "Converting $file to 1080p resolution..."
      ffmpeg -i $file -vf "scale=-2:1080" -c:a copy $output_file
    done
    
    echo "Directory video resolution conversion complete, exported to $vdo_folder/1080p"
  fi
}'  # Convert all videos in a directory to 1080p resolution

# Mobile device optimization
alias vdo2m='() { 
  if [ $# -eq 0 ]; then
    echo "Optimize video for mobile devices.\nUsage:\n vdo2m <video_file_path>"
    return 1
  else 
    input_file=$1
    temp_file=${input_file%.*}_320p.mp4
    output_file=${input_file%.*}_mobile.mp4
    
    echo "Converting $input_file to mobile-optimized format..."
    # First convert to 320p
    ffmpeg -i $input_file -vf "scale=-2:320" -c:a copy $temp_file
    # Then compress
    ffmpeg -i $temp_file -c:v libx264 -tag:v avc1 -movflags faststart -crf 28 -preset superfast $output_file && 
    echo "Mobile optimization complete, exported to $output_file"
    # Optional: delete intermediate file
    rm $temp_file
  fi
}'  # Optimize video for mobile devices

# Audio conversion
alias aud2mp3='() { 
  if [ $# -eq 0 ]; then
    echo "Convert audio to MP3 format.\nUsage:\n aud2mp3 <audio_file_path> [bitrate:128k]"
    return 1
  else 
    input_file=$1
    bitrate=${2:-128k}
    output_file=${input_file%.*}.mp3
    
    echo "Converting $input_file to MP3 format with bitrate $bitrate..."
    ffmpeg -i $input_file -c:a libmp3lame -b:a $bitrate $output_file && 
    echo "Conversion complete, exported to $output_file"
  fi
}'  # Convert audio to MP3 format

alias aud2mp3_dir='() { 
  if [ $# -eq 0 ]; then
    echo "Convert audio files in directory to MP3 format.\nUsage:\n aud2mp3_dir <audio_directory> <source_extension:wav> [bitrate:128k]"
    return 1
  else 
    aud_folder="${1:-.}"
    aud_ext="${2:-wav}"
    bitrate=${3:-128k}
    mkdir -p ${aud_folder}/mp3
    
    for file in $(find $aud_folder -type f -name "*.${aud_ext}" -maxdepth 1); do
      output_file="$aud_folder/mp3/$(basename $file .${aud_ext}).mp3"
      echo "Converting $file to $output_file with bitrate $bitrate..."
      ffmpeg -i $file -c:a libmp3lame -b:a $bitrate $output_file
    done
    
    echo "Directory audio conversion complete, exported to $aud_folder/mp3"
  fi
}'  # Convert all audio files in a directory to MP3 format

# M3U8 stream processing
alias m3u8_2mp4='() { 
  if [ $# -eq 0 ]; then
    echo "Convert M3U8 stream to MP4 video.\nUsage:\n m3u8_2mp4 <m3u8_url> [output_filename]"
    return 1
  else 
    output=${2:-"output_$(date +%Y%m%d%H%M%S).mp4"}
    echo "Converting M3U8 stream $1 to MP4 format..."
    ffmpeg -i "$1" -c copy "${output}" && 
    echo "Conversion complete, exported to ${output}"
  fi
}'  # Convert M3U8 stream to MP4 video

# YouTube downloads
alias ytdl='youtube-dl -f "bestvideo[ext=mp4]+bestaudio[ext=m4a]/bestvideo+bestaudio" --merge-output-format mp4'  # Download YouTube video in best quality
alias ytdl_all='youtube-dl -f "bestvideo[ext=mp4]+bestaudio[ext=m4a]/bestvideo+bestaudio" --merge-output-format mp4 --all-subs --embed-subs --embed-thumbnail -o "%(title)s.%(ext)s"'  # Download YouTube video with all subtitles and thumbnail

alias ytdlmp4_720='youtube-dl -f "bestvideo[height<=720][ext=mp4]+bestaudio[ext=m4a]/bestvideo[height<=720]+bestaudio" --merge-output-format mp4'  # Download YouTube video in 720p quality
alias ytdlmp4_1920='youtube-dl -f "bestvideo[height<=1920][ext=mp4]+bestaudio[ext=m4a]/bestvideo[height<=1920]+bestaudio" --merge-output-format mp4'  # Download YouTube video in 1080p quality

alias ytdlmp3='youtube-dl -f bestaudio --extract-audio --audio-format mp3'  # Download YouTube audio in MP3 format
alias ytdlmp3_128='youtube-dl -f bestaudio --extract-audio --audio-format mp3 --audio-quality 128K'  # Download YouTube audio in MP3 format at 128Kbps
alias ytdlmp3_320='youtube-dl -f bestaudio --extract-audio --audio-format mp3 --audio-quality 320K'  # Download YouTube audio in MP3 format at 320Kbps