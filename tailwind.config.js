/** @type {import('tailwindcss').Config} */
const defaultTheme = require('tailwindcss/defaultTheme')

module.exports = {
  content: [
    "./templates/**/*.html", // Zola HTML templates
    "./content/**/*.md",     // Markdown files in Zola's content directory
  ],
  theme: {
    extend: {},
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

