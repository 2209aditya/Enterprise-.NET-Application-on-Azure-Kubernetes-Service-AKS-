# 🚀 Enterprise .NET Application on Azure Kubernetes Service (AKS)

[![.NET](https://img.shields.io/badge/.NET-8.0-512BD4?logo=dotnet)](https://dotnet.microsoft.com/)
[![Azure](https://img.shields.io/badge/Azure-AKS-0078D4?logo=microsoft-azure)](https://azure.microsoft.com/en-us/services/kubernetes-service/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.28+-326CE5?logo=kubernetes)](https://kubernetes.io/)
[![Jenkins](https://img.shields.io/badge/CI-Jenkins-D24939?logo=jenkins)](https://www.jenkins.io/)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

A production-ready, enterprise-grade CI/CD pipeline for deploying .NET applications to Azure Kubernetes Service with comprehensive security scanning, monitoring, and auto-scaling capabilities.

## 📋 Table of Contents

- [Architecture Overview](#-architecture-overview)
- [Features](#-features)
- [Prerequisites](#-prerequisites)
- [Quick Start](#-quick-start)
- [Infrastructure Setup](#️-infrastructure-setup)
- [Application Structure](#-application-structure)
- [CI/CD Pipeline](#-cicd-pipeline)
- [Security](#-security)
- [Monitoring](#-monitoring)
- [Troubleshooting](#-troubleshooting)
- [Contributing](#-contributing)

## 🏗️ Architecture Overview

```
Developer
    │
    ├──> GitHub (Code Repository)
    │
    ├──> Jenkins (Continuous Integration)
    │       ├── Build .NET Application
    │       ├── Run Unit Tests (xUnit)
    │       ├── SonarQube Code Analysis
    │       ├── OWASP Dependency Check
    │       ├── Trivy Container Scan
    │       └── Push to Azure Container Registry
    │
    └──> Azure DevOps (Continuous Deployment)
            ├── Helm Deployment
            ├── Azure Kubernetes Service (AKS)
            ├── Horizontal Pod Autoscaler
            ├── NGINX Ingress Controller
            └── Azure Key Vault Integration
```

## ✨ Features

- **Enterprise CI/CD Pipeline** - Automated build, test, and deployment
- **Security First** - Multi-layer security scanning (SonarQube, OWASP, Trivy)
- **Auto-scaling** - HPA for dynamic workload management
- **Secret Management** - Azure Key Vault integration
- **High Availability** - Multi-node AKS cluster with load balancing
- **Monitoring** - Azure Monitor and Application Insights
- **Infrastructure as Code** - Fully automated Azure resource provisioning

## 🔧 Prerequisites

Before you begin, ensure you have the following installed:

- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) (>= 2.50.0)
- [kubectl](https://kubernetes.io/docs/tasks/tools/) (>= 1.28)
- [Helm](https://helm.sh/docs/intro/install/) (>= 3.12)
- [Docker](https://docs.docker.com/get-docker/) (>= 24.0)
- [.NET SDK](https://dotnet.microsoft.com/download) (>= 8.0)
- Jenkins Server with plugins:
  - Docker Pipeline
  - Kubernetes
  - SonarQube Scanner
  - Azure CLI
- Azure DevOps account with service connection
- Active Azure Subscription

## 🚀 Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/your-org/dotnet-aks-app.git
cd dotnet-aks-app
```

### 2. Login to Azure

```bash
az login
az account set --subscription "YOUR_SUBSCRIPTION_ID"
```

### 3. Run Infrastructure Setup

```bash
chmod +x scripts/setup-infrastructure.sh
./scripts/setup-infrastructure.sh
```

### 4. Deploy Application

```bash
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl apply -f k8s/ingress.yaml
kubectl apply -f k8s/hpa.yaml
```

## 🏗️ Infrastructure Setup

### Step 1: Create Resource Group

```bash
az group create \
  --name rg-dotnet-aks-prod \
  --location eastus
```

### Step 2: Create Virtual Network

```bash
az network vnet create \
  --resource-group rg-dotnet-aks-prod \
  --name aks-vnet \
  --address-prefix 10.0.0.0/16 \
  --subnet-name aks-subnet \
  --subnet-prefix 10.0.1.0/24
```

### Step 3: Create Azure Container Registry

```bash
az acr create \
  --resource-group rg-dotnet-aks-prod \
  --name dotnetacrprod \
  --sku Premium \
  --admin-enabled false
```

### Step 4: Create Azure Key Vault

```bash
az keyvault create \
  --name kv-dotnet-prod \
  --resource-group rg-dotnet-aks-prod \
  --location eastus
```

**Store Application Secrets:**

```bash
az keyvault secret set \
  --vault-name kv-dotnet-prod \
  --name DbConnectionString \
  --value "Server=sql;User=app;Password=YourSecurePassword"
```

### Step 5: Create AKS Cluster

```bash
# Get subnet ID
SUBNET_ID=$(az network vnet subnet show \
  --resource-group rg-dotnet-aks-prod \
  --vnet-name aks-vnet \
  --name aks-subnet \
  --query id -o tsv)

# Create AKS cluster
az aks create \
  --resource-group rg-dotnet-aks-prod \
  --name dotnet-aks \
  --node-count 3 \
  --node-vm-size Standard_D4s_v5 \
  --network-plugin azure \
  --vnet-subnet-id $SUBNET_ID \
  --enable-managed-identity \
  --enable-addons monitoring \
  --enable-azure-policy \
  --enable-cluster-autoscaler \
  --min-count 3 \
  --max-count 6 \
  --attach-acr dotnetacrprod
```

### Step 6: Connect to AKS

```bash
az aks get-credentials \
  --resource-group rg-dotnet-aks-prod \
  --name dotnet-aks
```

### Step 7: Install NGINX Ingress Controller

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

helm install nginx-ingress ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.replicaCount=2
```

## 📦 Application Structure

```
dotnet-aks-app/
├── src/
│   ├── DotNetApp/
│   │   ├── Controllers/
│   │   ├── Models/
│   │   ├── Services/
│   │   └── Program.cs
│   └── DotNetApp.Tests/
│       └── UnitTests.cs
├── k8s/
│   ├── namespace.yaml
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── ingress.yaml
│   ├── hpa.yaml
│   └── secrets.yaml
├── helm/
│   ├── Chart.yaml
│   ├── values.yaml
│   └── templates/
├── Dockerfile
├── Jenkinsfile
├── azure-pipelines.yml
└── README.md
```

### Dockerfile

```dockerfile
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS runtime
WORKDIR /app
COPY publish/ .
ENTRYPOINT ["dotnet", "DotNetApp.dll"]
```

## 🔄 CI/CD Pipeline

### Jenkins CI Pipeline

The Jenkins pipeline performs the following stages:

1. **Checkout** - Clone source code from GitHub
2. **Restore & Build** - Restore dependencies and build the application
3. **Unit Tests** - Run xUnit tests with code coverage
4. **SonarQube Scan** - Static code analysis
5. **OWASP Dependency Check** - Scan for vulnerable dependencies
6. **Docker Build** - Build container image
7. **Trivy Scan** - Scan container for vulnerabilities
8. **Push to ACR** - Push image to Azure Container Registry

**Jenkinsfile:**

```groovy
pipeline {
  agent any

  tools {
    dotnet 'dotnet8'
  }

  environment {
    ACR = "dotnetacrprod.azurecr.io"
    IMAGE = "dotnet-app"
    TAG = "${BUILD_NUMBER}"
  }

  stages {
    stage('Checkout') {
      steps {
        git 'https://github.com/org/dotnet-app.git'
      }
    }

    stage('Restore & Build') {
      steps {
        sh 'dotnet restore'
        sh 'dotnet build --no-restore'
      }
    }

    stage('Unit Tests (xUnit)') {
      steps {
        sh 'dotnet test --collect:"XPlat Code Coverage"'
      }
    }

    stage('SonarQube Scan') {
      steps {
        withSonarQubeEnv('sonarqube') {
          sh '''
          dotnet sonarscanner begin /k:"dotnet-app"
          dotnet build
          dotnet sonarscanner end
          '''
        }
      }
    }

    stage('OWASP Dependency Check') {
      steps {
        sh 'dependency-check.sh --scan .'
      }
    }

    stage('Docker Build') {
      steps {
        sh '''
        dotnet publish -c Release -o publish
        docker build -t $ACR/$IMAGE:$TAG .
        '''
      }
    }

    stage('Trivy Scan') {
      steps {
        sh 'trivy image $ACR/$IMAGE:$TAG'
      }
    }

    stage('Push Image') {
      steps {
        sh 'docker push $ACR/$IMAGE:$TAG'
      }
    }
  }
}
```

### Azure DevOps CD Pipeline

**azure-pipelines.yml:**

```yaml
trigger: none

stages:
- stage: Deploy
  jobs:
  - job: AKS_Deploy
    pool:
      vmImage: ubuntu-latest
    steps:

    - task: HelmInstaller@1
      inputs:
        helmVersionToInstall: latest

    - task: AzureCLI@2
      inputs:
        azureSubscription: 'Azure-Prod'
        scriptType: bash
        scriptLocation: inlineScript
        inlineScript: |
          az aks get-credentials \
            --resource-group rg-dotnet-aks-prod \
            --name dotnet-aks

    - script: |
        helm upgrade --install dotnet-app ./helm \
          --namespace dotnet-prod \
          --set image.tag=$(Build.BuildId)
      displayName: 'Deploy to AKS'
```

## 🔒 Security

Our security approach follows defense-in-depth principles with multiple layers:

| Layer | Tool | Purpose |
|-------|------|---------|
| **Code Quality** | SonarQube | Detect bugs, code smells, and vulnerabilities |
| **Dependencies** | OWASP Dependency Check | Identify vulnerable libraries and packages |
| **Container Image** | Trivy | Scan for CVEs in container images |
| **Secrets Management** | Azure Key Vault | Secure storage of sensitive data |
| **Cluster Security** | Azure Policy | Enforce security standards and compliance |
| **Network Security** | NSG + Private AKS | Restrict network access |
| **Access Control** | RBAC | Least privilege principle |

### Key Security Features

- **No Secrets in Git** - All sensitive data stored in Azure Key Vault
- **Image Scanning** - Every container image scanned before deployment
- **Network Isolation** - Private AKS cluster with NSG rules
- **Pod Security** - Security contexts and policies enforced
- **Automated Scanning** - Security checks in every CI build

## 📊 Monitoring

### Azure Monitor for Containers

```bash
# Enable monitoring addon
az aks enable-addons \
  --resource-group rg-dotnet-aks-prod \
  --name dotnet-aks \
  --addons monitoring
```

### Application Insights

Add to your `appsettings.json`:

```json
{
  "ApplicationInsights": {
    "InstrumentationKey": "YOUR_INSTRUMENTATION_KEY"
  }
}
```

### Key Metrics Monitored

- CPU and Memory utilization
- Request rate and latency
- Error rates and exceptions
- Pod health and restarts
- Node resource usage
- Network traffic patterns

### Prometheus + Grafana (Optional)

```bash
# Install Prometheus
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace

# Access Grafana
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
```

## 🔧 Troubleshooting

### Common Issues

**Issue: Pods stuck in ImagePullBackOff**

```bash
# Check ACR authentication
az aks update \
  --resource-group rg-dotnet-aks-prod \
  --name dotnet-aks \
  --attach-acr dotnetacrprod
```

**Issue: Application not accessible via Ingress**

```bash
# Check ingress controller
kubectl get pods -n ingress-nginx
kubectl logs -n ingress-nginx <ingress-controller-pod>

# Check ingress resource
kubectl describe ingress dotnet-ingress -n dotnet-prod
```

**Issue: High CPU/Memory usage**

```bash
# Check resource usage
kubectl top pods -n dotnet-prod
kubectl top nodes

# Scale deployment manually
kubectl scale deployment dotnet-app -n dotnet-prod --replicas=5
```

### Useful Commands

```bash
# View pod logs
kubectl logs -f deployment/dotnet-app -n dotnet-prod

# Execute into pod
kubectl exec -it <pod-name> -n dotnet-prod -- /bin/bash

# Check HPA status
kubectl get hpa -n dotnet-prod

# View events
kubectl get events -n dotnet-prod --sort-by='.lastTimestamp'
```

## 🤝 Contributing

We welcome contributions! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Code Standards

- Follow C# coding conventions
- Write unit tests for new features
- Update documentation as needed
- Ensure all CI checks pass

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👥 Authors

- **Your Name** - *Initial work* - [YourGitHub](https://github.com/yourusername)

## 🙏 Acknowledgments

- Microsoft Azure Documentation
- Kubernetes Community
- .NET Foundation
- Jenkins Community

## 📞 Support

For support and questions:

- 📧 Email: support@yourcompany.com
- 💬 Slack: [Join our workspace](https://yourslack.slack.com)
- 🐛 Issues: [GitHub Issues](https://github.com/your-org/dotnet-aks-app/issues)

---

**Built with ❤️ by the DevOps Team**
