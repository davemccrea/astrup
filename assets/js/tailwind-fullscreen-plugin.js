const plugin = require('tailwindcss/plugin')

module.exports = plugin(function({ addVariant }) {
  addVariant('fullscreen', [
    '&:fullscreen',
    '&:-webkit-full-screen',
    '&:-moz-full-screen',
    '&:-ms-fullscreen'
  ])
})