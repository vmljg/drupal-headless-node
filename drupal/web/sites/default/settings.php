<?php

/**
 * @file
 * Drupal site-specific configuration file for headless setup.
 */

// Database configuration
$databases['default']['default'] = [
  'database' => getenv('DRUPAL_DATABASE_NAME') ?: 'drupal',
  'username' => getenv('DRUPAL_DATABASE_USERNAME') ?: 'drupal',
  'password' => getenv('DRUPAL_DATABASE_PASSWORD') ?: 'drupal',
  'prefix' => '',
  'host' => getenv('DRUPAL_DATABASE_HOST') ?: 'localhost',
  'port' => getenv('DRUPAL_DATABASE_PORT') ?: '3306',
  'namespace' => 'Drupal\\mysql\\Driver\\Database\\mysql',
  'driver' => 'mysql',
  'autoload' => 'core/modules/mysql/src/Driver/Database/mysql/',
];

// Configuration sync directory
$settings['config_sync_directory'] = '../config/sync';

// Hash salt for security
$settings['hash_salt'] = getenv('DRUPAL_HASH_SALT') ?: 'your-random-hash-salt-here-change-in-production';

// Trusted host patterns for security
$settings['trusted_host_patterns'] = [
  '^localhost$',
  '^127\.0\.0\.1$',
  '^.*\.local$',
  '^.*\.localhost$',
];

// File system paths
$settings['file_public_path'] = 'sites/default/files';
$settings['file_private_path'] = '../private';
$settings['file_temp_path'] = '/tmp';

// Redis configuration (if available)
if (getenv('REDIS_HOST')) {
  $settings['redis.connection']['interface'] = 'PhpRedis';
  $settings['redis.connection']['host'] = getenv('REDIS_HOST');
  $settings['redis.connection']['port'] = getenv('REDIS_PORT') ?: 6379;
  $settings['cache']['default'] = 'cache.backend.redis';
  $settings['cache']['bins']['bootstrap'] = 'cache.backend.chainedfast';
  $settings['cache']['bins']['discovery'] = 'cache.backend.chainedfast';
  $settings['cache']['bins']['config'] = 'cache.backend.chainedfast';
}

// CORS configuration for headless setup
$settings['cors_allowed_headers'] = [
  'x-csrf-token',
  'authorization',
  'content-type',
  'accept',
  'origin',
  'x-requested-with',
  'access-control-allow-origin',
  'x-api-key',
];

// JSON:API configuration
$settings['jsonapi_default_include_count'] = TRUE;

// Development settings
if (getenv('DRUPAL_ENV') === 'development') {
  // Disable CSS and JS aggregation
  $config['system.performance']['css']['preprocess'] = FALSE;
  $config['system.performance']['js']['preprocess'] = FALSE;
  
  // Enable verbose error reporting
  $config['system.logging']['error_level'] = 'verbose';
  
  // Disable render cache
  $settings['cache']['bins']['render'] = 'cache.backend.null';
  $settings['cache']['bins']['page'] = 'cache.backend.null';
  $settings['cache']['bins']['dynamic_page_cache'] = 'cache.backend.null';
  
  // Enable development services
  $settings['container_yamls'][] = DRUPAL_ROOT . '/sites/development.services.yml';
}

// Production settings
if (getenv('DRUPAL_ENV') === 'production') {
  // Enable CSS and JS aggregation
  $config['system.performance']['css']['preprocess'] = TRUE;
  $config['system.performance']['js']['preprocess'] = TRUE;
  
  // Set error reporting to errors only
  $config['system.logging']['error_level'] = 'hide';
  
  // Disable development modules
  $config['system.theme']['admin'] = 'claro';
  $config['system.theme']['default'] = 'olivero';
}

// API-specific configurations
$settings['api_base_url'] = getenv('API_BASE_URL') ?: 'http://localhost:3001';
$settings['frontend_url'] = getenv('FRONTEND_URL') ?: 'http://localhost:3000';

// JWT configuration for authentication
$settings['jwt_private_key'] = getenv('JWT_PRIVATE_KEY') ?: '../private/jwt_private.key';
$settings['jwt_public_key'] = getenv('JWT_PUBLIC_KEY') ?: '../private/jwt_public.key';
$settings['jwt_algorithm'] = 'RS256';

// Simple OAuth configuration
$settings['simple_oauth']['public_key'] = getenv('OAUTH_PUBLIC_KEY') ?: '../private/oauth_public.key';
$settings['simple_oauth']['private_key'] = getenv('OAUTH_PRIVATE_KEY') ?: '../private/oauth_private.key';

// Load local settings if available
if (file_exists($app_root . '/' . $site_path . '/settings.local.php')) {
  include $app_root . '/' . $site_path . '/settings.local.php';
}

