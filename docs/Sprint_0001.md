# Sprint 0001

## [x] Repository is initialized and available in version control
- Category: functional
- Steps:
  - Open the project root
  - Verify the repository has a .git directory
  - Confirm the main branch exists

## [x] CI/CD pipeline is configured for the repository
- Category: functional
- Steps:
  - Open .github/workflows
  - Verify at least one workflow file exists
  - Confirm the workflow is intended for CI/CD

## [x] Next.js (TypeScript) application is initialized using the latest stable tooling
- Category: functional
- Steps:
  - Run the Next.js project initialization for a TypeScript app
  - Verify the generated project structure exists (app or pages, next.config, tsconfig)
  - Run the development server and confirm it starts successfully

## [x] README documents the first three sprint requirements
- Category: functional
- Steps:
  - Open README.md in the repository root (create it if missing)
  - Add a section documenting the first three sprint requirements in order
  - Confirm the README mentions they are requirements and notes their current status

## [x] PostgreSQL database service is defined for local development
- Category: functional
- Steps:
  - Define a PostgreSQL service configuration (image, ports, env, volume)
  - Start the database service
  - Verify the database is reachable using the configured connection details

## [x] Dockerfile exists for the Next.js application
- Category: functional
- Steps:
  - Create a Dockerfile for the app
  - Build the Docker image without errors
  - Run the container and verify the app starts

## [x] docker-compose configuration starts the full stack (app + Postgres)
- Category: functional
- Steps:
  - Create docker-compose.yml with app and database services
  - Run docker compose up
  - Verify both services are healthy and the app can connect to the database
