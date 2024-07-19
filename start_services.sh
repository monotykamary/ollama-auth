#!/bin/bash

# Function to start Ollama and Caddy services
start_services() {
    echo "Starting services..."
    ollama serve &
    OLLAMA_PID=$!
    caddy run --config /etc/caddy/Caddyfile &
    CADDY_PID=$!
}

# Function to stop Ollama and Caddy services
stop_services() {
    echo "Stopping services..."
    if [ ! -z "$OLLAMA_PID" ]; then
        kill $OLLAMA_PID
        wait $OLLAMA_PID 2>/dev/null
    fi
    if [ ! -z "$CADDY_PID" ]; then
        kill $CADDY_PID
        wait $CADDY_PID 2>/dev/null
    fi
    OLLAMA_PID=""
    CADDY_PID=""
}

# Function to check the number of current connections
check_connections() {
    netstat -tn | grep :80 | grep ESTABLISHED | wc -l
}

# Configuration variables from environment variables with defaults
DEFAULT_TIMEOUT=${DEFAULT_TIMEOUT:-15}    # Default timeout in seconds for low traffic periods
MAX_TIMEOUT=${MAX_TIMEOUT:-120}           # Maximum timeout in seconds for high traffic periods
CONNECTION_THRESHOLD=${CONNECTION_THRESHOLD:-2}  # Threshold for high traffic determination

CURRENT_TIMEOUT=$DEFAULT_TIMEOUT
LAST_CONNECTION_TIME=$(date +%s)
MAX_CONNECTIONS=0
PREV_CONNECTIONS=0
PREV_MAX_CONNECTIONS=0
PREV_TIMEOUT=$CURRENT_TIMEOUT

# Set up trap to handle shutdown signals
trap "stop_services; exit 0" SIGTERM SIGINT

# Start the services
start_services

# Function to log status if there's a change
log_status() {
    if [ $CURRENT_CONNECTIONS != $PREV_CONNECTIONS ] || 
       [ $MAX_CONNECTIONS != $PREV_MAX_CONNECTIONS ] || 
       [ $CURRENT_TIMEOUT != $PREV_TIMEOUT ]; then
        echo "Current connections: $CURRENT_CONNECTIONS, Max connections: $MAX_CONNECTIONS, Current timeout: $CURRENT_TIMEOUT seconds"
        PREV_CONNECTIONS=$CURRENT_CONNECTIONS
        PREV_MAX_CONNECTIONS=$MAX_CONNECTIONS
        PREV_TIMEOUT=$CURRENT_TIMEOUT
    fi
}

# Main loop
while true; do
    CURRENT_TIME=$(date +%s)
    CURRENT_CONNECTIONS=$(check_connections)
    
    if [ $CURRENT_CONNECTIONS -gt 0 ]; then
        # Update last connection time
        LAST_CONNECTION_TIME=$CURRENT_TIME
        
        # Update max connections
        if [ $CURRENT_CONNECTIONS -gt $MAX_CONNECTIONS ]; then
            MAX_CONNECTIONS=$CURRENT_CONNECTIONS
        fi
        
        # Update timeout based on max connections
        if [ $MAX_CONNECTIONS -ge $CONNECTION_THRESHOLD ]; then
            CURRENT_TIMEOUT=$MAX_TIMEOUT
        else
            CURRENT_TIMEOUT=$DEFAULT_TIMEOUT
        fi
        
        # Log current status if there's a change
        log_status
    elif [ $((CURRENT_TIME - LAST_CONNECTION_TIME)) -ge $CURRENT_TIMEOUT ]; then
        # If inactive for longer than the current timeout, initiate shutdown
        echo "No activity for $CURRENT_TIMEOUT seconds. Attempting to signal machine shutdown..."
        stop_services
        
        echo "Exiting container with special exit code to signal shutdown"
        exit 78  # Special exit code to signal Fly.io for machine shutdown
    fi
    
    # Wait for 1 second before the next check
    sleep 1
done