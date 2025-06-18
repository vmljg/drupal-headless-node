import { Php, Request } from '@platformatic/php-node'
import Fastify from 'fastify'
import cors from '@fastify/cors'
import helmet from '@fastify/helmet'
import rateLimit from '@fastify/rate-limit'
import jwt from '@fastify/jwt'
import redis from '@fastify/redis'
import { fileURLToPath } from 'url'
import { dirname, join } from 'path'
import dotenv from 'dotenv'
import NodeCache from 'node-cache'

// Load environment variables
dotenv.config()

const __filename = fileURLToPath(import.meta.url)
const __dirname = dirname(__filename)

// Initialize cache (TTL: 5 minutes)
const cache = new NodeCache({ stdTTL: 300 })

// Create Fastify instance
const fastify = Fastify({
  logger: {
    level: process.env.LOG_LEVEL || 'info',
    transport: {
      target: 'pino-pretty',
      options: {
        colorize: true,
        translateTime: 'HH:MM:ss Z',
        ignore: 'pid,hostname'
      }
    }
  }
})

// Initialize PHP instance
const php = new Php({
  docroot: join(__dirname, '../drupal/web'),
  argv: [],
  throwRequestErrors: false
})

// Register plugins
await fastify.register(helmet, {
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      scriptSrc: ["'self'"],
      imgSrc: ["'self'", "data:", "https:"],
      connectSrc: ["'self'"],
      fontSrc: ["'self'"],
      objectSrc: ["'none'"],
      mediaSrc: ["'self'"],
      frameSrc: ["'none'"]
    }
  }
})

await fastify.register(cors, {
  origin: [
    'http://localhost:3000',
    'http://localhost:8080',
    process.env.FRONTEND_URL,
    process.env.DRUPAL_URL
  ].filter(Boolean),
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS', 'PATCH'],
  allowedHeaders: [
    'Content-Type',
    'Authorization',
    'X-Requested-With',
    'Accept',
    'Origin',
    'X-API-Key',
    'X-CSRF-Token'
  ]
})

await fastify.register(rateLimit, {
  max: 1000,
  timeWindow: '1 minute',
  skipOnError: true
})

// JWT configuration
if (process.env.JWT_SECRET) {
  await fastify.register(jwt, {
    secret: process.env.JWT_SECRET
  })
}

// Redis configuration
if (process.env.REDIS_URL) {
  await fastify.register(redis, {
    url: process.env.REDIS_URL
  })
}

// Health check endpoint
fastify.get('/health', async (request, reply) => {
  return { 
    status: 'healthy', 
    timestamp: new Date().toISOString(),
    version: process.env.npm_package_version || '1.0.0'
  }
})

// Metrics endpoint
fastify.get('/metrics', async (request, reply) => {
  const memUsage = process.memoryUsage()
  return {
    memory: {
      rss: Math.round(memUsage.rss / 1024 / 1024) + ' MB',
      heapTotal: Math.round(memUsage.heapTotal / 1024 / 1024) + ' MB',
      heapUsed: Math.round(memUsage.heapUsed / 1024 / 1024) + ' MB',
      external: Math.round(memUsage.external / 1024 / 1024) + ' MB'
    },
    uptime: Math.round(process.uptime()) + ' seconds',
    cache: {
      keys: cache.keys().length,
      stats: cache.getStats()
    }
  }
})

// Proxy Drupal API requests through PHP-Node
fastify.all('/api/drupal/*', async (request, reply) => {
  const cacheKey = `drupal_${request.method}_${request.url}`
  
  // Check cache for GET requests
  if (request.method === 'GET') {
    const cached = cache.get(cacheKey)
    if (cached) {
      reply.header('X-Cache', 'HIT')
      return cached
    }
  }

  try {
    // Create PHP request
    const phpRequest = new Request({
      method: request.method,
      url: `http://localhost${request.url.replace('/api/drupal', '')}`,
      headers: request.headers,
      body: request.body ? Buffer.from(JSON.stringify(request.body)) : undefined
    })

    // Handle request through PHP
    const response = await php.handleRequest(phpRequest)
    
    // Parse response
    const responseBody = response.body.toString()
    let jsonResponse
    
    try {
      jsonResponse = JSON.parse(responseBody)
    } catch (e) {
      jsonResponse = { data: responseBody }
    }

    // Cache successful GET responses
    if (request.method === 'GET' && response.statusCode === 200) {
      cache.set(cacheKey, jsonResponse)
      reply.header('X-Cache', 'MISS')
    }

    reply.code(response.statusCode)
    return jsonResponse

  } catch (error) {
    fastify.log.error('PHP request failed:', error)
    reply.code(500)
    return { 
      error: 'Internal server error',
      message: error.message,
      timestamp: new Date().toISOString()
    }
  }
})

// Enhanced JSON:API proxy with caching and transformation
fastify.all('/jsonapi/*', async (request, reply) => {
  const cacheKey = `jsonapi_${request.method}_${request.url}`
  
  if (request.method === 'GET') {
    const cached = cache.get(cacheKey)
    if (cached) {
      reply.header('X-Cache', 'HIT')
      return cached
    }
  }

  try {
    const phpRequest = new Request({
      method: request.method,
      url: `http://localhost${request.url}`,
      headers: {
        ...request.headers,
        'Accept': 'application/vnd.api+json',
        'Content-Type': 'application/vnd.api+json'
      },
      body: request.body ? Buffer.from(JSON.stringify(request.body)) : undefined
    })

    const response = await php.handleRequest(phpRequest)
    const responseBody = response.body.toString()
    
    let jsonResponse
    try {
      jsonResponse = JSON.parse(responseBody)
      
      // Add metadata to JSON:API responses
      if (jsonResponse.data) {
        jsonResponse.meta = {
          ...jsonResponse.meta,
          generated_at: new Date().toISOString(),
          cached: false
        }
      }
    } catch (e) {
      jsonResponse = { error: 'Invalid JSON response', data: responseBody }
    }

    // Cache successful responses
    if (request.method === 'GET' && response.statusCode === 200) {
      cache.set(cacheKey, jsonResponse)
      reply.header('X-Cache', 'MISS')
    }

    reply.code(response.statusCode)
    return jsonResponse

  } catch (error) {
    fastify.log.error('JSON:API request failed:', error)
    reply.code(500)
    return { 
      error: 'JSON:API request failed',
      message: error.message 
    }
  }
})

// Custom aggregated content endpoint
fastify.get('/api/content/featured', async (request, reply) => {
  const cacheKey = 'featured_content'
  const cached = cache.get(cacheKey)
  
  if (cached) {
    reply.header('X-Cache', 'HIT')
    return cached
  }

  try {
    // Fetch featured articles
    const articlesRequest = new Request({
      method: 'GET',
      url: 'http://localhost/jsonapi/node/article?filter[promote]=1&sort=-created&page[limit]=5',
      headers: { 'Accept': 'application/vnd.api+json' }
    })

    const articlesResponse = await php.handleRequest(articlesRequest)
    const articles = JSON.parse(articlesResponse.body.toString())

    // Fetch featured pages
    const pagesRequest = new Request({
      method: 'GET',
      url: 'http://localhost/jsonapi/node/page?filter[promote]=1&sort=-created&page[limit]=3',
      headers: { 'Accept': 'application/vnd.api+json' }
    })

    const pagesResponse = await php.handleRequest(pagesRequest)
    const pages = JSON.parse(pagesResponse.body.toString())

    const featuredContent = {
      articles: articles.data || [],
      pages: pages.data || [],
      meta: {
        total_articles: articles.data?.length || 0,
        total_pages: pages.data?.length || 0,
        generated_at: new Date().toISOString()
      }
    }

    cache.set(cacheKey, featuredContent, 600) // Cache for 10 minutes
    reply.header('X-Cache', 'MISS')
    return featuredContent

  } catch (error) {
    fastify.log.error('Featured content request failed:', error)
    reply.code(500)
    return { error: 'Failed to fetch featured content' }
  }
})

// Search endpoint with caching
fastify.get('/api/search', async (request, reply) => {
  const { q, type, limit = 10 } = request.query
  
  if (!q) {
    reply.code(400)
    return { error: 'Search query is required' }
  }

  const cacheKey = `search_${q}_${type}_${limit}`
  const cached = cache.get(cacheKey)
  
  if (cached) {
    reply.header('X-Cache', 'HIT')
    return cached
  }

  try {
    let searchUrl = `/jsonapi/node/${type || 'article'}?filter[title][operator]=CONTAINS&filter[title][value]=${encodeURIComponent(q)}&page[limit]=${limit}`
    
    const searchRequest = new Request({
      method: 'GET',
      url: `http://localhost${searchUrl}`,
      headers: { 'Accept': 'application/vnd.api+json' }
    })

    const response = await php.handleRequest(searchRequest)
    const searchResults = JSON.parse(response.body.toString())

    const results = {
      query: q,
      type: type || 'article',
      results: searchResults.data || [],
      meta: {
        count: searchResults.data?.length || 0,
        generated_at: new Date().toISOString()
      }
    }

    cache.set(cacheKey, results, 300) // Cache for 5 minutes
    reply.header('X-Cache', 'MISS')
    return results

  } catch (error) {
    fastify.log.error('Search request failed:', error)
    reply.code(500)
    return { error: 'Search failed' }
  }
})

// Cache management endpoints
fastify.delete('/api/cache', async (request, reply) => {
  cache.flushAll()
  return { message: 'Cache cleared successfully' }
})

fastify.get('/api/cache/stats', async (request, reply) => {
  return {
    keys: cache.keys().length,
    stats: cache.getStats()
  }
})

// Error handler
fastify.setErrorHandler((error, request, reply) => {
  fastify.log.error(error)
  reply.code(500).send({ 
    error: 'Internal Server Error',
    message: error.message,
    timestamp: new Date().toISOString()
  })
})

// Start server
const start = async () => {
  try {
    const port = process.env.PORT || 3001
    const host = process.env.HOST || '0.0.0.0'
    
    await fastify.listen({ port, host })
    fastify.log.info(`Server running on http://${host}:${port}`)
    fastify.log.info(`Drupal docroot: ${join(__dirname, '../drupal/web')}`)
  } catch (err) {
    fastify.log.error(err)
    process.exit(1)
  }
}

start()

