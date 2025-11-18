# RefreshTokenRotationService Documentation

## Overview

The `RefreshTokenRotationService` provides comprehensive refresh token rotation capabilities following security best practices. This service implements family-based token tracking, automatic reuse detection, and secure token management for the English Backend Development project.

## Key Features

### 🔄 Secure Token Rotation
- Atomic token rotation with database transactions
- Automatic invalidation of old tokens when new ones are created
- 256-bit cryptographically secure token generation
- Proper linking between old and new tokens for audit trails

### 👥 Family-Based Token Management
- Groups tokens by device/session using family IDs
- Tracks device information, user agents, and IP hashes
- Allows management of multiple active sessions per user
- Supports device-specific logout functionality

### 🚨 Reuse Detection & Security
- Automatic detection of token reuse attempts
- Immediate revocation of entire token families when reuse is detected
- Comprehensive security logging and audit trails
- Rate limiting for token operations to prevent abuse

### 📊 Audit & Monitoring
- Detailed security event logging
- Token lifecycle tracking
- Family and user-level revocation capabilities
- Expired token cleanup mechanisms

## Architecture

### Core Components

```
RefreshTokenRotationService
├── IRefreshTokenRotationService (Interface)
├── TokenRotationException Classes (Error Handling)
├── RefreshTokenUseCase (Use Case Implementation)
└── Integration with existing services
    ├── IRefreshTokenRepository
    ├── IHashUtilityService
    └── ITokenGenerationService
```

### Database Schema

The service works with the updated `refresh_tokens` table:

```sql
CREATE TABLE refresh_tokens (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id),
    token_hash VARCHAR(500) UNIQUE NOT NULL,
    family_id UUID NOT NULL,
    jti UUID UNIQUE NOT NULL,
    replaced_by UUID,
    revoked_at TIMESTAMPTZ,
    reason VARCHAR(64),
    device_info VARCHAR(255),
    ip_hash VARCHAR(128),
    user_agent VARCHAR(255),
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

## API Reference

### Core Methods

#### `rotateToken(oldTokenHash: string, context?: RotationContext): Promise<TokenRotationResult>`

Rotates a refresh token by invalidating the old one and creating a new one.

**Parameters:**
- `oldTokenHash`: Hash of the token to be rotated
- `context`: Optional context including device info, user agent, IP address

**Returns:**
- `TokenRotationResult`: Information about both old and new tokens

**Example:**
```typescript
const result = await refreshTokenRotationService.rotateToken(tokenHash, {
  deviceInfo: 'iPhone 13',
  userAgent: 'Mozilla/5.0...',
  ipAddress: '192.168.1.1'
});
```

#### `validateAndRotateToken(presentedToken: string, context?: RotationContext)`

Validates a presented token and rotates it if valid.

**Parameters:**
- `presentedToken`: The raw token being presented
- `context`: Additional context for validation and rotation

**Returns:**
- Combined validation and rotation result

**Example:**
```typescript
const result = await refreshTokenRotationService.validateAndRotateToken(token, {
  deviceInfo: 'Android Phone',
  userAgent: 'Chrome Mobile',
  ipAddress: '10.0.0.1'
});

if (!result.isValid) {
  if (result.shouldRevokeFamily) {
    // Handle token reuse - family compromised
    throw new TokenFamilyCompromisedException();
  }
  // Handle invalid token
  throw new InvalidTokenException();
}

// Use result.rotation for new token information
```

#### `detectTokenReuse(tokenHash: string): Promise<boolean>`

Detects if a token is being reused (already rotated/revoked).

**Example:**
```typescript
const isReused = await refreshTokenRotationService.detectTokenReuse(tokenHash);
if (isReused) {
  // Handle security violation
}
```

#### `revokeFamilyTokens(familyId: string, reason: string): Promise<number>`

Revokes all tokens in a family due to security incident.

**Example:**
```typescript
const count = await refreshTokenRotationService.revokeFamilyTokens(
  familyId, 
  'SECURITY_VIOLATION'
);
console.log(`Revoked ${count} tokens`);
```

#### `createTokenFamily(userId: string, deviceInfo?, userAgent?, ipAddress?): Promise<TokenFamilyInfo>`

Creates a new token family for device/session management.

**Example:**
```typescript
const family = await refreshTokenRotationService.createTokenFamily(
  userId,
  'MacBook Pro',
  'Safari 15.0',
  '192.168.1.100'
);
```

## Usage Examples

### Basic Token Refresh Flow

```typescript
@Injectable()
export class AuthService {
  constructor(
    private refreshTokenRotationService: IRefreshTokenRotationService,
    private jwtService: IJwtService
  ) {}

  async refreshTokens(refreshToken: string, context: any) {
    try {
      // Validate and rotate token
      const result = await this.refreshTokenRotationService
        .validateAndRotateToken(refreshToken, context);
      
      if (!result.isValid) {
        throw new UnauthorizedException('Invalid refresh token');
      }

      // Generate new access token
      const accessToken = await this.jwtService.createAccessToken(
        result.token.userId,
        result.token.user.role
      );

      return {
        accessToken,
        refreshToken: result.rotation.newToken.tokenHash,
        expiresIn: 3600
      };
    } catch (error) {
      if (error instanceof TokenReuseDetectedException) {
        // Log security incident
        this.logger.error('Token reuse detected', { familyId: error.familyId });
      }
      throw error;
    }
  }
}
```

### Device Management

```typescript
async getUserDevices(userId: string) {
  const families = await this.refreshTokenRotationService
    .getActiveFamilies(userId);
  
  return families.map(family => ({
    id: family.familyId,
    deviceInfo: family.deviceInfo,
    lastActive: family.lastUsed,
    // Don't expose sensitive information like IP hashes
  }));
}

async logoutFromDevice(familyId: string) {
  const count = await this.refreshTokenRotationService
    .revokeFamilyTokens(familyId, 'USER_INITIATED_LOGOUT');
  
  return { revokedTokens: count };
}
```

### Security Incident Response

```typescript
async handleSecurityIncident(userId: string) {
  // Revoke all user tokens
  const count = await this.refreshTokenRotationService
    .revokeUserTokens(userId, 'SECURITY_INCIDENT');
  
  // Log the incident
  this.logger.error('Security incident - all tokens revoked', {
    userId,
    revokedCount: count
  });
  
  return count;
}
```

## Security Features

### Reuse Detection

The service automatically detects when revoked tokens are presented:

1. **Detection**: When a revoked token is presented, it's flagged as reuse
2. **Response**: The entire token family is immediately revoked
3. **Logging**: Critical security events are logged with full context
4. **User Impact**: All sessions for that device/family are terminated

### Rate Limiting

Built-in rate limiting prevents token rotation abuse:

- **Limit**: 5 rotations per minute per user
- **Window**: Rolling 60-second window
- **Response**: `TokenOperationRateLimitedException` when exceeded
- **Cleanup**: Automatic cleanup of expired rate limit entries

### Family Management

Token families provide device-level session management:

- **Creation**: New family per device/session
- **Tracking**: Device info, user agent, and IP hash
- **Limitation**: Maximum 10 families per user
- **Revocation**: Surgical revocation by family or user-wide

## Error Handling

### Custom Exceptions

The service provides specific exceptions for different scenarios:

```typescript
try {
  await refreshTokenRotationService.rotateToken(tokenHash);
} catch (error) {
  if (error instanceof TokenReuseDetectedException) {
    // Handle reuse detection
    console.log(`Family compromised: ${error.familyId}`);
  } else if (error instanceof TokenFamilyLimitExceededException) {
    // Handle too many devices
    console.log(`Too many devices for user: ${error.userId}`);
  } else if (error instanceof InvalidTokenException) {
    // Handle invalid token
    console.log('Token is invalid or expired');
  }
}
```

### Exception Types

- `TokenRotationException`: Base exception class
- `InvalidTokenException`: Invalid or expired tokens
- `TokenReuseDetectedException`: Token reuse detected
- `TokenFamilyCompromisedException`: Family has been compromised
- `TokenRotationFailedException`: Operation failed
- `TokenFamilyConflictException`: Family already exists
- `TokenFamilyLimitExceededException`: Too many families
- `TokenOperationRateLimitedException`: Rate limit exceeded

## Configuration

### Service Dependencies

Ensure these services are properly configured in your module:

```typescript
@Module({
  providers: [
    RefreshTokenRotationService,
    {
      provide: 'IRefreshTokenRepository',
      useClass: RefreshTokenRepository,
    },
    {
      provide: 'IHashUtilityService', 
      useClass: HashUtilityService,
    },
    {
      provide: 'ITokenGenerationService',
      useClass: TokenGenerationService,
    },
    // ... other providers
  ],
})
export class AuthModule {}
```

### Environment Variables

Consider these configuration options:

```env
# Token rotation settings
MAX_TOKEN_FAMILIES_PER_USER=10
TOKEN_ROTATION_RATE_LIMIT=5
REFRESH_TOKEN_EXPIRES_DAYS=30

# Security settings
ENABLE_TOKEN_REUSE_DETECTION=true
LOG_SECURITY_EVENTS=true
```

## Best Practices

### 1. Always Use Transactions
Token rotation operations should be atomic:

```typescript
// Good - Uses transaction in implementation
await this.rotateToken(tokenHash, context);

// Bad - Manual transaction management
const queryRunner = this.dataSource.createQueryRunner();
// ... manual transaction code
```

### 2. Handle Reuse Detection Properly
Always check for reuse and handle it appropriately:

```typescript
const result = await service.validateAndRotateToken(token);
if (!result.isValid && result.shouldRevokeFamily) {
  // Critical security event - log and alert
  await this.securityService.handleCriticalEvent({
    type: 'TOKEN_REUSE',
    userId: result.userId,
    timestamp: new Date()
  });
}
```

### 3. Implement Proper Logging
Security events should be logged comprehensively:

```typescript
// The service automatically logs, but you can add application-level logging
this.logger.security('Token rotation completed', {
  userId,
  familyId,
  deviceInfo,
  timestamp: new Date().toISOString()
});
```

### 4. Regular Cleanup
Implement background tasks for token cleanup:

```typescript
@Cron(CronExpression.EVERY_DAY_AT_MIDNIGHT)
async cleanupTokens() {
  const count = await this.refreshTokenRotationService.cleanupExpiredTokens();
  this.logger.log(`Cleaned up ${count} expired tokens`);
}
```

## Monitoring & Alerts

### Key Metrics to Monitor

1. **Token Rotation Rate**: Unusual spikes may indicate attacks
2. **Reuse Detection Events**: Should be rare in normal operation
3. **Family Revocation Events**: May indicate compromised accounts
4. **Rate Limit Violations**: Could indicate brute force attempts

### Recommended Alerts

- Critical alert on token reuse detection
- Warning on high token rotation rates
- Info on family limit exceeded events
- Daily summary of token cleanup activities

## Integration with Frontend

### Token Storage
Store refresh tokens securely in the frontend:

```javascript
// Good - HttpOnly cookie (handled by backend)
// Token automatically included in requests

// Bad - LocalStorage or SessionStorage
localStorage.setItem('refreshToken', token); // Don't do this
```

### Error Handling
Handle rotation errors gracefully:

```javascript
async function refreshTokens() {
  try {
    const response = await api.post('/auth/refresh');
    return response.data;
  } catch (error) {
    if (error.status === 401) {
      // Token invalid - redirect to login
      window.location.href = '/login';
    } else if (error.status === 429) {
      // Rate limited - show message and retry later
      showMessage('Too many attempts. Please wait.');
    }
    throw error;
  }
}
```

## Testing

### Unit Tests Example

```typescript
describe('RefreshTokenRotationService', () => {
  it('should rotate token successfully', async () => {
    const result = await service.rotateToken(tokenHash, context);
    
    expect(result.oldToken.revoked).toBe(true);
    expect(result.newToken.jti).toBeDefined();
    expect(result.newToken.familyId).toBe(result.oldToken.familyId);
  });

  it('should detect token reuse', async () => {
    // Rotate token first
    await service.rotateToken(tokenHash, context);
    
    // Attempt to use old token - should detect reuse
    const isReused = await service.detectTokenReuse(tokenHash);
    expect(isReused).toBe(true);
  });

  it('should revoke family on reuse detection', async () => {
    // Setup family with multiple tokens
    // Simulate reuse
    // Verify entire family is revoked
  });
});
```

## Performance Considerations

### Database Indexes
Ensure proper indexes exist:

```sql
CREATE INDEX CONCURRENTLY idx_refresh_tokens_user_valid 
ON refresh_tokens (user_id) 
WHERE revoked_at IS NULL AND expires_at > NOW();

CREATE INDEX CONCURRENTLY idx_refresh_tokens_family_valid 
ON refresh_tokens (family_id) 
WHERE revoked_at IS NULL AND expires_at > NOW();
```

### Rate Limiting Memory Usage
The in-memory rate limiting map automatically cleans itself:

- 10% chance of cleanup on each request
- Removes expired entries to prevent memory leaks
- Consider Redis for distributed deployments

### Token Cleanup
Regular cleanup prevents table bloat:

```sql
-- Run periodically to remove old revoked tokens
DELETE FROM refresh_tokens 
WHERE revoked_at IS NOT NULL 
AND revoked_at < NOW() - INTERVAL '90 days';
```

This comprehensive service provides enterprise-grade refresh token management with security best practices built-in. Use it as the foundation for secure authentication in your application.