import axios from 'axios'

// Create axios instance with default configuration
const api = axios.create({
  baseURL: process.env.API_BASE_URL || 'http://localhost:3001',
  timeout: 10000,
  headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  },
})

// Request interceptor for adding auth tokens
api.interceptors.request.use(
  (config) => {
    // Add API key if available
    const apiKey = process.env.API_KEY || localStorage?.getItem('api_key')
    if (apiKey) {
      config.headers['X-API-Key'] = apiKey
    }

    // Add JWT token if available
    const token = localStorage?.getItem('auth_token')
    if (token) {
      config.headers['Authorization'] = `Bearer ${token}`
    }

    return config
  },
  (error) => {
    return Promise.reject(error)
  }
)

// Response interceptor for handling errors
api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      // Handle unauthorized access
      localStorage?.removeItem('auth_token')
      // Redirect to login page if needed
    }
    return Promise.reject(error)
  }
)

// Content API functions
export const contentApi = {
  // Get featured content
  getFeaturedContent: async () => {
    const response = await api.get('/api/content/featured')
    return response.data
  },

  // Get content by type and filters
  getContent: async (type = 'article', filters = {}) => {
    const params = new URLSearchParams()
    
    // Add filters to query params
    Object.entries(filters).forEach(([key, value]) => {
      if (value !== undefined && value !== null) {
        params.append(key, value.toString())
      }
    })

    const response = await api.get(`/jsonapi/node/${type}?${params.toString()}`)
    return response.data
  },

  // Get single content item
  getContentById: async (type, id) => {
    const response = await api.get(`/jsonapi/node/${type}/${id}`)
    return response.data
  },

  // Search content
  searchContent: async (query, type = 'article', limit = 10) => {
    const response = await api.get('/api/search', {
      params: { q: query, type, limit }
    })
    return response.data
  },

  // Get content in batch
  getBatchContent: async (ids, type = 'node') => {
    const response = await api.post('/api/content/batch', { ids, type })
    return response.data
  },

  // Get content preview (requires authentication)
  getContentPreview: async (type, id, revisionId = null) => {
    const params = revisionId ? { revision_id: revisionId } : {}
    const response = await api.get(`/api/preview/${type}/${id}`, { params })
    return response.data
  }
}

// Site API functions
export const siteApi = {
  // Get site configuration
  getConfig: async () => {
    const response = await api.get('/api/config')
    return response.data
  },

  // Get site statistics
  getStats: async () => {
    const response = await api.get('/api/stats')
    return response.data
  },

  // Get site metadata
  getMetadata: async () => {
    const response = await api.get('/api/drupal/api/site-metadata')
    return response.data
  },

  // Get menu data
  getMenu: async (menuName = 'main') => {
    const response = await api.get(`/api/drupal/api/menu/${menuName}`)
    return response.data
  }
}

// Cache API functions
export const cacheApi = {
  // Get cache statistics
  getStats: async () => {
    const response = await api.get('/api/cache/stats')
    return response.data
  },

  // Clear cache
  clearCache: async () => {
    const response = await api.delete('/api/cache')
    return response.data
  },

  // Invalidate specific cache entries
  invalidateCache: async (entityType, entityId, action = 'update') => {
    const response = await api.post('/api/webhook/cache-invalidate', {
      entity_type: entityType,
      entity_id: entityId,
      action
    })
    return response.data
  }
}

// Utility functions
export const apiUtils = {
  // Format Drupal date
  formatDate: (dateString) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'long',
      day: 'numeric'
    })
  },

  // Extract text from Drupal rich text field
  extractText: (richTextField) => {
    if (!richTextField || !richTextField.value) return ''
    
    // Remove HTML tags for plain text
    return richTextField.value.replace(/<[^>]*>/g, '')
  },

  // Get image URL from Drupal media field
  getImageUrl: (mediaField, imageStyle = 'large') => {
    if (!mediaField || !mediaField.data) return null
    
    const media = mediaField.data
    if (media.attributes && media.attributes.uri) {
      const baseUrl = process.env.DRUPAL_BASE_URL || 'http://localhost:8080'
      return `${baseUrl}${media.attributes.uri.url}`
    }
    
    return null
  },

  // Build JSON:API filter query
  buildFilter: (filters) => {
    const params = new URLSearchParams()
    
    Object.entries(filters).forEach(([field, config]) => {
      if (typeof config === 'string' || typeof config === 'number') {
        params.append(`filter[${field}]`, config.toString())
      } else if (typeof config === 'object') {
        const { value, operator = 'CONTAINS' } = config
        params.append(`filter[${field}][value]`, value.toString())
        params.append(`filter[${field}][operator]`, operator)
      }
    })
    
    return params.toString()
  },

  // Handle API errors
  handleError: (error) => {
    if (error.response) {
      // Server responded with error status
      const { status, data } = error.response
      return {
        status,
        message: data.message || data.error || 'An error occurred',
        details: data
      }
    } else if (error.request) {
      // Request was made but no response received
      return {
        status: 0,
        message: 'Network error - please check your connection',
        details: error.request
      }
    } else {
      // Something else happened
      return {
        status: -1,
        message: error.message || 'An unexpected error occurred',
        details: error
      }
    }
  }
}

// Health check function
export const healthCheck = async () => {
  try {
    const response = await api.get('/health')
    return { healthy: true, data: response.data }
  } catch (error) {
    return { healthy: false, error: apiUtils.handleError(error) }
  }
}

export default api

