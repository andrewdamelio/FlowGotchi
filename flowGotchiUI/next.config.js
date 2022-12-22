/** @type {import('next').NextConfig} */
const nextConfig = {
  images: {
    domains: ['i.imgur.com'],
  },
  experimental: {
    appDir: true,
  },
}

module.exports = nextConfig
