# Setup and Installation Guide

This comprehensive guide will walk you through setting up the complete headless Drupal, Platformatic PHP-Node, and Next.js integration from scratch. The setup process involves configuring three main components that work together to create a modern, performant web application architecture.

## Prerequisites and System Requirements

Before beginning the installation process, ensure your development environment meets the following requirements. These prerequisites are essential for the proper functioning of all components in the stack.

### System Requirements

Your development machine should have adequate resources to run multiple services simultaneously. A minimum of 8GB RAM is recommended, with 16GB being optimal for development work. The system should have at least 10GB of free disk space to accommodate all dependencies, Docker images, and project files.

### Required Software

**Node.js and npm**: Install Node.js version 18 or higher from the official website. The installation includes npm (Node Package Manager) which is required for managing JavaScript dependencies. Verify the installation by running `node --version` and `npm --version` in your terminal.

**PHP and Extensions**: Install PHP 8.1 or higher with the following extensions: curl, xml, mbstring, zip, gd, mysql, and json. These extensions are crucial for Drupal's operation and the PHP-Node integration. On Ubuntu/Debian systems, you can install these using the package manager.

**Composer**: Install Composer, the PHP dependency manager, from getcomposer.org. Composer is essential for managing Drupal's PHP dependencies and modules.

**Docker and Docker Compose**: Install Docker Desktop or Docker Engine along with Docker Compose. This setup provides an isolated development environment and simplifies database management. Ensure Docker is running before proceeding with the setup.

**Git**: Install Git for version control and cloning repositories. This is necessary for downloading the project files and managing code changes during development.

### Platform-Specific Setup

For Ubuntu/Debian systems, install the required system libraries that @platformatic/php-node depends on. These libraries provide the necessary interfaces between the PHP runtime and the Node.js environment. Run the following command to install all required dependencies:

```bash
sudo apt-get update
sudo apt-get install -y libssl-dev libcurl4-openssl-dev libxml2-dev \
  libsqlite3-dev libonig-dev re2c php8.1-cli php8.1-fpm php8.1-mysql \
  php8.1-xml php8.1-curl php8.1-gd php8.1-mbstring php8.1-zip
```

For macOS systems using Homebrew, install the required libraries with:

```bash
brew install openssl@3 curl sqlite libxml2 oniguruma php composer
```

Windows users should use WSL2 (Windows Subsystem for Linux) for the best compatibility with the PHP-Node integration. Install Ubuntu through WSL2 and follow the Ubuntu setup instructions.

## Environment Setup

### Project Directory Structure

Create a dedicated directory for the project and navigate to it. This directory will contain all three components of the application stack. The recommended structure separates concerns while maintaining clear relationships between components.

```bash
mkdir drupal-platformatic-nextjs-example
cd drupal-platformatic-nextjs-example
```

### Environment Variables

Create environment variable files for each component to manage configuration settings. These files should not be committed to version control as they may contain sensitive information.

Create a `.env` file in the project root:

```bash
# Database Configuration
MYSQL_ROOT_PASSWORD=rootpassword
MYSQL_DATABASE=drupal
MYSQL_USER=drupal
MYSQL_PASSWORD=drupal

# Drupal Configuration
DRUPAL_DATABASE_HOST=localhost
DRUPAL_DATABASE_PORT=3306
DRUPAL_DATABASE_NAME=drupal
DRUPAL_DATABASE_USERNAME=drupal
DRUPAL_DATABASE_PASSWORD=drupal
DRUPAL_HASH_SALT=your-random-hash-salt-here
DRUPAL_ENV=development

# API Configuration
API_BASE_URL=http://localhost:3001
DRUPAL_BASE_URL=http://localhost:8080
FRONTEND_URL=http://localhost:3000

# Security Configuration
JWT_SECRET=your-jwt-secret-here
API_KEY=your-api-key-here

# Redis Configuration (optional)
REDIS_HOST=localhost
REDIS_PORT=6379
```

## Database Setup

### Docker-based Database

The recommended approach uses Docker to run MySQL and Redis services. This provides a consistent development environment across different platforms and simplifies database management.

Start the database services using Docker Compose:

```bash
docker-compose up -d mysql redis
```

This command starts MySQL and Redis containers in the background. The MySQL container is configured with the database credentials specified in the environment variables. Redis provides caching capabilities for improved performance.

### Manual Database Setup

If you prefer not to use Docker, you can install MySQL manually. Create a database named `drupal` and a user with appropriate permissions:

```sql
CREATE DATABASE drupal CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'drupal'@'localhost' IDENTIFIED BY 'drupal';
GRANT ALL PRIVILEGES ON drupal.* TO 'drupal'@'localhost';
FLUSH PRIVILEGES;
```

Ensure MySQL is configured to use the utf8mb4 character set for proper Unicode support, which is essential for international content and modern web applications.

## Drupal Backend Installation

### Composer Installation

Navigate to the Drupal directory and install PHP dependencies using Composer. This process downloads Drupal core and all required modules for the headless setup.

```bash
cd drupal
composer install
```

The installation process may take several minutes as Composer downloads and configures all dependencies. The composer.json file includes modules specifically chosen for headless Drupal functionality, including JSON:API, REST UI, CORS support, and authentication modules.

### Drupal Site Installation

Install Drupal using the command-line interface. This method provides more control over the installation process and ensures proper configuration for headless operation.

```bash
cd web
php core/scripts/drupal install standard \
  --db-url=mysql://drupal:drupal@localhost:3306/drupal \
  --site-name="Headless Drupal Site" \
  --account-name=admin \
  --account-pass=admin \
  --account-mail=admin@example.com
```

This command installs Drupal with the standard profile, which includes commonly used modules and content types. The installation creates the necessary database tables and configures the initial site settings.

### Module Configuration

After installation, enable the required modules for headless functionality:

```bash
drush en jsonapi jsonapi_extras rest restui cors serialization hal basic_auth -y
```

These modules provide the API endpoints and authentication mechanisms necessary for the headless architecture. The JSON:API module creates standardized endpoints for content access, while CORS support enables cross-origin requests from the frontend application.

### Content Type Setup

Create sample content types and content to demonstrate the integration. Access the Drupal admin interface at `http://localhost:8080/admin` and create:

1. **Article Content Type**: Configure with fields for title, body, author, tags, and featured image
2. **Page Content Type**: Configure with fields for title, body, and meta description
3. **Sample Content**: Create several articles and pages with varied content

Configure the JSON:API settings to expose these content types through the API endpoints. Navigate to Configuration > Web Services > JSON:API and ensure the content types are enabled for API access.

## Platformatic PHP-Node Setup

### Node.js Dependencies

Navigate to the Platformatic directory and install the Node.js dependencies:

```bash
cd ../platformatic
npm install
```

This installs @platformatic/php-node along with Fastify, caching libraries, and other dependencies required for the bridge layer. The installation process compiles native modules that enable PHP and Node.js communication.

### PHP-Node Configuration

The Platformatic configuration files define how PHP requests are handled and routed through the Node.js layer. The main configuration file specifies the Drupal document root, request handling options, and API routing rules.

Verify the PHP document root path in the configuration matches your Drupal installation. The path should point to the `drupal/web` directory where Drupal's index.php file is located.

### Testing the Integration

Start the Platformatic server to test the PHP-Node integration:

```bash
npm run dev
```

The server should start on port 3001 and display logs indicating successful PHP initialization. Test the integration by accessing the health check endpoint at `http://localhost:3001/health`.

Test Drupal API access through Platformatic by visiting `http://localhost:3001/jsonapi/node/article`. This should return JSON data for articles created in Drupal, demonstrating successful communication between the PHP backend and Node.js layer.

## Next.js Frontend Setup

### Frontend Dependencies

Navigate to the frontend directory and install the React and Next.js dependencies:

```bash
cd ../frontend
npm install
```

This installs Next.js, React, Tailwind CSS, and utility libraries for API communication and content rendering. The installation includes development tools for building and optimizing the frontend application.

### Development Server

Start the Next.js development server:

```bash
npm run dev
```

The frontend application should be accessible at `http://localhost:3000`. The development server includes hot reloading, which automatically updates the browser when code changes are made.

### API Integration Testing

Verify that the frontend can communicate with the Platformatic API by checking the browser's network tab for successful API requests. The home page should display featured content fetched from Drupal through the Platformatic bridge.

Test the articles listing page at `http://localhost:3000/articles` to ensure content is properly fetched and displayed. The page should show articles with proper formatting, pagination, and filtering capabilities.

## Production Deployment

### Environment Preparation

Production deployment requires additional configuration for security, performance, and reliability. Create production environment files with secure credentials and appropriate URLs for your production infrastructure.

### Database Configuration

For production, use a managed database service or a properly configured MySQL server with regular backups. Ensure the database connection uses SSL encryption and follows security best practices.

Configure Redis for production caching with appropriate memory limits and persistence settings. Redis significantly improves API response times by caching frequently accessed content.

### Drupal Production Setup

Configure Drupal for production by:

1. **Security Settings**: Update settings.php with production-specific security configurations
2. **Performance Optimization**: Enable CSS and JavaScript aggregation
3. **Caching**: Configure Drupal's internal caching and Redis integration
4. **File Permissions**: Set appropriate file and directory permissions for security

### Platformatic Deployment

Deploy the Platformatic service using a process manager like PM2 or containerize it using Docker. Ensure the service has access to the Drupal files and database.

Configure environment variables for production URLs, database connections, and security keys. Use a reverse proxy like Nginx to handle SSL termination and load balancing.

### Next.js Production Build

Build the Next.js application for production:

```bash
npm run build
npm start
```

The build process optimizes the application for performance, including code splitting, image optimization, and static generation where appropriate. Deploy the built application to a hosting service that supports Node.js applications.

### SSL and Security

Configure SSL certificates for all components to ensure secure communication. Use Let's Encrypt or a commercial certificate authority to obtain valid SSL certificates.

Implement security headers, rate limiting, and monitoring to protect the production deployment from common web vulnerabilities and attacks.

## Troubleshooting Common Issues

### PHP-Node Integration Problems

If the Platformatic server fails to start, verify that all required PHP extensions are installed and that the PHP binary is accessible. Check the server logs for specific error messages related to PHP initialization.

Ensure the Drupal document root path is correct and that the web server user has appropriate permissions to read the Drupal files.

### Database Connection Issues

Verify database credentials and network connectivity. Ensure the MySQL service is running and accessible from the application servers. Check firewall settings that might block database connections.

### Frontend API Communication

If the frontend cannot fetch data from the API, verify CORS configuration in the Platformatic server. Ensure the frontend URL is included in the allowed origins list.

Check network connectivity between the frontend and API servers, and verify that API endpoints are responding correctly using tools like curl or Postman.

### Performance Optimization

Monitor application performance using built-in metrics endpoints and logging. Optimize database queries, implement appropriate caching strategies, and use content delivery networks for static assets.

Configure monitoring and alerting to detect and respond to performance issues in production environments.

