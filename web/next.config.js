/** @type {import('next').NextConfig} */
const nextConfig = {
  images: { unoptimized: true },
  async rewrites() { return [{ source: "/dashboard", destination: "/dashboard" }] }
}
module.exports = nextConfig
