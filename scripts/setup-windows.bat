@echo off
REM Windows Setup Script for Drupal Platformatic Next.js Example
REM This script provides Windows-specific setup instructions and automation

echo ========================================
echo   Drupal + Platformatic + Next.js Setup
echo   Windows Installation Guide
echo ========================================
echo.

REM Check if we're in the right directory
if not exist "docker-compose.yml" (
    echo [ERROR] Please run this script from the project root directory
    pause
    exit /b 1
)

echo [INFO] Checking system requirements...
echo.

REM Check for required software
where docker >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Docker is not installed or not in PATH
    echo Please install Docker Desktop from: https://docs.docker.com/desktop/windows/
    goto :requirements_failed
)

where docker-compose >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Docker Compose is not installed or not in PATH
    echo Please install Docker Desktop which includes Docker Compose
    goto :requirements_failed
)

where node >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Node.js is not installed or not in PATH
    echo Please install Node.js from: https://nodejs.org/
    goto :requirements_failed
)

where npm >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] npm is not installed or not in PATH
    echo npm should be included with Node.js installation
    goto :requirements_failed
)

where php >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] PHP is not installed or not in PATH
    echo Please install PHP from: https://windows.php.net/download/
    goto :requirements_failed
)

where composer >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Composer is not installed or not in PATH
    echo Please install Composer from: https://getcomposer.org/download/
    goto :requirements_failed
)

echo [SUCCESS] All required software is installed!
echo.

REM Check Node.js version
for /f "tokens=1 delims=." %%a in ('node --version') do set NODE_MAJOR=%%a
set NODE_MAJOR=%NODE_MAJOR:v=%
if %NODE_MAJOR% lss 18 (
    echo [ERROR] Node.js version 18 or higher is required
    node --version
    goto :requirements_failed
)

echo [SUCCESS] Node.js version check passed
echo.

REM Create environment file
echo [INFO] Creating environment configuration...
if not exist ".env" (
    (
        echo # Database Configuration
        echo MYSQL_ROOT_PASSWORD=rootpassword
        echo MYSQL_DATABASE=drupal
        echo MYSQL_USER=drupal
        echo MYSQL_PASSWORD=drupal
        echo.
        echo # Drupal Configuration
        echo DRUPAL_DATABASE_HOST=localhost
        echo DRUPAL_DATABASE_PORT=3306
        echo DRUPAL_DATABASE_NAME=drupal
        echo DRUPAL_DATABASE_USERNAME=drupal
        echo DRUPAL_DATABASE_PASSWORD=drupal
        echo DRUPAL_HASH_SALT=your-random-hash-salt-here
        echo DRUPAL_ENV=development
        echo.
        echo # API Configuration
        echo API_BASE_URL=http://localhost:3001
        echo DRUPAL_BASE_URL=http://localhost:8080
        echo FRONTEND_URL=http://localhost:3000
        echo.
        echo # Security Configuration
        echo JWT_SECRET=your-jwt-secret-here
        echo API_KEY=your-api-key-here
        echo.
        echo # Redis Configuration
        echo REDIS_HOST=localhost
        echo REDIS_PORT=6379
    ) > .env
    echo [SUCCESS] Environment file created
) else (
    echo [WARNING] Environment file already exists, skipping...
)
echo.

REM Start Docker services
echo [INFO] Starting Docker services...
docker info >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Docker is not running. Please start Docker Desktop first.
    pause
    exit /b 1
)

docker-compose up -d mysql redis mailhog
if %errorlevel% neq 0 (
    echo [ERROR] Failed to start Docker services
    pause
    exit /b 1
)

echo [SUCCESS] Docker services started
echo [INFO] Waiting for MySQL to be ready...
timeout /t 15 /nobreak >nul
echo.

REM Setup Drupal
echo [INFO] Setting up Drupal backend...
cd drupal

echo [INFO] Installing Composer dependencies...
composer install --no-dev --optimize-autoloader
if %errorlevel% neq 0 (
    echo [ERROR] Failed to install Composer dependencies
    cd ..
    pause
    exit /b 1
)

REM Create required directories
if not exist "web\sites\default\files" mkdir web\sites\default\files
if not exist "private" mkdir private

echo [SUCCESS] Drupal dependencies installed
cd ..
echo.

REM Setup Platformatic
echo [INFO] Setting up Platformatic PHP-Node bridge...
cd platformatic

echo [INFO] Installing npm dependencies...
npm install
if %errorlevel% neq 0 (
    echo [ERROR] Failed to install Platformatic dependencies
    cd ..
    pause
    exit /b 1
)

copy ..\env .env >nul 2>&1
echo [SUCCESS] Platformatic setup completed
cd ..
echo.

REM Setup Frontend
echo [INFO] Setting up Next.js frontend...
cd frontend

echo [INFO] Installing npm dependencies...
npm install
if %errorlevel% neq 0 (
    echo [ERROR] Failed to install Frontend dependencies
    cd ..
    pause
    exit /b 1
)

REM Create .env.local file
if not exist ".env.local" (
    (
        echo API_BASE_URL=http://localhost:3001
        echo DRUPAL_BASE_URL=http://localhost:8080
        echo SITE_NAME=Headless Drupal Site
        echo SITE_URL=http://localhost:3000
    ) > .env.local
)

echo [SUCCESS] Frontend setup completed
cd ..
echo.

REM Create batch files for easy development
echo [INFO] Creating development batch files...

REM Create start-dev.bat
(
    echo @echo off
    echo echo Starting development environment...
    echo echo.
    echo echo Starting Platformatic API...
    echo start "Platformatic API" cmd /k "cd platformatic && npm run dev"
    echo timeout /t 5 /nobreak ^>nul
    echo.
    echo echo Starting Next.js Frontend...
    echo start "Next.js Frontend" cmd /k "cd frontend && npm run dev"
    echo.
    echo echo Development environment started!
    echo echo.
    echo echo Available services:
    echo echo - Drupal Admin: http://localhost:8080/admin
    echo echo - API Endpoint: http://localhost:3001
    echo echo - Frontend: http://localhost:3000
    echo echo.
    echo echo Press any key to close this window...
    echo pause ^>nul
) > start-dev.bat

REM Create stop-dev.bat
(
    echo @echo off
    echo echo Stopping development environment...
    echo taskkill /f /im node.exe ^>nul 2^>^&1
    echo docker-compose down
    echo echo Development environment stopped.
    echo pause
) > stop-dev.bat

echo [SUCCESS] Development batch files created
echo.

echo ========================================
echo   Setup completed successfully!
echo ========================================
echo.
echo Next steps:
echo.
echo 1. Complete Drupal installation:
echo    - Open http://localhost:8080 in your browser
echo    - Follow the installation wizard
echo    - Use database settings from .env file
echo.
echo 2. Start development environment:
echo    - Double-click start-dev.bat
echo    - Or manually run:
echo      * cd platformatic ^&^& npm run dev
echo      * cd frontend ^&^& npm run dev
echo.
echo 3. Access your applications:
echo    - Drupal Admin: http://localhost:8080/admin
echo    - API Endpoint: http://localhost:3001
echo    - Frontend: http://localhost:3000
echo.
echo 4. To stop all services:
echo    - Double-click stop-dev.bat
echo    - Or press Ctrl+C in the terminal windows
echo.
echo For more information, see the documentation in the docs/ directory.
echo.
goto :end

:requirements_failed
echo.
echo ========================================
echo   Requirements Check Failed
echo ========================================
echo.
echo Please install the missing software and run this script again.
echo.
echo Installation links:
echo - Docker Desktop: https://docs.docker.com/desktop/windows/
echo - Node.js: https://nodejs.org/en/download/
echo - PHP: https://windows.php.net/download/
echo - Composer: https://getcomposer.org/download/
echo.
echo For detailed instructions, see docs/setup.md
echo.

:end
pause

