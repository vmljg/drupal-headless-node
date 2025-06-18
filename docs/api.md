# API Documentation

This document provides comprehensive documentation for the API endpoints available in the headless Drupal, Platformatic PHP-Node, and Next.js integration. The API layer serves as the bridge between the Drupal content management system and the Next.js frontend, providing both standard Drupal JSON:API endpoints and custom enhanced endpoints through the Platformatic layer.

## API Architecture Overview

The API architecture consists of multiple layers that work together to provide a robust and performant content delivery system. The foundation layer is Drupal's native JSON:API implementation, which provides standardized endpoints for content access following the JSON:API specification. Above this sits the Platformatic PHP-Node bridge, which adds caching, custom endpoints, authentication, and request optimization.

The Platformatic layer intercepts and enhances requests before passing them to Drupal, allowing for advanced features like request aggregation, response transformation, and intelligent caching. This architecture provides the flexibility of Drupal's content management capabilities while delivering the performance characteristics expected in modern web applications.

## Base URLs and Endpoints

The API is accessible through multiple base URLs depending on the type of endpoint being accessed. The primary API base URL is `http://localhost:3001` in development, which serves as the entry point for all Platformatic-enhanced endpoints. Direct Drupal JSON:API endpoints are available at `http://localhost:3001/jsonapi`, while custom API endpoints are available at `http://localhost:3001/api`.

### Standard JSON:API Endpoints

The JSON:API endpoints follow the official JSON:API specification and provide standardized access to Drupal content entities. These endpoints support filtering, sorting, pagination, and relationship inclusion as defined by the JSON:API standard.

**Content Nodes**
- `GET /jsonapi/node/article` - Retrieve all article nodes
- `GET /jsonapi/node/article/{id}` - Retrieve a specific article by ID
- `GET /jsonapi/node/page` - Retrieve all page nodes
- `GET /jsonapi/node/page/{id}` - Retrieve a specific page by ID

**Users and Authentication**
- `GET /jsonapi/user/user` - Retrieve user information (requires authentication)
- `GET /jsonapi/user/user/{id}` - Retrieve specific user by ID

**Taxonomy Terms**
- `GET /jsonapi/taxonomy_term/tags` - Retrieve all tag terms
- `GET /jsonapi/taxonomy_term/tags/{id}` - Retrieve specific tag by ID

### Custom API Endpoints

The Platformatic layer provides custom endpoints that aggregate data, provide enhanced functionality, and optimize common use cases. These endpoints are designed to reduce the number of requests needed by frontend applications and provide data in formats optimized for specific use cases.

**Content Aggregation**
- `GET /api/content/featured` - Retrieve featured articles and pages
- `POST /api/content/batch` - Retrieve multiple content items by ID
- `GET /api/search` - Search content across multiple content types

**Site Information**
- `GET /api/config` - Retrieve site configuration and API information
- `GET /api/stats` - Retrieve site statistics and performance metrics
- `GET /api/drupal/api/site-metadata` - Retrieve Drupal site metadata

**Cache Management**
- `GET /api/cache/stats` - Retrieve cache statistics
- `DELETE /api/cache` - Clear all cached data
- `POST /api/webhook/cache-invalidate` - Invalidate specific cache entries

## Request and Response Formats

All API endpoints accept and return JSON data unless otherwise specified. Request headers should include `Content-Type: application/json` for POST and PUT requests. The API supports both `application/json` and `application/vnd.api+json` content types, with the latter being preferred for JSON:API endpoints.

### Standard JSON:API Response Format

JSON:API endpoints return data in the standardized JSON:API format, which includes a `data` object containing the primary resource data, optional `included` array for related resources, and `meta` object for additional information.

```json
{
  "data": [
    {
      "type": "node--article",
      "id": "uuid-string",
      "attributes": {
        "title": "Article Title",
        "body": {
          "value": "<p>Article content...</p>",
          "format": "basic_html"
        },
        "created": "2023-01-01T00:00:00+00:00",
        "status": true
      },
      "relationships": {
        "uid": {
          "data": {
            "type": "user--user",
            "id": "user-uuid"
          }
        }
      }
    }
  ],
  "meta": {
    "count": 1
  }
}
```

### Custom Endpoint Response Format

Custom endpoints return data in simplified formats optimized for frontend consumption, reducing the complexity of data parsing while maintaining essential information.

```json
{
  "articles": [
    {
      "id": "uuid-string",
      "title": "Article Title",
      "body": "Article content...",
      "created": "2023-01-01T00:00:00+00:00",
      "author": "Author Name"
    }
  ],
  "meta": {
    "total_articles": 5,
    "total_pages": 3,
    "generated_at": "2023-01-01T00:00:00+00:00"
  }
}
```

## Authentication and Authorization

The API supports multiple authentication methods to accommodate different use cases and security requirements. For public content access, no authentication is required. For administrative operations and private content access, authentication is mandatory.

### API Key Authentication

API key authentication provides a simple method for server-to-server communication and administrative access. Include the API key in the request headers:

```
X-API-Key: your-api-key-here
```

API keys should be kept secure and rotated regularly. They provide full access to the API and should only be used in secure server environments.

### JWT Token Authentication

JWT (JSON Web Token) authentication provides secure, stateless authentication for user-specific operations. Obtain a JWT token through the authentication endpoint and include it in subsequent requests:

```
Authorization: Bearer your-jwt-token-here
```

JWT tokens have expiration times and should be refreshed before expiry to maintain continuous access.

### OAuth2 Authentication

For more complex authentication scenarios, the API supports OAuth2 authentication through Drupal's Simple OAuth module. This provides secure authentication for third-party applications and mobile clients.

## Query Parameters and Filtering

The API supports extensive query parameters for filtering, sorting, and customizing responses. These parameters follow JSON:API conventions for standard endpoints and provide intuitive interfaces for custom endpoints.

### Filtering

Filter content based on field values using the `filter` parameter. Multiple filters can be combined to create complex queries:

```
GET /jsonapi/node/article?filter[status]=1&filter[promote]=1
```

Advanced filtering supports operators like `CONTAINS`, `STARTS_WITH`, `ENDS_WITH`, and comparison operators:

```
GET /jsonapi/node/article?filter[title][operator]=CONTAINS&filter[title][value]=technology
```

### Sorting

Sort results using the `sort` parameter. Prefix field names with `-` for descending order:

```
GET /jsonapi/node/article?sort=-created,title
```

### Pagination

Control result pagination using `page` parameters:

```
GET /jsonapi/node/article?page[limit]=10&page[offset]=20
```

### Including Relationships

Include related entities in the response using the `include` parameter:

```
GET /jsonapi/node/article?include=uid,field_tags
```

## Caching and Performance

The Platformatic layer implements intelligent caching to improve API performance and reduce load on the Drupal backend. Caching strategies vary based on content type, request frequency, and data volatility.

### Cache Headers

API responses include cache-related headers to indicate cache status:

- `X-Cache: HIT` - Response served from cache
- `X-Cache: MISS` - Response generated and cached
- `Cache-Control` - Browser caching directives

### Cache Invalidation

Cache entries are automatically invalidated when content is updated in Drupal. Manual cache invalidation is available through the cache management endpoints for administrative purposes.

### Performance Optimization

The API implements several performance optimizations:

- **Request Aggregation**: Multiple related requests are combined to reduce round trips
- **Response Compression**: Large responses are compressed to reduce bandwidth usage
- **Database Query Optimization**: Efficient database queries minimize response times
- **CDN Integration**: Static assets are served through content delivery networks

## Error Handling and Status Codes

The API uses standard HTTP status codes to indicate request success or failure. Error responses include detailed information to help developers diagnose and resolve issues.

### Success Status Codes

- `200 OK` - Request successful, data returned
- `201 Created` - Resource created successfully
- `204 No Content` - Request successful, no data returned

### Client Error Status Codes

- `400 Bad Request` - Invalid request format or parameters
- `401 Unauthorized` - Authentication required or invalid
- `403 Forbidden` - Access denied for authenticated user
- `404 Not Found` - Requested resource does not exist
- `422 Unprocessable Entity` - Request format valid but contains semantic errors

### Server Error Status Codes

- `500 Internal Server Error` - Unexpected server error
- `502 Bad Gateway` - Upstream service unavailable
- `503 Service Unavailable` - Service temporarily unavailable

### Error Response Format

Error responses include structured information to help identify and resolve issues:

```json
{
  "error": "Authentication required",
  "message": "Please provide a valid API key or JWT token",
  "status": 401,
  "timestamp": "2023-01-01T00:00:00+00:00",
  "details": {
    "code": "AUTH_REQUIRED",
    "documentation": "https://api-docs.example.com/authentication"
  }
}
```

## Rate Limiting and Quotas

The API implements rate limiting to ensure fair usage and protect against abuse. Rate limits vary based on authentication status and endpoint type.

### Rate Limit Headers

Responses include rate limit information in headers:

- `X-RateLimit-Limit` - Maximum requests per time window
- `X-RateLimit-Remaining` - Remaining requests in current window
- `X-RateLimit-Reset` - Time when rate limit window resets

### Rate Limit Policies

- **Anonymous Users**: 100 requests per minute
- **Authenticated Users**: 1000 requests per minute
- **API Key Users**: 5000 requests per minute

### Handling Rate Limits

When rate limits are exceeded, the API returns a `429 Too Many Requests` status code. Clients should implement exponential backoff and respect the rate limit headers to avoid being temporarily blocked.

## Webhooks and Real-time Updates

The API supports webhooks for real-time notifications of content changes. Webhooks enable frontend applications to update content immediately when changes occur in Drupal.

### Webhook Configuration

Configure webhook endpoints in the Drupal admin interface to receive notifications for specific content types and events. Webhook payloads include information about the changed content and the type of change.

### Supported Events

- `content.created` - New content published
- `content.updated` - Existing content modified
- `content.deleted` - Content removed
- `user.created` - New user registered
- `user.updated` - User profile modified

## SDK and Client Libraries

While the API can be accessed directly using HTTP requests, client libraries and SDKs are available to simplify integration and provide additional functionality.

### JavaScript/TypeScript SDK

A JavaScript SDK is available for frontend applications, providing typed interfaces and simplified methods for common operations:

```javascript
import { DrupalAPI } from '@drupal-platformatic/sdk'

const api = new DrupalAPI({
  baseURL: 'http://localhost:3001',
  apiKey: 'your-api-key'
})

const articles = await api.content.getArticles({
  limit: 10,
  sort: '-created'
})
```

### PHP SDK

A PHP SDK is available for server-side integrations and custom Drupal modules:

```php
use DrupalPlatformatic\SDK\Client;

$client = new Client([
    'base_url' => 'http://localhost:3001',
    'api_key' => 'your-api-key'
]);

$articles = $client->content()->getArticles([
    'limit' => 10,
    'sort' => '-created'
]);
```

## Testing and Development

The API includes comprehensive testing endpoints and development tools to facilitate integration and debugging.

### Health Check Endpoints

Monitor API health and status using dedicated health check endpoints:

- `GET /health` - Basic health check
- `GET /health/detailed` - Detailed system status
- `GET /metrics` - Performance metrics and statistics

### Development Tools

Development environments include additional tools for API exploration and testing:

- **API Explorer**: Interactive documentation and testing interface
- **Request Logging**: Detailed logging of API requests and responses
- **Performance Profiling**: Request timing and performance analysis
- **Mock Data**: Sample data for testing and development

This comprehensive API documentation provides the foundation for building robust integrations with the headless Drupal, Platformatic PHP-Node, and Next.js stack. The combination of standard JSON:API endpoints and custom enhanced endpoints provides flexibility while maintaining performance and ease of use.

