# Container Compose

A Swift-based alternative to Docker Compose that translates `docker-compose.yml` files into `container` command executions. This tool provides a lightweight way to manage multi-container applications using the `container` CLI instead of Docker.

## Features

- **Full docker-compose.yml parsing**: Supports most Docker Compose file format features
- **Environment variable resolution**: Handles `.env` files and variable substitution (`${VAR:-default}`, `${VAR:?error}`)
- **Network management**: Creates and manages custom networks
- **Volume management**: Creates named volumes and handles bind mounts
- **Service orchestration**: Builds images and runs containers with proper configuration
- **Build support**: Handles `build` contexts with Dockerfile and build arguments
- **Comprehensive logging**: Detailed output for debugging and monitoring

## Supported Docker Compose Features

### ✅ Fully Supported
- **Services**: Image, build, environment, volumes, networks, ports, restart policies
- **Networks**: Custom networks with drivers and configuration
- **Volumes**: Named volumes and bind mounts
- **Environment**: `.env` files, environment variables, variable substitution
- **Build**: Build contexts, Dockerfiles, build arguments
- **Container Configuration**: User, hostname, working directory, privileged mode, read-only

### ⚠️ Parsed but Limited Support
- **Configs**: Parsed but not attached to containers (Swarm-specific feature)
- **Secrets**: Parsed but not attached to containers (Swarm-specific feature)
- **Deploy**: Parsed but orchestration features not implemented

### ❌ Not Supported
- **Port mappings**: The `container` tool doesn't support `-p` flag
- **Restart policies**: Not supported by `container run`
- **Healthchecks**: Parsed but not implemented
- **Dependencies**: `depends_on` is parsed but startup order not enforced
- **Volumns**: Works well when mapping to a directory, but compose does not support mapping directly to a file presently
  
## Installation

### Prerequisites
- Swift 5.0 or later
- `container` CLI tool installed and available in PATH
- Yams Swift YAML library

### Build from Source
```bash
# Clone the repository
git clone <repository-url>
cd container-compose

# Add Yams dependency to Package.swift
swift package add-dependency https://github.com/jpsim/Yams.git

# Build the executable
swift build -c release

# Copy to PATH (optional)
cp .build/release/container-compose /usr/local/bin/
```

## Usage

### Basic Usage
```bash
# Navigate to directory containing docker-compose.yml
cd /path/to/your/project

# Start services (equivalent to docker-compose up)
container-compose up

# Start services in detached mode
container-compose up -d
```

### Project Structure
```
your-project/
├── docker-compose.yml
├── .env (optional)
├── Dockerfile (if using build)
└── other-files/
```

### Example docker-compose.yml
```yaml
version: '3.8'
name: my-project

services:
  web:
    build: .
    environment:
      - NODE_ENV=production
      - DATABASE_URL=${DATABASE_URL:-postgresql://localhost/myapp}
    volumes:
      - ./src:/app/src
      - web-data:/app/data
    networks:
      - app-network
    depends_on:
      - db

  db:
    image: postgres:13
    environment:
      POSTGRES_DB: myapp
      POSTGRES_PASSWORD: ${DB_PASSWORD:?Database password required}
    volumes:
      - db-data:/var/lib/postgresql/data
    networks:
      - app-network

volumes:
  web-data:
  db-data:

networks:
  app-network:
    driver: bridge
```

### Environment Variables
Create a `.env` file in the same directory as your `docker-compose.yml`:

```env
DATABASE_URL=postgresql://localhost/myapp_dev
DB_PASSWORD=supersecret
NODE_ENV=development
```

## Command Line Options

```bash
container-compose up [-d]
```

**Options:**
- `-d, --detach`: Run containers in the background (detached mode)

**Currently supported subcommands:**
- `up`: Create and start containers

## How It Works

1. **Parse**: Reads and validates `docker-compose.yml` using Swift's Codable and Yams
2. **Environment**: Loads variables from `.env` files and resolves substitutions
3. **Networks**: Creates custom networks defined in the compose file
4. **Volumes**: Creates named volumes defined in the compose file
5. **Build**: Builds images for services with build configurations
6. **Run**: Executes `container run` commands for each service with appropriate flags

## Configuration Details

### Environment Variable Resolution
Supports Docker Compose variable substitution syntax:
- `${VARIABLE}` - Simple substitution
- `${VARIABLE:-default}` - Use default if variable is unset
- `${VARIABLE:?error message}` - Exit with error if variable is unset

### Volume Handling
- **Named volumes**: Creates volumes using `container volume create`
- **Bind mounts**: Maps host directories to container paths
- **Auto-creation**: Creates missing host directories for bind mounts

### Network Management
- **Custom networks**: Creates networks with specified drivers and options
- **External networks**: References existing networks without creating them
- **Default behavior**: Services without explicit networks use default bridge network

### Build Process
- **Context**: Supports build contexts and custom Dockerfiles
- **Arguments**: Passes build arguments with variable resolution
- **Tagging**: Uses service image name or generates default tags

## Limitations

This tool is designed to work with the `container` CLI, which has some limitations compared to Docker:

1. **No port mapping**: The `-p` flag is not supported by `container run`
2. **No restart policies**: Automatic restart is not available
3. **No healthchecks**: Health monitoring is not implemented
4. **No dependency ordering**: Services start independently
5. **Limited Swarm features**: Configs and secrets are parsed but not used

## Troubleshooting

### Common Issues

**Error: docker-compose.yml not found**
```bash
# Ensure you're in the correct directory
ls -la docker-compose.yml
```

**Error: Missing required environment variable**
```bash
# Check your .env file or export the variable
export REQUIRED_VAR=value
```

**Error: Container command not found**
```bash
# Ensure container CLI is installed and in PATH
which container
```

**Build failures**
```bash
# Check build context and Dockerfile paths
# Ensure all build dependencies are available
```

### Debugging
The tool provides verbose output showing:
- Parsed configuration values
- Environment variable resolution
- Network and volume creation
- Exact `container` commands being executed

## Development

### Project Structure
```
container-compose/
├── Sources/
│   └── main.swift          # Main application logic
├── Package.swift           # Swift package configuration
└── README.md              # This file
```

### Key Components
- **DockerCompose struct**: Represents the complete compose file structure
- **Service struct**: Individual service configuration
- **Environment resolution**: Variable substitution logic
- **Command execution**: Interface to `container` CLI

### Contributing
1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Submit a pull request

## License
MIT

## Acknowledgments

- Built with Swift and the Yams YAML parsing library
- Inspired by Docker Compose's functionality
- Designed for use with Apples Container runtime that provide a Docker-(Semi)compatible CLI
