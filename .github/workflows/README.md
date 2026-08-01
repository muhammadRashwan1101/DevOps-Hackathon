# BackBenchers-Mini — Self-Hosted Minikube DevOps Pipeline on AWS EC2

A complete educational DevOps project that provisions an AWS EC2 instance with Terraform, runs a local Minikube Kubernetes cluster on it, deploys a containerized Node.js/Express application, and automates the build process with GitHub Actions.

## Architecture

Developer → GitHub Repo → GitHub Actions (CI)
│
▼
Build Docker Image
(optional push to Docker Hub)

AWS Cloud
└── VPC
└── Public Subnet
└── EC2 Instance (Ubuntu 24.04, t2.medium)
├── Docker Engine
├── kubectl
├── Minikube (single-node cluster)
│ └── Namespace: BackBenchers
│ ├── ConfigMap
│ ├── Secret
│ ├── Deployment (2 replicas)
│ └── Service (NodePort)
└── Security Group (22, 80, 443, 30000-32767)

End User Browser ──► http://<EC2_PUBLIC_IP>:<NodePort> ──► Application


Terraform provisions the networking and compute layer. The EC2 instance bootstraps itself on first boot with Docker, kubectl, and Minikube. Kubernetes manifests are applied manually (or via SSH script) once the instance is ready. GitHub Actions builds the Docker image on every push to `main` and optionally pushes it to Docker Hub if credentials are configured as repository secrets.

## Repository Structure

project/
├── terraform/
│ ├── provider.tf
│ ├── variables.tf
│ ├── main.tf
│ ├── network.tf
│ ├── security_group.tf
│ ├── ec2.tf
│ ├── outputs.tf
│ └── user_data.sh
├── app/
│ ├── server.js
│ ├── package.json
│ ├── Dockerfile
│ └── .dockerignore
├── kubernetes/
│ ├── namespace.yaml
│ ├── configmap.yaml
│ ├── secret.yaml
│ ├── deployment.yaml
│ └── service.yaml
├── .github/workflows/
│ └── ci.yml
└── README.md


## Prerequisites

- An AWS account with billing enabled (this project creates real, billable resources: EC2 `t2.medium`, EBS volume, VPC networking)
- Terraform CLI installed locally
- AWS credentials configured locally (`aws configure` or environment variables)
- An existing EC2 key pair in your target AWS region
- Git installed locally

## Deployment

### 1. Terraform

```bash
cd terraform
terraform init
terraform plan -var="key_name=<your-key-pair-name>"
terraform apply -var="key_name=<your-key-pair-name>"
```

Retrieve the outputs once the apply completes:

```bash
terraform output instance_public_ip
terraform output ssh_connection_string
```

SSH into the instance:

```bash
ssh -i /path/to/your-key.pem ubuntu@<instance_public_ip>
```

The bootstrap script runs automatically via EC2 user data on first boot. Confirm it finished successfully:

```bash
cat /var/log/bootstrap.log
```

Look for the line `=== Bootstrap completed at <timestamp> ===` at the end of the log.

### 2. Docker

Clone the repository onto the instance and point Docker at Minikube's internal daemon so the image you build is immediately usable by the cluster:

```bash
git clone <your-repo-url>
cd <your-repo-name>/app

eval $(minikube docker-env)
docker build -t BackBenchers-app:latest .
docker images
```

### 3. Kubernetes

Apply the manifests in order from the `kubernetes/` directory:

```bash
cd ../kubernetes
kubectl apply -f namespace.yaml
kubectl apply -f configmap.yaml
kubectl apply -f secret.yaml
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
```

Confirm the rollout succeeded:

```bash
kubectl rollout status deployment/BackBenchers-deployment -n BackBenchers
```

## Verification

Run through each command below and confirm the expected result:

```bash
minikube status
kubectl get nodes
kubectl get pods -n BackBenchers
kubectl get svc -n BackBenchers
```

Retrieve the NodePort assigned to the service:

```bash
kubectl get svc BackBenchers-service -n BackBenchers -o jsonpath='{.spec.ports[0].nodePort}'
```

Open the application in a browser:

http://<instance_public_ip>:<nodePort>/


You should see a page welcoming you to the app name defined in the ConfigMap.

Check the health endpoint:

```bash
curl http://<instance_public_ip>:<nodePort>/health
```

Expected response:

```json
{ "status": "ok" }
```

## GitHub Actions CI

The workflow defined in `.github/workflows/ci.yml` triggers on every push to `main`. It checks out the code, sets up Node.js, installs dependencies, and builds the Docker image. If the repository secrets `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN` are configured, it additionally logs in and pushes the image to Docker Hub, tagged with both the commit SHA and `latest`. If those secrets are not set, the push steps are skipped and the workflow still completes successfully.

## Cleanup

Remove all Kubernetes resources:

```bash
kubectl delete namespace BackBenchers
```

Stop and delete the Minikube cluster:

```bash
minikube stop
minikube delete
```

Destroy all AWS infrastructure:

```bash
cd terraform
terraform destroy -var="key_name=<your-key-pair-name>"
```

**Note:** This project does not create an Elastic IP by default, so no additional billable resources persist once `terraform destroy` completes. Confirm in the AWS Console that the EC2 instance, VPC, and security group have all been removed.

## Screenshots

Capture and insert the following screenshots here to document a successful deployment:

- `terraform apply` completing successfully with outputs displayed
- SSH session connected to the EC2 instance
- `docker ps` / `docker images` output on the instance
- `minikube status` output showing `Running`
- `kubectl get nodes` output showing the node `Ready`
- `kubectl get pods -n BackBenchers` output showing 2/2 pods `Running`
- `kubectl get svc -n BackBenchers` output showing the NodePort service
- The application homepage open in a browser, showing the configured `APP_NAME`
- A successful GitHub Actions workflow run

## Validation Checklist

- [ ] `terraform apply` completes with no errors and produces all outputs
- [ ] SSH access to the EC2 instance succeeds
- [ ] `docker ps` works without `sudo` as the `ubuntu` user
- [ ] `minikube status` reports `Running`
- [ ] `kubectl get nodes` shows the node in `Ready` state
- [ ] `kubectl get pods -n BackBenchers` shows 2/2 pods `Running`
- [ ] `kubectl get svc -n BackBenchers` shows the NodePort service with an assigned port
- [ ] The application is reachable via `http://<instance_public_ip>:<nodePort>/`
- [ ] `/health` returns a successful JSON response
- [ ] The GitHub Actions workflow completes successfully on push