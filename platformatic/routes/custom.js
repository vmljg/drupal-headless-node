/**
 * Custom API routes for enhanced functionality
 */
export default async function customRoutes(fastify, options) {
  
  // Site configuration endpoint
  fastify.get('/api/config', async (request, reply) => {
    return {
      site: {
        name: process.env.SITE_NAME || 'Headless Drupal Site',
        description: process.env.SITE_DESCRIPTION || 'A headless Drupal site with Next.js frontend',
        url: process.env.SITE_URL || 'http://localhost:3000',
        api_url: process.env.API_URL || 'http://localhost:3001'
      },
      api: {
        version: '1.0.0',
        endpoints: {
          drupal: '/api/drupal/*',
          jsonapi: '/jsonapi/*',
          search: '/api/search',
          featured: '/api/content/featured',
          config: '/api/config'
        }
      },
      features: {
        caching: true,
        authentication: !!process.env.JWT_SECRET,
        rate_limiting: true,
        cors: true
      }
    }
  })

  // Content statistics endpoint
  fastify.get('/api/stats', async (request, reply) => {
    try {
      // This would typically query your database
      // For demo purposes, we'll return mock data
      return {
        content: {
          total_nodes: 150,
          published_nodes: 142,
          articles: 89,
          pages: 53,
          users: 25
        },
        api: {
          requests_today: 1247,
          cache_hit_rate: 0.73,
          average_response_time: '145ms'
        },
        updated_at: new Date().toISOString()
      }
    } catch (error) {
      fastify.log.error('Stats request failed:', error)
      reply.code(500)
      return { error: 'Failed to fetch statistics' }
    }
  })

  // Batch content endpoint
  fastify.post('/api/content/batch', async (request, reply) => {
    const { ids, type = 'node' } = request.body

    if (!ids || !Array.isArray(ids)) {
      reply.code(400)
      return { error: 'IDs array is required' }
    }

    try {
      const results = []
      
      for (const id of ids) {
        const contentRequest = new Request({
          method: 'GET',
          url: `http://localhost/jsonapi/${type}/${id}`,
          headers: { 'Accept': 'application/vnd.api+json' }
        })

        try {
          const response = await php.handleRequest(contentRequest)
          const content = JSON.parse(response.body.toString())
          results.push(content)
        } catch (error) {
          results.push({ 
            id, 
            error: 'Content not found or inaccessible' 
          })
        }
      }

      return {
        requested: ids.length,
        returned: results.length,
        data: results
      }

    } catch (error) {
      fastify.log.error('Batch request failed:', error)
      reply.code(500)
      return { error: 'Batch request failed' }
    }
  })

  // Content preview endpoint (for authenticated users)
  fastify.get('/api/preview/:type/:id', async (request, reply) => {
    if (!request.authenticated) {
      reply.code(401)
      return { error: 'Authentication required for preview' }
    }

    const { type, id } = request.params
    const { revision_id } = request.query

    try {
      let url = `http://localhost/jsonapi/${type}/${id}`
      if (revision_id) {
        url += `?revision=${revision_id}`
      }

      const previewRequest = new Request({
        method: 'GET',
        url,
        headers: { 
          'Accept': 'application/vnd.api+json',
          'X-Preview-Mode': 'true'
        }
      })

      const response = await php.handleRequest(previewRequest)
      const content = JSON.parse(response.body.toString())

      return {
        ...content,
        meta: {
          ...content.meta,
          preview: true,
          revision_id: revision_id || 'latest'
        }
      }

    } catch (error) {
      fastify.log.error('Preview request failed:', error)
      reply.code(500)
      return { error: 'Preview request failed' }
    }
  })

  // Webhook endpoint for cache invalidation
  fastify.post('/api/webhook/cache-invalidate', async (request, reply) => {
    const { entity_type, entity_id, action } = request.body

    if (!entity_type || !entity_id) {
      reply.code(400)
      return { error: 'entity_type and entity_id are required' }
    }

    try {
      // Invalidate related cache entries
      const cacheKeys = cache.keys()
      const keysToDelete = cacheKeys.filter(key => 
        key.includes(entity_type) || key.includes(entity_id)
      )

      keysToDelete.forEach(key => cache.del(key))

      fastify.log.info(`Cache invalidated for ${entity_type}:${entity_id}, action: ${action}`)
      
      return {
        message: 'Cache invalidated successfully',
        invalidated_keys: keysToDelete.length,
        entity: { type: entity_type, id: entity_id },
        action
      }

    } catch (error) {
      fastify.log.error('Cache invalidation failed:', error)
      reply.code(500)
      return { error: 'Cache invalidation failed' }
    }
  })
}

