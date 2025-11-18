# Runbook de Autenticación – NestJS (HU‑001)

**Contexto**: Este runbook se basa en tu código (NestJS + TypeORM) compartido: *DTOs de registro*, *RegisterUserUseCase*, *UserService*, *RefreshToken entity/repository*, *UserRepository*, *AuthController/AuthModule*.

Objetivo: Aterrizar **requerimientos de seguridad** y el **procedimiento operativo** para registro/login, emisión/rotación de tokens, verificación de correo y recuperación de contraseña; además, listar **gaps** concretos y **cambios sugeridos** directamente aplicables a tu código.

---

## 1) Diagrama y flujo de sesión

- **Access JWT** (vida corta, 15 min) → en **header** `Authorization: Bearer` desde Frontend.
- **Refresh token** (vida media, 7–30 días) → **cookie HttpOnly, Secure, SameSite=Lax**, *no* en `localStorage`. 
- **Rotación** de refresh **en cada** `/auth/refresh`: invalida el anterior y emite uno nuevo. Si se detecta **reuse** → revocar **toda la familia** y forzar re‑login.

```
Frontend ── POST /auth/register ──> Backend (crea user/person) ──> Set-Cookie refresh + access en body
Frontend ── POST /auth/login ──> Backend (valida) ──> Set-Cookie refresh + access en body
Frontend ── POST /auth/refresh (cookie) ──> Backend (rota refresh) ──> Set-Cookie nuevo refresh + nuevo access
Frontend ── POST /auth/logout ──> Backend (revoca refresh actual)
```

> **Nota**: Si necesitas compatibilidad con app móvil sin cookies, usa *refresh* en body solo bajo canal TLS y con protecciones adicionales (pinning/DPoP). Para SPA web, **cookie HttpOnly** es el camino recomendado.

---

## 2) Gaps críticos detectados (con acciones)

1) **Refresh en el body de `RegisterResponseDto`**  
   - *Riesgo*: exfiltración por XSS.  
   - **Acción**: no devolver `refreshToken` en el body; enviar sólo por **cookie HttpOnly**. Mantén `accessToken` e `expiresIn` en la respuesta.

2) **Política de contraseñas débil (min 6)**  
   - **Acción**: subir a **min 12** (ideal 12–128). Validar contra contraseñas comprometidas (p.ej. k‑Anonymity), y no loggear el valor.

3) **Regex de email demasiado restrictivo**  
   - `@Matches(/…{2,4}$/)` rompe TLDs largos.  
   - **Acción**: confía en `@IsEmail()` y elimina `@Matches`. 

4) **JWT claims y llaves**  
   - *Estado*: payload `{ userId, type }` sin `iss/aud/jti`; algoritmo no especificado.  
   - **Acción**: usar **RS256/EdDSA**, header `kid`, claims: `iss`, `aud`, `sub=userId`, `jti`, `iat`, `exp`. Gestionar llaves en KMS y rotarlas.

5) **Rotación y familias de refresh tokens no implementadas**  
   - *Estado*: guardas un hash del token pero no hay *family_id*, `replaced_by`, ni detección de reuse.  
   - **Acción**: introducir **familias** y **rotación** (ver §5 y §8 cambios de schema/repos).

6) **Inconsistencia de hash en `RefreshTokenRepository.findByToken`**  
   - *Estado*: almacenas `hash(token)` pero consultas por `token` plano.  
   - **Acción**: siempre comparar **hash(candidato)** contra columna `token_hash`.

7) **`revokeExpiredTokens` usa `$lt` (no válido en TypeORM)**  
   - **Acción**: usar `LessThan(new Date())` o query builder.

8) **`UserRepository.updateRefreshToken` lanza error**  
   - **Acción**: eliminar método del contrato o implementarlo adecuadamente (**mejor**: gestionar refresh **solo** via `RefreshTokenRepository`).

9) **Faltan endpoints**: `/auth/login`, `/auth/refresh`, `/auth/logout`, `/auth/logout-all`, `/auth/verify-email`, `/auth/forgot`, `/auth/reset`.  
   - **Acción**: implementar contratos del §4.

10) **Rate limiting/anti‑enumeración** inexistente.  
   - **Acción**: límites por IP y por cuenta, respuestas y tiempos homogéneos.

---

## 3) Requerimientos de seguridad (checklist)

- **Registro/Identidad**: verificación de email antes de acceso pleno; reenvío con *cooldown*; mensajes no enumerativos.
- **Contraseñas**: min 12; hash **Argon2id** (mem≥64MB, iters≥3) o **bcrypt** cost 12–14; *pepper* en KMS; historial (últimas 5) opcional.
- **Tokens**: Access 15min; Refresh 7–30d, **rotación**; `kid`/JWKS; `iss/aud/jti`.
- **Cookies**: `HttpOnly; Secure; SameSite=Lax; Path=/auth/refresh`.
- **CSRF**: sólo afecta endpoints que usan cookie (refresh/logout). Verificar **Origin/Referer** + token anti‑CSRF (doble submit) o header `X-Requested-With` que fuerce preflight.
- **CORS**: allowlist estricta de orígenes Frontend.
- **Rate limit**: `/register` 3/h/IP; `/login` 5/min/IP y 20/h por cuenta; `/forgot` 3/h/IP.
- **Auditoría**: registro de alta/baja/refresh/reuse/logout/reset/verify. Redactar PII; retención 90 días.
- **Headers/TLS**: HSTS, CSP restrictiva, `X-Content-Type-Options=nosniff`, `Referrer-Policy=strict-origin-when-cross-origin`.

---

## 4) Contratos de endpoints (NestJS)

### POST `/auth/register`
- **Body**: `RegisterDto` (ver §7 cambios).  
- **Éxito (201)**: Body `{ userId, email, fullName, isEmailVerified, accessToken, expiresIn, message }` y **Set‑Cookie** `refreshToken=...; HttpOnly; Secure; SameSite=Lax; Path=/auth/refresh; Max-Age=604800`.
- **Notas**: No incluir `refreshToken` en body. Disparar envío de *email verification*.

### POST `/auth/login`
- **Body**: `{ identifier: string (email), password: string }`.  
- **Éxito (200)**: Igual a register; set cookie refresh.  
- **Errores**: 401 genérico; 429 por rate‑limit.

### POST `/auth/refresh`
- **Req**: cookie `refreshToken` + header `X-Requested-With: XMLHttpRequest`.  
- **Éxito (200)**: **rotar refresh** (invalidar anterior, crear nuevo) + nuevo access.  
- **Errores**: 401 (inválido/revocado) → si hay **reuse** revocar **familia**; 419 (expirado).

### POST `/auth/logout`
- **Req**: revoca refresh **actual** (por `jti`/`token_hash`).  
- **Opcional**: `allDevices=true` para revocar por `userId`.

### POST `/auth/verify-email`
- **Body**: `{ token: string }` (o link GET). Marca `isEmailVerified=true`, consume token.

### POST `/auth/forgot`
- **Body**: `{ email }` → siempre 200 (mensaje genérico). Genera *code* (10 min) + correo.

### POST `/auth/reset`
- **Body**: `{ email, code, newPassword }` → rota familia de refresh y borra tokens de reset.

### GET `/auth/sessions`
- Lista de sesiones activas (metadatos: dispositivo, `lastSeen`, IP parcial).

---

## 5) Estrategia de tokens

**Opción recomendada (simple y robusta)**
- **Access**: JWT RS256/EdDSA (15 min). Claims: `sub`, `iss`, `aud`, `jti`, `iat`, `exp`, `role`.
- **Refresh**: **token opaco** (random 256 bits). **No** es JWT. Guardar solo **hash** (`token_hash`), más `family_id`, `jti`, `replaced_by`, `revoked_at`, `reason`, `ip_hash`, `user_agent`.
- **Rotación**: cada refresh genera nuevo opaco; el anterior se marca `replaced_by=<id_nuevo>`. Si se presenta un token ya rotado ⇒ **reuse** ⇒ revocar **toda la familia**.

**Si insistes en refresh = JWT**
- Incluir `jti`, `type='refresh'`, `sub=userId`. Aun así **persistir** `hash(jwt)` + `jti` y **rotar**. Validar **ambas**: firma + existencia no revocada en DB.

---

## 6) Modelo de datos (propuesto)

**Tabla `refresh_tokens` (reemplaza/ajusta tu entity)**
- `id (uuid PK)`
- `user_id (FK)`
- `token_hash (varchar 500, unique)` ← **renombrar** de `token`
- `family_id (uuid)` ← familia por sesión/dispositivo
- `jti (uuid)`
- `replaced_by (uuid|null)`
- `revoked_at (timestamptz|null)`
- `reason (varchar 64|null)`
- `device_info (varchar 255|null)`
- `ip_hash (varchar 128|null)`
- `user_agent (varchar 255|null)`
- `expires_at (timestamptz)`
- `created_at / updated_at`

> `isRevoked` se deduce como `revoked_at IS NOT NULL` **o** `expires_at < now()`.

---

## 7) Cambios de código **concretos**

### 7.1 DTOs
```ts
export class RegisterDto {
  @MinLength(2) @MaxLength(200) readonly fullName!: string;
  @IsEmail() @MaxLength(255) readonly email!: string; // quitar @Matches
  @IsString() @MinLength(12) @MaxLength(128) readonly password!: string; // subir a 12
  @IsString() readonly confirmPassword!: string;
}
```

**RegisterResponseDto**
- **Quitar** `refreshToken` del constructor y del `type` expuesto. Mantener `accessToken` y `expiresIn`. Si necesitas compatibilidad móvil temporal, crea **otro DTO** específico (`MobileRegisterResponseDto`).

### 7.2 Use case `RegisterUserUseCase`
- Generar **refresh opaco** y enviarlo por **cookie**. Guardar **hash** + `family_id`.
```ts
const accessToken = await this.jwtService.sign({ sub: user.id, type: 'access' }, { expiresIn: '15m' });
const refreshRaw = crypto.randomBytes(64).toString('base64url');
await this.refreshTokenRepository.save({
  tokenHash: await this.hashService.hash(refreshRaw),
  userId: user.id,
  familyId: crypto.randomUUID(),
  jti: crypto.randomUUID(),
  deviceInfo: null,
  expiresAt: addDays(new Date(), 7),
});
// En el controller: setear cookie HttpOnly con refreshRaw
```

### 7.3 Controller `AuthController`
- En `register` y `login`, **setear cookie**:
```ts
@Post('register')
@HttpCode(HttpStatus.CREATED)
async register(@Body() dto: RegisterDto, @Res({ passthrough: true }) res: Response): Promise<RegisterResponseDto> {
  const out = await this.registerUserUseCase.execute(dto);
  res.cookie('refreshToken', out.refreshRaw, { // NO devolver out.refreshRaw en el body
    httpOnly: true, secure: true, sameSite: 'lax', path: '/auth/refresh', maxAge: 7*24*3600*1000
  });
  return { userId: out.userId, email: out.email, fullName: out.fullName, isEmailVerified: out.isEmailVerified, accessToken: out.accessToken, expiresIn: out.expiresIn, message: out.message };
}
```
> Para no romper contratos, puedes hacer que `execute` devuelva `refreshRaw` **solo** hacia el controller, no en el DTO público.

### 7.4 Nuevo endpoint `/auth/refresh`
```ts
@Post('refresh')
@HttpCode(HttpStatus.OK)
async refresh(@Req() req: Request, @Res({ passthrough: true }) res: Response) {
  const presented = req.cookies['refreshToken'];
  const hash = await this.hashService.hash(presented);
  const rec = await this.refreshTokenRepository.findByHash(hash);
  if (!rec || rec.revoked_at || rec.expires_at < new Date()) throw new UnauthorizedException();
  // ROTACIÓN
  const newRaw = crypto.randomBytes(64).toString('base64url');
  await this.refreshTokenRepository.rotate(rec, await this.hashService.hash(newRaw));
  const access = await this.jwtService.sign({ sub: rec.userId, type: 'access' }, { expiresIn: '15m' });
  res.cookie('refreshToken', newRaw, { httpOnly: true, secure: true, sameSite: 'lax', path: '/auth/refresh', maxAge: 7*24*3600*1000 });
  return { accessToken: access, expiresIn: 900 };
}
```

### 7.5 Repositorio `RefreshTokenRepository`
```ts
// Correcciones clave
async findByHash(tokenHash: string) { return this.repository.findOne({ where: { tokenHash, revoked_at: IsNull() } }); }
async revokeByUserId(userId: string) { await this.repository.update({ userId, revoked_at: IsNull() }, { revoked_at: new Date(), reason: 'USER_LOGOUT_ALL' }); }
async revokeExpiredTokens() { await this.repository.createQueryBuilder().update().set({ revoked_at: () => 'NOW()' }).where('expires_at < NOW() AND revoked_at IS NULL').execute(); }
async rotate(oldRec: RefreshToken, newHash: string) {
  await this.repository.manager.transaction(async m => {
    await m.update(RefreshToken, { id: oldRec.id }, { revoked_at: new Date(), reason: 'ROTATED' });
    await m.save(RefreshToken, { userId: oldRec.userId, tokenHash: newHash, familyId: oldRec.familyId, jti: crypto.randomUUID(), expiresAt: addDays(new Date(), 7) });
  });
}
```

### 7.6 `UserRepository`
- Eliminar el método `updateRefreshToken` del contrato/servicio o dejarlo **no usado**. Gestionar todo vía `RefreshTokenRepository`.

---

## 8) Verificación de email y reset de contraseña

- **Verify**: `generateEmailVerificationToken(id)` ya existe; almacenar **hash** del token, *no* el token plano. Enviar link `GET /auth/verify-email?token=...` con caducidad 10–15 min. Al verificar: marca `emailVerified`, borra token y **revoca** refresh tokens existentes.
- **Reset**: `generatePasswordResetToken(id)` existe; almacenar **hash** y caducidad 10 min. Al resetear: actualizar password (rotar *pepper* si aplica), **revocar** todas las familias de refresh.

---

## 9) CORS, CSRF, rate‑limit, headers

- **CORS**: allowlist (`https://app.tu‑dominio.com`, `https://staging…`). `credentials: true` sólo para `/auth/refresh` y `/auth/logout`.
- **CSRF**: en `/auth/refresh` y `/auth/logout` validar **Origin/Referer** y (opcional) token anti‑CSRF (doble submit) en cookie `csrf` + header `x-csrf-token`.
- **Rate limit**: `@nestjs/throttler` o NGINX/Redis. Bloquear IPs/ASNs abusivos.
- **Headers**: `helmet()`; CSP con fuentes permitidas; HSTS ≥ 6 meses.

---

## 10) Configuración/Secrets (env sugeridas)

```
JWT_ISSUER=https://api.tu-dominio.com
JWT_AUDIENCE=https://app.tu-dominio.com
JWT_ACCESS_TTL=900
JWT_PRIVATE_KEY_KID=current_kid
AUTH_REFRESH_COOKIE_NAME=refreshToken
REFRESH_TTL_DAYS=7
ARGON2_MEM=65536
ARGON2_ITERS=3
RATE_LIMIT_LOGIN=5/m/IP,20/h/account
CORS_ORIGINS=https://app.tu-dominio.com,https://staging.tu-dominio.com
```

Llaves privadas en **KMS/Vault**; publicar **JWKS** con llaves públicas y `kid` vigente.

---

## 11) Pruebas (mínimas)

- **Unitarias**: hash/compare; generación y validación de JWT (claims); validación de DTO (password/email). 
- **Integración**: register → verify → login → refresh*(rotación)* → logout; reuse de refresh ⇒ familia revocada; reset de password ⇒ revocar familias. 
- **E2E**: cookies con flags; CORS; CSRF en refresh/logout; rate‑limit; no enumeración.

---

## 12) Operación (Runbook)

### 12.1 Despliegue inicial
1. Crear pares de llaves (≥2) y subir a KMS con `kid`.
2. Aplicar migraciones (schema de `refresh_tokens` actualizado).
3. Configurar CORS y cookies en gateway/NGINX.
4. Activar dashboards: tasa login ok/ko, refresh, reuse, 401/429.

### 12.2 Rotación de llaves JWT
1. Publicar nueva llave en JWKS (`kid=new`).  
2. Cambiar firma a `kid=new`.  
3. Mantener verificación con llaves viejas por `access_ttl + skew`.  
4. Retirar llave vieja.

### 12.3 Incidente: sospecha de fuga de refresh
1. Elevar severidad **Alta**.  
2. **Revocar por familia** y por usuario afectado.  
3. Invalidar refresh emitidos antes de `T0` (bumping `token_version`).  
4. Forzar logout global + reset de contraseñas (si procede).  
5. Revisar auditoría y notificar según política.

---

## 13) Definition of Done (para este punto)
- [ ] Refresh **no** en body; cookie HttpOnly configurada.  
- [ ] DTOs endurecidos (contraseña 12+, email sin regex frágil).  
- [ ] Repos corregidos (`findByHash`, `revokeExpiredTokens`).  
- [ ] Rotación y familias implementadas.  
- [ ] Endpoints completados (login/refresh/logout/verify/forgot/reset).  
- [ ] CORS/CSRF/Rate‑limit/Headers aplicados (stage).  
- [ ] Plan de pruebas ejecutable.

---

## 14) Snippets útiles (NestJS)

**Setear cookie segura**
```ts
res.cookie('refreshToken', token, {
  httpOnly: true, secure: true, sameSite: 'lax', path: '/auth/refresh', maxAge: 7*24*3600*1000
});
```

**Guard de acceso**
```ts
@Injectable()
export class JwtAuthGuard extends AuthGuard('jwt') {}
```

**Strategy**
```ts
new JwtStrategy({
  jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
  ignoreExpiration: false,
  secretOrKeyProvider: jwksRsa.expressJwtSecret({ cache: true, rateLimit: true, jwksUri }),
  audience: process.env.JWT_AUDIENCE,
  issuer: process.env.JWT_ISSUER,
});
```

