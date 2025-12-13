# ggando-website

Personal website built with Zola and the Serene theme.

## Development

Run locally:
```bash
zola serve --interface 0.0.0.0
```

## Image Processing

Process ChatGPT-generated thumbnails (crop, resize, mozjpeg compress):
```bash
./scripts/process-thumbnail.sh ~/resources/chatgpt_image.png my_blog_post
```

This creates:
- `my_blog_post_1280.jpg` (1280x720, mozjpeg 75%)
- `my_blog_post_640.jpg` (640x360 thumbnail, mozjpeg 75%)

Then upload both to bunny.net storage.

### Manual crop/resize
```bash
convert input.png \
  -resize 1280x720^ \
  -gravity center \
  -extent 1280x720 \
  output.png
```
