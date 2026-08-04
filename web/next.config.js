/** @type {import('next').NextConfig} */
const nextConfig = {
  images: { unoptimized: true },
  experimental: { serverComponentsExternalPackages: ['firebase-admin'] },
}
module.exports = nextConfig
