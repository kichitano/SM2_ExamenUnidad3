# Script para ejecutar pruebas E2E de Login/Logout
# PowerShell script to run E2E Login/Logout tests

Write-Host "=== English App E2E Tests ==="
Write-Host "Ejecutando pruebas de integración para Login/Logout"
Write-Host ""

# Verificar que Flutter esté instalado
Write-Host "Verificando instalación de Flutter..."
try {
    $flutterVersion = flutter --version
    Write-Host "✓ Flutter encontrado" -ForegroundColor Green
} catch {
    Write-Host "✗ Flutter no encontrado. Por favor instala Flutter primero." -ForegroundColor Red
    exit 1
}

# Limpiar dependencias
Write-Host "Limpiando dependencias..."
flutter clean

# Obtener dependencias
Write-Host "Obteniendo dependencias..."
flutter pub get

# Verificar que hay dispositivos disponibles
Write-Host "Verificando dispositivos disponibles..."
$devices = flutter devices
Write-Host $devices

if ($devices -match "No devices detected") {
    Write-Host "✗ No se detectaron dispositivos. Por favor conecta un dispositivo o inicia un emulador." -ForegroundColor Red
    exit 1
}

Write-Host "✓ Dispositivos detectados" -ForegroundColor Green
Write-Host ""

# Ejecutar pruebas E2E específicas de Login/Logout
Write-Host "=== Ejecutando Pruebas E2E de Login/Logout ==="
Write-Host "Esto puede tomar varios minutos..."
Write-Host ""

try {
    # Ejecutar pruebas de login/logout específicas
    Write-Host "Ejecutando pruebas de Login/Logout..." -ForegroundColor Yellow
    flutter test integration_test/login_logout_test.dart
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Pruebas de Login/Logout completadas exitosamente" -ForegroundColor Green
    } else {
        Write-Host "✗ Algunas pruebas de Login/Logout fallaron" -ForegroundColor Red
    }
    
    Write-Host ""
    
    # Ejecutar todas las pruebas E2E
    Write-Host "Ejecutando todas las pruebas E2E..." -ForegroundColor Yellow
    flutter test integration_test/app_test.dart
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Todas las pruebas E2E completadas exitosamente" -ForegroundColor Green
    } else {
        Write-Host "✗ Algunas pruebas E2E fallaron" -ForegroundColor Red
    }
    
} catch {
    Write-Host "✗ Error ejecutando las pruebas: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "=== Resumen de Pruebas ==="
Write-Host "Las pruebas E2E han sido ejecutadas."
Write-Host "Revisa los resultados arriba para ver el estado de cada prueba."
Write-Host ""
Write-Host "Pruebas incluidas:"
Write-Host "- Login con credenciales válidas y logout"
Write-Host "- Validación de formulario de login"
Write-Host "- Login con Google"
Write-Host "- Login con Apple"
Write-Host "- Funcionalidad 'Recordarme'"
Write-Host "- Navegación a 'Olvidé mi contraseña'"
Write-Host ""
Write-Host "Para ejecutar pruebas individuales, usa:"
Write-Host "flutter test integration_test/login_logout_test.dart --verbose"