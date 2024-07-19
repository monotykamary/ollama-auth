Here's an updated README that includes information about the new code and environment variables, with backticks removed:

# Docker Image for Ollama Service with Basic Auth using Caddy Server

This project provides a Docker image that runs the Ollama service with basic authentication using the Caddy server. The image is designed to be easy to use, with a simple command to get started. The basic authentication credentials can be set using environment variables when running the Docker container.

## Usage:

To use this Docker image, you can run the following command:

```
docker run -p 8200:80 -e CADDY_API_KEY=apikey ghcr.io/monotykamary/ollama-auth:latest 
```

This will start a new Docker container using the ollama-auth image, and map port 8200 on the host machine to port 80 on the container. The basic authentication credentials can be set using the CADDY_API_KEY environment variable.

## Environment Variables:

The following environment variables can be used to configure the service:

- CADDY_API_KEY: The API key for basic authentication (required)
- DEFAULT_TIMEOUT: Default timeout in seconds for low traffic periods (default: 15)
- MAX_TIMEOUT: Maximum timeout in seconds for high traffic periods (default: 120)
- CONNECTION_THRESHOLD: Threshold for high traffic determination (default: 2)

## Building the Docker Image:

To build the Docker image yourself, you can use the following command:

```
docker build -t ollama-auth .
```

This will build the Docker image using the Dockerfile in the current directory, and tag it with the name ollama-auth.

## Running the Ollama Service:

The Ollama service is started automatically when the Docker container is launched. It will be available at http://localhost:8200 on the host machine.

## Automatic Shutdown:

The service includes an automatic shutdown feature to conserve resources during periods of inactivity. The shutdown behavior is controlled by the timeout and connection threshold settings, which can be adjusted using the environment variables mentioned above.

## Monitoring:

The service logs current connection status, including the number of current connections, maximum connections, and current timeout. This information can be useful for monitoring and debugging purposes.