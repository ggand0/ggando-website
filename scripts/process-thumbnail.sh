#!/bin/bash
# Process ChatGPT-generated images into blog thumbnails
# Usage: ./scripts/process-thumbnail.sh <input.png> <output_name>
# Example: ./scripts/process-thumbnail.sh ~/resources/my_image.png my_blog_post
#
# Outputs:
#   - <output_name>_1280.jpg (1280x720, mozjpeg 75%)
#   - <output_name>_640.jpg  (640x360, mozjpeg 75%)

set -e

if [ $# -lt 2 ]; then
    echo "Usage: $0 <input.png> <output_name>"
    echo "Example: $0 ~/resources/chatgpt_image.png my_blog_post"
    exit 1
fi

INPUT="$1"
OUTPUT_NAME="$2"
RESOURCES_DIR="/home/gota/ggando/v1_personal_website/resources"
QUALITY=75

if [ ! -f "$INPUT" ]; then
    echo "Error: Input file '$INPUT' not found"
    exit 1
fi

echo "Processing: $INPUT"

# Create temp files for intermediate PNGs
TEMP_1280=$(mktemp /tmp/thumb_1280_XXXXXX.png)
TEMP_640=$(mktemp /tmp/thumb_640_XXXXXX.png)

# Crop/resize to 1280x720
echo "Creating 1280x720 version..."
convert "$INPUT" \
    -resize 1280x720^ \
    -gravity center \
    -extent 1280x720 \
    "$TEMP_1280"

# Resize to 640x360
echo "Creating 640x360 thumbnail..."
convert "$INPUT" \
    -resize 640x360^ \
    -gravity center \
    -extent 640x360 \
    "$TEMP_640"

# Convert PNG to PPM (cjpeg can't read PNG directly), then to mozjpeg
echo "Converting to mozjpeg (quality: $QUALITY%)..."
convert "$TEMP_1280" ppm:- | cjpeg -quality $QUALITY > "${RESOURCES_DIR}/${OUTPUT_NAME}_1280.jpg"
convert "$TEMP_640" ppm:- | cjpeg -quality $QUALITY > "${RESOURCES_DIR}/${OUTPUT_NAME}_640.jpg"

# Cleanup temp files
rm -f "$TEMP_1280" "$TEMP_640"

echo ""
echo "Done! Created:"
echo "  ${RESOURCES_DIR}/${OUTPUT_NAME}_1280.jpg"
echo "  ${RESOURCES_DIR}/${OUTPUT_NAME}_640.jpg"
echo ""
echo "Upload to bunny.net:"
echo "  https://ggando.b-cdn.net/${OUTPUT_NAME}_1280.jpg"
echo "  https://ggando.b-cdn.net/${OUTPUT_NAME}_640.jpg"
