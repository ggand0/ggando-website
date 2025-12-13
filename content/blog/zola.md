+++
title = "Switching to Zola from Nuxt.js"
date = 2025-01-23
draft = false

[extra]
thumb = "https://ggando.b-cdn.net/zola_cropped1.jpg"

[taxonomies]
categories = ["blog"]
tags = ["rust"]
+++

<img src="/img/zola.webp" alt="img0" width="500"/>

## Context
I initially created my previous website sometime with Nuxt.js in 2023. It served its purpose showing my bio and past projects, but I found it somewhat cumbersome for a static site like this. I also felt a mental barrier when it came to updating my website or writing new blog posts. In fact, I wrote my only blog post in February 2024 and never wrote anything since then. lol! As a result, I decided to migrate to a Rust-based static site generator called Zola, more compact framework that lets you focus on what I'd like to achieve with this website; documenting and sharing what I’ve learned on the internet.

## How it works
### Set up the project
I opted to fork the design from the [serene](https://github.com/isunjn/serene) and [tranquil](https://github.com/TeaDrinkingProgrammer/tranquil) themes. Once you chose a theme, setting up a Zola project was fairly easy; the serene theme provides a comprehensive [usage doc](https://github.com/isunjn/serene/blob/latest/USAGE.md) and I just needed to follow their instructions. Here's a summary of the steps::
1. `zola init <proj_name>`
2. `cd  <proj_name>`
3. `git submodule add -b latest https://github.com/isunjn/serene.git themes/serene`
4. Copy `themes/serene/config.example.toml` to the top level of your project, then rename it to `config.toml`
5. Edit config.toml to suit your needs
6. Set up subdirectories under content and create the required files:
- `content/posts/_index.md`
- `content/projects/_index.md`
- `content/projects/data.toml`

After running a local server by `zola serve`, you should be able to see the skelton website in your browser. A neat thing about Zola is that you can override the templates or asset files (js / css) used in the theme with your custom files. For example, if you put your custom home.html under ./templates , Zola will prioritize that file over the corresponding one in the theme.

### Style with tailwind css
From here, I wanted to improve the styles of serene using Tailwind CSS. Incorporating tailwind was straightforward:
1. Run `npm install <packages>` or create this `package.json` and then `npm install`
```json
{
  "dependencies": {
    "@tailwindcss/typography": "^0.5.16",
    "autoprefixer": "^10.4.20",
    "parcel": "^2.13.3",
    "postcss": "^8.5.1",
    "postcss-cli": "^11.0.0",
    "tailwindcss": "^3.4.17"
  },
  "scripts": {
    "build:css": "npx tailwindcss -i ./static/css/tailwind.css -o ./static/css/main.css --minify"
  }
}
```
The build:css  command is for building the css in deployment phase later.

 2. Generate tailwind.config.js
Run the command npx tailwindcss init . Here's my tailwind.config.js I generated with ChatGPT: 
```js
/** @type {import('tailwindcss').Config} */
const defaultTheme = require('tailwindcss/defaultTheme')

module.exports = {
  content: [
    "./templates/**/*.html", // Zola HTML templates
    "./content/**/*.md",     // Markdown files in Zola's content directory
  ],
  darkMode: 'class', // Enable class-based dark mode
  theme: {
    extend: {
      colors: {
        bg: 'var(--bg-color)',
        text: 'var(--text-color)',
        'primary': 'var(--primary-color)',
        'primary-pale': 'var(--primary-pale-color)',
        'blockquote': 'var(--blockquote-color)',
        'text-pale': 'var(--text-pale-color)',
        'inline-code-bg': 'var(--inline-code-bg-color)',
      },
      backgroundColor: {
        'dark-mode': 'var(--dark-mode-img-brightness)',
      },
    },
    fontFamily: {
      sans: ["Inter Variable", ...defaultTheme.fontFamily.sans],
    },
  },
  plugins: [
    require("tailwindcss"),
    require('@tailwindcss/typography'),
    require("autoprefixer")
  ],
}
```
3. Include Tailwind CSS in your project
I placed `tailwind.css` at `./static/css/tailwind.css`  and compiled it to `./static/css/main.css`  with this command: `npx tailwindcss -i ./static/css/tailwind.css -o ./static/css/main.css —watch`. This automatically rebuilds the css whenever changes are detected.
4. Override _base.html and include your css
As mentioned earlier, you can override theme templates with your own files. To include my custom css file, I created a new `_base.html` under `./templates` directory and added the following line:
```<link rel="stylesheet" href="/css/main.css">```
5. Style custom templates with Tailwind CSS
Referring to another tailwind based theme tranquil, I just threw all the relevant templates to ChatGPT 4o to apply tailwind styles in my custom templates..and it worked. It took about 4 days to generate and refine custom templates. As I usually don't do front-end things, it took a fair amount of effort to achieve the satisfying results, but it's amazing how we can use AI to speed up the process these days.

## Things I got stuck on
While the process was mostly straightforward, here are some challenges I faced:
- A long URL breaking the mobile layout
In my only existing post, a long URL wasn’t wrapping correctly within the parent element, making it look like there was a weird horizontal gap on the right side. I mistakenly thought it was a tailwind issue so I ended up wasting a few hours troubleshooting with ChatGPT.
- Tera not ignoring the commented-out blocks of html:
Zola uses a templating engine called Tera, and we can use its templating syntax to interact with the data in config.toml. I often comment out old code blocks when I make breaking changes. For example, in _base.html, I had this:
```html
<!--<body class="{% block page %}{% endblock page%}{% if config.extra.force_theme == "dark" %}dark{% endif %}">-->

<body class="{% block page %}{% endblock page %}bg-bg text-text dark:bg-dark-mode dark:text-white {% if config.extra.force_theme == 'dark' %}dark{% endif %}">
```
Interestingly this results in an error saying `Block page is duplicated`, because Tera doesn’t ignore commented-out HTML. I suspect this also contributed to another styling issue I had.

## Deployment
I use Vercel for deploying my personal website and I was able to deploy my Zola site without much trouble. After connecting your github repo, make sure to match the Zola version on Vercel with your local version. In my case it was 0.19.2. Addtionally, I needed to use `Node.js 20.x` to avoid the error `zola: /lib64/libm.so.6: version  GLIBC_2.29' not found (required by zola)`

## Takeaway
- Zola is easy, Zola works
- Compatible with Tailwind CSS
- Mind the Tera blocks
- Utilize ChatGPT 4o

All in all, I feel pretty good about the new website setup with Zola including how the website looks now. Highly recommended if you're hoping to do sometiing similar! If you're curious about the code I used for this website, you can check out the [repo](https://github.com/ggand0/ggando-website).
