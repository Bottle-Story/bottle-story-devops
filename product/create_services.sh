#!/bin/bash

# Define services array
services=("bottlesv" "realtime" "wheatherbgm" "batch" "frontend")

# Define service specific configurations
declare -A service_configs
service_configs["bottlesv"]="bottle"
service_configs["realtime"]="realtime"  
service_configs["wheatherbgm"]="weather"
service_configs["batch"]="batch"
service_configs["frontend"]="frontend"

# Define port mappings
declare -A service_ports
service_ports["bottlesv"]="8080"
service_ports["realtime"]="8080"
service_ports["wheatherbgm"]="8080" 
service_ports["batch"]="8080"
service_ports["frontend"]="3000"

for service in "${services[@]}"; do
    echo "Creating configuration for $service..."
    
    component=${service_configs[$service]}
    port=${service_ports[$service]}
    
    # Create Chart.yaml
    cat > "/Users/kimyj/bottle-story/bottle-story-devops/product/$service/helm/Chart.yaml" << CHART_EOF
apiVersion: v2
name: bottle-story-$component-prod
description: Bottle Story $component Service for Production Environment
type: application
version: 1.0.0
appVersion: "1.0.0"
keywords:
  - bottle-story
  - $component
  - microservice
  - production
home: https://bottle-story.com
sources:
  - https://github.com/Bottle-Story/bottle-story-$service
maintainers:
  - name: DevOps Team
    email: devops@bottle-story.com
CHART_EOF

    # Create values-prod.yaml
    cat > "/Users/kimyj/bottle-story/bottle-story-devops/product/$service/helm/values-prod.yaml" << VALUES_EOF
namespace: bottle-story-prod

image:
  repository: \${AWS_ACCOUNT_ID}.dkr.ecr.ap-northeast-2.amazonaws.com/bottle-story/$component
  tag: latest
  pullPolicy: Always

replicaCount: 2

labels:
  part-of: bottle-story-backend
  component: $component-service
  name: $component-service-pod
  instance: $component-service-prod
  version: "1.0.0"
  managedBy: helm
  environment: production

containerPort: $port

resources:
  limits:
    memory: "1Gi"
    cpu: "800m"
  requests:
    memory: "512Mi"
    cpu: "400m"

readinessPath: /actuator/health/readiness
livenessPath: /actuator/health/liveness

envFrom:
  configMap: $component-service-config
  secret: $component-service-secret

service:
  name: $component-service
  port: 80
  targetPort: $port
  type: ClusterIP

hpa:
  enabled: true
  name: $component-service-hpa
  targetDeployment: $component-service-deployment
  minReplicas: 2
  maxReplicas: 8
  cpuUtilization: 70
  memoryUtilization: 80
VALUES_EOF

    echo "Created configuration for $service successfully!"
done

echo "All service configurations created!"
