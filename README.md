# Headless Drupal with @platformatic/php-node and Next.js Integration Example

This comprehensive example demonstrates how to integrate a headless Drupal backend with a Next.js frontend using @platformatic/php-node as the bridge layer. This architecture combines the content management capabilities of Drupal with the performance benefits of a decoupled frontend, all while leveraging the power of running PHP and Node.js in the same process.

## Architecture Overview

The integration consists of three main components working together:

**Drupal Backend (PHP)**: Serves as the content management system and API provider through JSON:API and REST endpoints. Drupal handles content creation, user management, and provides structured data through its robust API system.

**Platformatic PHP-Node Bridge**: Acts as the middleware layer that allows PHP (Drupal) and Node.js to communicate within the same process. This eliminates network overhead and provides seamless integration between the PHP backend and Node.js services.

**Next.js Frontend**: Provides the user-facing interface with server-side rendering, static generation, and modern React-based user experience. The frontend consumes data from Drupal through the Platformatic bridge.

## Key Benefits

This architecture provides several significant advantages over traditional approaches. The elimination of network calls between PHP and Node.js reduces latency and improves performance. Running both environments in the same process allows for shared memory and more efficient resource utilization. The setup maintains the flexibility of headless architecture while providing tighter integration between components.

The approach also enables advanced features like request rewriting, custom middleware, and seamless authentication flow between the PHP backend and Node.js frontend services. This is particularly valuable for complex applications that need to leverage both PHP's mature ecosystem and Node.js's modern development patterns.

## Project Structure

```
drupal-platformatic-nextjs-example/
├── README.md                          # This file
├── docker-compose.yml                 # Docker setup for development
├── drupal/                           # Drupal backend
│   ├── web/                         # Drupal web root
│   ├── composer.json                # PHP dependencies
│   ├── config/                      # Drupal configuration
│   └── modules/                     # Custom modules
├── platformatic/                     # Platformatic configuration
│   ├── platformatic.json           # Main configuration
│   ├── server.js                   # Node.js server setup
│   ├── routes/                     # Custom API routes
│   └── middleware/                 # Custom middleware
├── frontend/                        # Next.js application
│   ├── package.json                # Node.js dependencies
│   ├── next.config.js              # Next.js configuration
│   ├── pages/                      # Next.js pages
│   ├── components/                 # React components
│   ├── lib/                        # Utility functions
│   └── styles/                     # CSS styles
└── docs/                           # Additional documentation
    ├── setup.md                    # Setup instructions
    ├── api.md                      # API documentation
    └── deployment.md               # Deployment guide
```

## Prerequisites

Before setting up this integration, ensure you have the following installed on your system:

- Node.js 18+ with npm or yarn
- PHP 8.1+ with required extensions
- Composer for PHP dependency management
- Docker and Docker Compose (recommended for development)
- Git for version control

For Ubuntu/Debian systems, install the required PHP libraries:

```bash
sudo apt-get update
sudo apt-get install -y libssl-dev libcurl4-openssl-dev libxml2-dev \
  libsqlite3-dev libonig-dev re2c php8.1-cli php8.1-fpm php8.1-mysql \
  php8.1-xml php8.1-curl php8.1-gd php8.1-mbstring php8.1-zip
```

For macOS with Homebrew:

```bash
brew install openssl@3 curl sqlite libxml2 oniguruma php composer
```

## Quick Start

### Automated Setup (Recommended)

1. Clone this repository:
```bash
git clone https://github.com/jasonjgardner/drupal-platformatic-nextjs-example.git
cd drupal-platformatic-nextjs-example
```

2. Check system requirements:
```bash
./scripts/check-requirements.sh
```

3. Run automated setup:
```bash
./scripts/setup.sh
```

4. Start development environment:
```bash
./scripts/dev.sh
```

### Platform-Specific Setup

**macOS (with Homebrew):**
```bash
./scripts/setup-macos.sh
./start-dev-macos.sh  # Starts and opens in browser
```

**Windows:**
```cmd
scripts\setup-windows.bat
start-dev.bat  # After setup completes
```

**Manual Setup:**
See `docs/setup.md` for detailed manual installation instructions.

### Available Services
- Drupal Admin: http://localhost:8080 (admin/admin)
- Platformatic API: http://localhost:3001
- Next.js Frontend: http://localhost:3000
- MailHog: http://localhost:8025

### Useful Commands
```bash
./scripts/logs.sh          # View all logs
./scripts/restart.sh       # Restart all services
./scripts/stop.sh          # Stop all services
```


