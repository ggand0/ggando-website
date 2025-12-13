# ggando.com

Personal website built with [Zola](https://www.getzola.org/) and the [Serene](https://github.com/isunjn/serene) theme.

## Structure

```
content/
├── _index.md       # Homepage intro text
├── blog/           # Long-form articles
├── til/            # Today I Learned (short notes)
└── projects/       # Project showcase (data.toml)

templates/          # Zola templates (extends Serene theme)
static/
├── css/            # Tailwind CSS output
├── js/             # JS bundle (Parcel)
├── img/            # Images
└── icon/           # SVG icons
```

## Development

```bash
npm install          # Install dependencies
npm run build        # Build CSS/JS
zola serve           # Local dev server
```

## Frequently Used Commands

```bash
# Process thumbnail (crop to 16:9, mozjpeg compress)
./scripts/process-thumbnail.sh ~/resources/chatgpt_image.png my_blog_post
# Creates: my_blog_post_1280.jpg, my_blog_post_640.jpg → upload to bunny.net

# Manual crop/resize
convert input.png -resize 1280x720^ -gravity center -extent 1280x720 output.png

# Rebuild Tailwind CSS after adding new utility classes
npm run build:css
```
