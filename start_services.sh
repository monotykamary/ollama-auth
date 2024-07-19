#!/bin/bash

start_services() {
    echo "Starting services..."
    ollama serve &
    OLLAMA_PID=$!
    caddy run --config /etc/caddy/Caddyfile &
    CADDY_PID=$!
}

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

check_connections() {
    netstat -tn | grep :11434 | grep ESTABLISHED | wc -l
}

INACTIVITY_TIMEOUT=60
LAST_CONNECTION_TIME=$(date +%s)
SERVICES_RUNNING=false

trap "stop_services; exit 0" SIGTERM SIGINT

while true; do
    CURRENT_TIME=$(date +%s)
    
    if [ "$SERVICES_RUNNING" = false ]; then
        start_services
        SERVICES_RUNNING=true
        LAST_CONNECTION_TIME=$CURRENT_TIME
    else
        CURRENT_CONNECTIONS=$(check_connections)
        
        if [ $CURRENT_CONNECTIONS -gt 0 ]; then
            LAST_CONNECTION_TIME=$CURRENT_TIME
        elif [ $((CURRENT_TIME - LAST_CONNECTION_TIME)) -ge $INACTIVITY_TIMEOUT ]; then
            echo "No activity for $INACTIVITY_TIMEOUT seconds. Performing soft shutdown..."
            stop_services
            SERVICES_RUNNING=false
        fi
    fi
    
    sleep 10
done