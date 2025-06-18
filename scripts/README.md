# Automation Scripts

This directory contains automation scripts to streamline the setup and development process for the Drupal + Platformatic + Next.js integration.

## Available Scripts

### Setup Scripts

**`setup.sh`** - Main setup script (Linux/macOS)
- Checks system requirements
- Sets up environment variables
- Installs all dependencies
- Configures all three components
- Creates sample content
- Verifies installation

**`setup-macos.sh`** - macOS-specific setup
- Installs dependencies via Homebrew
- Optimizes for Apple Silicon (M1/M2)
- Creates macOS-specific helper scripts
- Integrates with macOS system features

**`setup-windows.bat`** - Windows setup script
- Checks Windows-specific requirements
- Creates batch files for development
- Provides Windows-specific instructions

### Development Scripts

**`dev.sh`** - Start development environment
- Starts all services in correct order
- Monitors service health
- Provides unified development interface
- Handles graceful shutdown

**`stop.sh`** - Stop all services
- Stops all running services
- Cleans up process files
- Handles Docker containers

**`restart.sh`** - Restart services
- Restart individual or all services
- Useful for applying configuration changes
- Maintains service dependencies

### Utility Scripts

**`check-requirements.sh`** - System requirements checker
- Validates all dependencies
- Checks version requirements
- Provides installation guidance
- Tests system resources

**`logs.sh`** - Log viewer and monitor
- View logs from all services
- Follow logs in real-time
- Filter by service
- Show service status

## Quick Start

### Linux/macOS
```bash
# Check requirements
./scripts/check-requirements.sh

# Run setup
./scripts/setup.sh

# Start development environment
./scripts/dev.sh
```

### Windows
```cmd
REM Run setup
scripts\setup-windows.bat

REM Start development (after setup)
start-dev.bat
```

### macOS (with Homebrew)
```bash
# macOS-optimized setup
./scripts/setup-macos.sh

# Start with browser integration
./start-dev-macos.sh
```

## Script Features

### Automated Dependency Management
- Checks for required software
- Validates version requirements
- Provides installation guidance
- Platform-specific optimizations

### Environment Configuration
- Generates secure environment variables
- Creates platform-specific configurations
- Sets up development databases
- Configures API endpoints

### Service Management
- Starts services in correct order
- Monitors service health
- Handles dependencies
- Provides graceful shutdown

### Development Tools
- Real-time log monitoring
- Service status checking
- Easy restart capabilities
- Error diagnostics

## Usage Examples

### Check System Requirements
```bash
./scripts/check-requirements.sh
```
Validates that all required software is installed and meets version requirements.

### Complete Setup
```bash
./scripts/setup.sh
```
Performs complete setup including:
- Environment configuration
- Database setup
- Dependency installation
- Service configuration
- Sample content creation

### Start Development Environment
```bash
./scripts/dev.sh
```
Starts all services and provides a unified development interface with:
- Service status monitoring
- Automatic browser opening
- Log aggregation
- Health checks

### View Logs
```bash
# View all logs
./scripts/logs.sh

# Follow specific service logs
./scripts/logs.sh -f platformatic

# Show last 100 lines
./scripts/logs.sh -n 100 frontend
```

### Restart Services
```bash
# Restart all services
./scripts/restart.sh

# Restart specific service
./scripts/restart.sh platformatic
```

## Platform-Specific Features

### macOS
- Homebrew integration for dependency management
- Apple Silicon (M1/M2) optimizations
- Automatic browser opening
- Xcode Command Line Tools setup
- Native compilation optimizations

### Windows
- Batch file creation for easy development
- Windows-specific path handling
- PowerShell compatibility
- Visual Studio Code integration
- Windows service management

### Linux
- Package manager detection
- Distribution-specific instructions
- Docker integration
- Systemd service support
- Performance optimizations

## Troubleshooting

### Common Issues

**Permission Denied**
```bash
chmod +x scripts/*.sh
```

**Docker Not Running**
```bash
# Start Docker service
sudo systemctl start docker  # Linux
# Or start Docker Desktop manually
```

**Port Already in Use**
```bash
# Check what's using the port
lsof -i :3000
lsof -i :3001
lsof -i :8080

# Stop conflicting services
./scripts/stop.sh
```

**Node.js Version Issues**
```bash
# Check version
node --version

# Install correct version (using nvm)
nvm install 18
nvm use 18
```

### Getting Help

1. **Check Requirements**: Run `./scripts/check-requirements.sh`
2. **View Logs**: Run `./scripts/logs.sh` to see error messages
3. **Restart Services**: Run `./scripts/restart.sh` to reset everything
4. **Clean Setup**: Remove `.env` files and run setup again

## Customization

### Environment Variables
Edit `.env` file to customize:
- Database credentials
- API endpoints
- Security keys
- Service ports

### Service Configuration
Modify configuration files:
- `platformatic/platformatic.json` - API configuration
- `frontend/next.config.js` - Frontend configuration
- `docker-compose.yml` - Docker services

### Script Behavior
Scripts can be customized by editing:
- Service startup order
- Health check timeouts
- Log file locations
- Default ports

## Integration with IDEs

### Visual Studio Code
```bash
# Open project in VS Code
code .

# Install recommended extensions
# - PHP Intelephense
# - ES7+ React/Redux/React-Native snippets
# - Tailwind CSS IntelliSense
# - Docker
```

### PhpStorm
- Import project as existing source
- Configure PHP interpreter
- Set up Node.js integration
- Configure Docker integration

## Continuous Integration

The scripts can be adapted for CI/CD pipelines:

```yaml
# Example GitHub Actions workflow
- name: Setup Environment
  run: ./scripts/setup.sh

- name: Run Tests
  run: |
    ./scripts/dev.sh &
    sleep 30
    npm test
    ./scripts/stop.sh
```

## Security Considerations

- Scripts generate secure random values for secrets
- Environment files are excluded from version control
- Database credentials use strong defaults
- API keys are randomly generated
- SSL/TLS configuration for production

These automation scripts significantly reduce the complexity of setting up and managing the development environment, making it easy for new developers to get started and for teams to maintain consistent development setups.

