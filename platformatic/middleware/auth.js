import fp from 'fastify-plugin'

/**
 * Authentication middleware for API requests
 */
async function authMiddleware(fastify, options) {
  fastify.addHook('preHandler', async (request, reply) => {
    // Skip auth for health check and public endpoints
    const publicPaths = ['/health', '/metrics', '/api/content/featured']
    if (publicPaths.some(path => request.url.startsWith(path))) {
      return
    }

    // Check for API key in headers
    const apiKey = request.headers['x-api-key']
    if (apiKey && apiKey === process.env.API_KEY) {
      request.authenticated = true
      return
    }

    // Check for JWT token
    if (request.headers.authorization) {
      try {
        const token = request.headers.authorization.replace('Bearer ', '')
        const decoded = fastify.jwt.verify(token)
        request.user = decoded
        request.authenticated = true
        return
      } catch (err) {
        fastify.log.warn('Invalid JWT token:', err.message)
      }
    }

    // For now, allow unauthenticated access to read operations
    if (request.method === 'GET') {
      request.authenticated = false
      return
    }

    // Require authentication for write operations
    reply.code(401).send({ 
      error: 'Authentication required',
      message: 'Please provide a valid API key or JWT token'
    })
  })
}

export default fp(authMiddleware, {
  name: 'auth-middleware'
})

