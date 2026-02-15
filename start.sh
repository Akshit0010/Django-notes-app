#!/bin/bash

set -e

echo "=========================================="
echo "Django Notes App - Quick Start Script"
echo "=========================================="
echo ""

if [ ! -f .env ]; then
    echo "Creating .env file from .env.example..."
    cp .env.example .env
    echo "Please edit .env file with your configurations before continuing."
    echo "Press Enter after editing .env file..."
    read
fi

echo "Building Docker images..."
docker-compose build

echo ""
echo "Starting containers..."
docker-compose up -d

echo ""
echo "Waiting for services to be ready..."
sleep 10

echo ""
echo "=========================================="
echo "Setup Complete!"
echo "=========================================="
echo ""
echo "Application is running at: http://localhost"
echo "Django Admin: http://localhost/admin"
echo ""
echo "Default admin credentials:"
echo "  Username: admin"
echo "  Password: admin123"
echo ""
echo "IMPORTANT: Change the admin password after first login!"
echo ""
echo "Useful commands:"
echo "  View logs: docker-compose logs -f"
echo "  Stop app: docker-compose down"
echo "  Restart: docker-compose restart"
echo ""
