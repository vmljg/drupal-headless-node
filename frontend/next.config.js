/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  swcMinify: true,
  
  // Environment variables
  env: {
    API_BASE_URL: process.env.API_BASE_URL || 'http://localhost:3001',
    DRUPAL_BASE_URL: process.env.DRUPAL_BASE_URL || 'http://localhost:8080',
    SITE_NAME: process.env.SITE_NAME || 'Headless Drupal Site',
    SITE_URL: process.env.SITE_URL || 'http://localhost:3000'
  },

  // Image optimization
  images: {
    domains: [
      'localhost',
      '127.0.0.1',
      // Add your production domains here
    ],
    formats: ['image/webp', 'image/avif'],
    deviceSizes: [640, 750, 828, 1080, 1200, 1920, 2048, 3840],
    imageSizes: [16, 32, 48, 64, 96, 128, 256, 384],
  },

  // Rewrites for API proxy
  async rewrites() {
    return [
      {
        source: '/api/:path*',
        destination: `${process.env.API_BASE_URL || 'http://localhost:3001'}/api/:path*`,
      },
      {
        source: '/jsonapi/:path*',
        destination: `${process.env.API_BASE_URL || 'http://localhost:3001'}/jsonapi/:path*`,
      }
    ]
  },

  // Headers for security and performance
  async headers() {
    return [
      {
        source: '/(.*)',
        headers: [
          {
            key: 'X-Frame-Options',
            value: 'DENY'
          },
          {
            key: 'X-Content-Type-Options',
            value: 'nosniff'
          },
          {
            key: 'Referrer-Policy',
            value: 'strict-origin-when-cross-origin'
          },
          {
            key: 'Permissions-Policy',
            value: 'camera=(), microphone=(), geolocation=()'
          }
        ]
      }
    ]
  },

  // Experimental features
  experimental: {
    appDir: false, // Using pages directory for this example
    optimizeCss: true,
    scrollRestoration: true,
  },

  // Webpack configuration
  webpack: (config, { buildId, dev, isServer, defaultLoaders, webpack }) => {
    // Custom webpack configurations if needed
    return config
  },

  // Output configuration for static export if needed
  output: process.env.BUILD_STANDALONE === 'true' ? 'standalone' : undefined,
  
  // Trailing slash configuration
  trailingSlash: false,
  
  // Compression
  compress: true,
  
  // Power by header
  poweredByHeader: false,
}

module.exports = nextConfig

