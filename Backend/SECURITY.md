# Security Implementation Guide

This document describes the comprehensive security middleware and guards implemented for the EnglishBackendDevelopment project.

## Overview

The security implementation includes:

- **CORS Configuration**: Proper CORS setup with allowlist of origins and credentials support
- **Security Headers**: HSTS, CSP, X-Content-Type-Options, Referrer-Policy, X-Frame-Options
- **Request Validation**: CSRF protection and Origin/Referer header validation
- **IP Extraction**: Real IP extraction with proxy support
- **Request Logging**: Security-focused request/response logging
- **Rate Limiting**: Granular rate limiting per endpoint type
- **Enhanced JWT Authentication**: Updated JWT guard with comprehensive validation
- **Origin Validation**: Ensures requests come from allowed origins

## Files Created

### Configuration
- `/src/infrastructure/config/security/security.config.ts` - Main security configuration
- Updated `/src/infrastructure/config/app.config.ts` - Added security toggles

### Middleware
- `/src/shared/middleware/security.middleware.ts` - Core security middleware
- `/src/shared/middleware/cors.middleware.ts` - Custom CORS handling

### Guards
- `/src/shared/guards/csrf.guard.ts` - CSRF protection with X-Requested-With validation
- `/src/shared/guards/enhanced-jwt.guard.ts` - Enhanced JWT authentication
- `/src/shared/guards/origin-validation.guard.ts` - Origin validation
- `/src/shared/guards/rate-limit.guard.ts` - Comprehensive rate limiting

### Integration
- `/src/shared/security.module.ts` - Security module for dependency injection
- Updated `/src/app.module.ts` - Integrated security configuration and module
- Updated `/src/main.ts` - Applied security middleware
- Updated `/src/presentation/controllers/auth.controller.ts` - Applied security decorators

### Configuration Files
- `/.env.security.example` - Example environment configuration with all security variables

## Security Features

### 1. CORS Configuration
- Allowlist-based origin control
- Credentials support for authentication endpoints
- Proper preflight handling
- Security-focused error responses

### 2. Security Headers
- **HSTS**: HTTP Strict Transport Security
- **CSP**: Content Security Policy with strict directives
- **X-Content-Type-Options**: Prevents MIME type sniffing
- **X-Frame-Options**: Prevents clickjacking
- **Referrer-Policy**: Controls referrer information
- **X-XSS-Protection**: XSS attack protection

### 3. CSRF Protection
- Cookie-based CSRF tokens
- X-Requested-With header validation
- Secure cookie configuration
- Timing-safe token comparison

### 4. Rate Limiting
- **Registration**: 3 attempts/hour per IP
- **Login**: 5 attempts/minute per IP, 20/hour per account
- **Forgot Password**: 3 attempts/hour per IP
- **Token Refresh**: 30 attempts/5 minutes per IP
- **Email Verification**: 10 attempts/5 minutes per IP
- **General API**: 100 requests/15 minutes per IP

### 5. Enhanced JWT Guard
- Proper JWT claim validation
- Role-based access control
- Token type validation (access vs refresh)
- Comprehensive error handling
- User information injection

### 6. Origin Validation
- Strict origin checking
- Cross-origin request monitoring
- Referer header validation (optional)
- Endpoint-specific allowed origins

### 7. IP Extraction and Privacy
- Proxy-aware IP extraction
- Privacy preservation through IP anonymization
- Configurable proxy headers
- Fallback mechanisms

### 8. Security Logging
- Security-focused request logging
- Sensitive data sanitization
- Configurable log levels
- Performance-conscious logging

## Usage

### Environment Configuration

Copy `.env.security.example` to `.env` and configure:

```bash
cp .env.security.example .env
```

### Security Decorators

The implementation provides several decorators for endpoint-level control:

#### Authentication
```typescript
@Public() // Skip JWT authentication
@Roles('admin', 'user') // Require specific roles
```

#### CSRF Protection
```typescript
@SkipCSRF() // Skip CSRF validation (for public endpoints)
```

#### Origin Validation
```typescript
@SkipOriginValidation() // Skip origin validation
@AllowedOrigins('https://trusted-domain.com') // Allow specific origins
```

#### Rate Limiting
```typescript
@UseRateLimit(RATE_LIMITS.LOGIN) // Use predefined rate limit
@SkipRateLimit() // Skip rate limiting
@RateLimit({ windowMs: 60000, max: 10 }) // Custom rate limit
```

### Example Controller Implementation

```typescript
@Controller('auth')
export class AuthController {
  
  @Post('login')
  @Public()
  @SkipCSRF()
  @UseRateLimit(RATE_LIMITS.LOGIN)
  async login(@Body() loginDto: LoginDto) {
    // Login implementation
  }

  @Get('profile')
  @Roles('user')
  @SkipCSRF()
  async getProfile() {
    // Profile implementation - requires authentication
  }

  @Post('admin-action')
  @Roles('admin')
  async adminAction(@Body() data: any) {
    // Admin action - requires CSRF token and admin role
  }
}
```

## Security Best Practices

### 1. Rate Limiting
- Adjust limits based on your application's needs
- Consider implementing Redis-based store for production
- Monitor rate limit violations for security threats

### 2. CORS Configuration
- Keep allowed origins list minimal and specific
- Avoid wildcard origins in production
- Regularly audit allowed origins

### 3. CSRF Protection
- Always validate CSRF tokens for state-changing operations
- Use secure, HttpOnly cookies for CSRF tokens
- Implement proper token rotation

### 4. JWT Security
- Use strong secrets and rotate them regularly
- Implement proper token expiration times
- Validate all JWT claims thoroughly

### 5. Logging and Monitoring
- Monitor security events and violations
- Implement alerting for suspicious activities
- Regular security log analysis

### 6. Headers Security
- Regularly update CSP policies
- Enable HSTS preload for production domains
- Monitor security header compliance

## Production Deployment

### Environment Variables
Set these critical environment variables for production:

```bash
NODE_ENV=production
TRUST_PROXY=true
CORS_ORIGINS=https://your-frontend-domain.com
JWT_ACCESS_TOKEN_SECRET=your-super-secure-secret
JWT_REFRESH_TOKEN_SECRET=your-super-secure-refresh-secret
HSTS_PRELOAD=true
ORIGIN_VALIDATION_STRICT=true
```

### Additional Security Measures
1. Use HTTPS for all communications
2. Implement proper database security
3. Regular security audits and updates
4. Monitor for security vulnerabilities
5. Implement proper backup and recovery procedures

## Monitoring and Maintenance

### Security Metrics to Monitor
- Rate limit violations by IP and endpoint
- CSRF validation failures
- Origin validation failures
- JWT validation errors
- Suspicious request patterns

### Regular Security Tasks
1. Review and update allowed origins
2. Rotate JWT secrets
3. Update CSP policies
4. Monitor security logs
5. Update rate limiting rules based on usage patterns

## Troubleshooting

### Common Issues

#### CORS Errors
- Verify origin is in allowed list
- Check credentials configuration
- Validate preflight responses

#### Rate Limiting Issues
- Check IP extraction configuration
- Verify rate limit settings
- Monitor rate limit headers

#### CSRF Validation Failures
- Ensure X-Requested-With header is set
- Verify CSRF cookie configuration
- Check token generation and validation

#### JWT Authentication Issues
- Validate token format and claims
- Check token expiration
- Verify secrets and algorithms

## Security Updates

This security implementation should be regularly reviewed and updated to address:
- New security threats
- Framework updates
- Best practice changes
- Performance optimizations

For questions or security concerns, please refer to the project's security policy or contact the development team.