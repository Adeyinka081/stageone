# StageOne DevOps Deployment

This repository contains the **deployment script (`deploy.sh`)** for automating the setup of a Python web application using Docker and Nginx.  
The script performs the following tasks:

1. Collects deployment parameters (Git repository URL, branch, app port, optional PAT & SSH details).  
2. Installs and configures **Docker**, **Docker Compose**, and **Nginx**.  
3. Clones or updates the application from the specified Git repository.  
4. Builds the Docker image for the app.  
5. Runs the Docker container.  
6. Configures Nginx as a reverse proxy to route traffic to the app.  
7. Cleans up old containers, images, and build caches.  
8. Validates that the app and Nginx service are running.  
9. Logs all deployment actions for troubleshooting.  
