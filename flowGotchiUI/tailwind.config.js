/** @type {import('tailwindcss').Config} */
const defaultTheme = require('tailwindcss/defaultTheme');
module.exports = {
  content: [
    "./app/**/*.{js,ts,tsx}",
  ],
  theme: {
    extend: {
      fontFamily: {
        serif: ['var(--font-grandstander)', ...defaultTheme.fontFamily.serif],
        sans: ['var(--font-source-sans)', ...defaultTheme.fontFamily.sans],
      } 
    },
  },
  plugins: [],
};