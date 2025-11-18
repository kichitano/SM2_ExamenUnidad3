# English Learning App Backend

Backend API for the English Learning App built with Node.js, TypeScript, NestJS, and TypeORM following Clean Architecture principles.

## 🏗️ Architecture

This project follows **Clean Architecture** principles with the following structure:

```
src/
├── application/              # Application layer (Use cases/Business logic)
│   ├── dtos/                # Data Transfer Objects
│   ├── interfaces/          # Repository and service interfaces
│   ├── services/            # Application services
│   └── use-cases/           # Business use cases
├── domain/                  # Domain layer (Entities and business rules)
│   ├── entities/            # Domain entities
│   ├── errors/              # Domain-specific errors
├── infrastructure/          # Infrastructure layer (External concerns)
│   ├── database/            # Database configuration and migrations
│   ├── repositories/        # Repository implementations
│   └── config/              # Configuration files
├── presentation/            # Presentation layer (Controllers and routes)
│   ├── controllers/         # Route controllers
│   └── modules/             # NestJS modules
└── shared/                  # Shared utilities and constants
    ├── filters/             # Exception filters
    └── services/            # Shared services
```

## 🚀 Features

- **Clean Architecture** - Well-organized, maintainable codebase
- **TypeScript Strict Mode** - Type safety with zero tolerance for `any` types
- **TypeORM** - Database ORM with PostgreSQL
- **NestJS** - Scalable Node.js framework
- **JWT Authentication** - Secure user authentication
- **Swagger Documentation** - Auto-generated API docs
- **Database Migrations** - Version-controlled database schema
- **Error Handling** - Global exception handling
- **Validation** - Request/response validation with class-validator
- **Testing** - Unit and integration tests setup

## 📦 Entities

### Person Entity
- Personal information (name, email, phone, document, etc.)
- Support for different document types (DNI, PASSPORT, CEDULA, OTHER)
- Demographic information (birth date, gender, nationality, location)
- Profile image support
- Soft delete functionality

### User Entity
- Authentication data (username, email, password)
- Multiple auth providers (EMAIL_PASSWORD, GOOGLE, APPLE, FACEBOOK)
- Role-based access (STUDENT, TEACHER, ADMIN, SUPER_ADMIN)
- Email verification and password reset tokens
- One-to-one relationship with Person entity

## 🛠️ Setup

### Prerequisites

- Node.js (v18 or higher)
- PostgreSQL (v12 or higher)
- npm or yarn

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd EnglishBackendDevelopment
```

2. Install dependencies:
```bash
npm install
```

3. Set up environment variables:
```bash
cp .env.example .env
# Edit .env with your configuration
```

4. Set up database:
```bash
# Create database
createdb english_learn_db

# Generate migration (example)
npm run migration:generate -- CreatePersonTable

# Run migrations
npm run migration:run
```

### Development

```bash
# Start development server
npm run start:dev

# Build for production
npm run build

# Start production server
npm run start:prod
```

## 📝 Scripts

### Development
- `npm run start:dev` - Start development server with hot reload
- `npm run start:debug` - Start with debugging enabled

### Code Quality
- `npm run lint` - Fix linting issues
- `npm run lint:check` - Check linting without fixing
- `npm run format` - Format code with Prettier
- `npm run format:check` - Check formatting without fixing

### Testing
- `npm run test` - Run unit tests
- `npm run test:watch` - Run tests in watch mode
- `npm run test:cov` - Run tests with coverage
- `npm run test:e2e` - Run end-to-end tests

### Database Operations
- `npm run migration:generate -- MigrationName` - Generate migration
- `npm run migration:run` - Apply migrations
- `npm run migration:revert` - Revert last migration
- `npm run migration:show` - Show migration status

## 🔧 Configuration

### Environment Variables

See `.env.example` for all available environment variables:

- **Application**: PORT, NODE_ENV, API_PREFIX
- **Database**: DATABASE_HOST, DATABASE_PORT, DATABASE_USERNAME, etc.
- **JWT**: JWT_SECRET, JWT_EXPIRES_IN, JWT_REFRESH_SECRET, etc.
- **External Services**: GOOGLE_CLIENT_ID, APPLE_TEAM_ID, etc.

### Database

The application uses PostgreSQL with TypeORM. All database changes must be done through migrations:

```bash
# Generate a new migration
npm run migration:generate -- src/infrastructure/database/migrations/YourMigrationName

# Run migrations
npm run migration:run
```

## 📚 API Documentation

Once the server is running, access the Swagger documentation at:
```
http://localhost:3000/api/docs
```

## 🧪 Testing

The project includes comprehensive testing setup:

- **Unit Tests** - Test individual components
- **Integration Tests** - Test API endpoints
- **E2E Tests** - Test complete user flows

```bash
npm run test              # Unit tests
npm run test:e2e          # E2E tests
npm run test:cov          # Coverage report
```

## 🏷️ Standards & Rules

This project follows strict coding standards:

- **TypeScript Strict Mode** - No `any` types allowed
- **Clean Architecture** - Clear separation of concerns
- **Maximum 400 lines** per file
- **Comprehensive error handling**
- **Repository pattern** for data access
- **Use cases** for business logic
- **DTOs** for data validation

## 🤝 Contributing

1. Follow the established architecture patterns
2. Write tests for new features
3. Ensure all linting and tests pass
4. Update documentation as needed

## 📄 License

This project is private and unlicensed.