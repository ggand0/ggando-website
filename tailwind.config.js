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
      //'sans': ['Lato', ...defaultTheme.fontFamily.sans],
      sans: ["Inter Variable", ...defaultTheme.fontFamily.sans],
    },
  },
  plugins: [
    require("tailwindcss"),
    require('@tailwindcss/typography'),
    require("autoprefixer")
  ],
}

