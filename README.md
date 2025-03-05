# **Project "RTSP-Recorder-to-Cloud" – Terraform & Ansible Configuration**

This document describes how to deploy AWS infrastructure and configure servers using Terraform and Ansible. It also explains how to automate deployment processes through GitHub Actions. The project includes creating a **VPC, EC2 instances (Bastion, Nginx, and RTSP), IAM configuration, and S3 storage** for Terraform state and RTSP recordings.

---

## **1. Architecture and Repository Structure**

### **Architecture Diagram**

![Architecture_Map](https://github.com/user-attachments/assets/2ec03282-3c38-48ab-9804-461ea19020a6)

### **Repository Structure**

```
.
├── .github
│   └── workflows
│       ├── terraform-deploy.yml
│       └── ansible-deploy.yml
├── ansible
│   ├── roles
│   │   ├── bastion         # Bastion setup: Fail2Ban, package updates, SSH
│   │   ├── nginx           # Nginx configuration as a reverse proxy for RTSP
│   │   └── rtsp            # Deployment of RTSP application (RTSPtoWeb + RTSP Recorder) with Docker
│   ├── group_vars
│   │   ├── all.yaml
│   │   └── role_bastion.yaml
│   ├── aws_ec2.yaml        # Dynamic Ansible inventory for AWS
│   ├── ansible.cfg         # Main Ansible configuration (inventory, SSH, etc.)
│   └── playbook.yaml       # Main playbook running all roles
└── terraform
    ├── main.tf            # Terraform code for infrastructure deployment
    ├── variables.tf       # Terraform variables
    ├── outputs.tf         # Outputs (e.g., IP addresses)
    └── backend.tf         # Backend configuration for storing tfstate in S3
```

---

## **2. Main Components**

### **GitHub Actions**

- **CI/CD Automation:**
    - Workflow for Terraform deployment (`terraform-deploy.yml`).
    - Workflow for Ansible server setup (`ansible-deploy.yml`).

### **Terraform**

- **Network Resources:**
    - Creates a VPC with public and private subnets.
    - Configures Security Groups, Internet Gateway, NAT Gateway, and Route Tables.
- **EC2 Instances:**
    - **Bastion:** Allows SSH access to private instances.
    - **Nginx:** Works as a reverse proxy.
    - **RTSP:** Handles video stream processing.
- **IAM and S3:**
    - Creates IAM roles and Instance Profiles for S3 upload.
    - Stores Terraform state (`terraform.tfstate`) in S3.

### **Ansible**

- **Playbook `playbook.yaml`:**
    - Runs the roles **bastion**, **nginx**, and **rtsp**.
- **Dynamic Inventory (`aws_ec2.yaml`):**
    - Automatically collects AWS hosts based on the `role` tag.
- **Configuration (`ansible.cfg`):**
    - Defines inventory paths, SSH parameters, and other settings.

---

## **3. Environment Setup**

### **3.1 Fork the repository**

To start using this project, you need to create your own copy of the repository.

Steps to Fork the Repository:
- Click the **"Fork"** button in the top-right corner of the page.
- Wait for GitHub to create a copy of the repository under your account.

### **3.2 Creating S3 Buckets in AWS**

Create two **S3 buckets**:

- **Terraform state bucket** (`S3_TFSTATE_BUCKET`): Stores `.tfstate` file to track infrastructure changes.
- **RTSP recordings and logs bucket** (`S3_BUCKET_NAME`): Used for storing RTSP video recordings.

### **3.3 Setting Up GitHub Secrets and Variables**

Go to your forked repository on GitHub.
Navigate to **Settings** > **Secrets and variables** > **Actions**.

#### **Secrets (Sensitive Data):**

- `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` – AWS credentials.
- `RTSP_URL_1` / `RTSP_URL_2` – RTSP stream URLs from cameras.
- `SSH_PRIVATE_KEY` – Private SSH key for server access.

#### **Variables (Environment Settings):**

**General Settings:**

- `ANSIBLE_USER=ubuntu` – Username on servers.
- `AWS_REGION=eu-central-1` – AWS region.
- `AVAILABILITY_ZONE=eu-central-1a` – Availability zone.
- `TZ=Europe/Warsaw` – Timezone.

**EC2 and Infrastructure:**

- `AWS_INSTANCE=ami-07eef52105e8a2059` – AMI for EC2 instances.
- `INSTANCE_TYPE=t2.micro` – Instance type for Bastion and Nginx.
- `INSTANCE_TYPE_RTSP=t2.micro` – Instance type for RTSP.

**Video Recording Configuration:**

- `NUM_CAMERAS=2` – Number of cameras.
- `RECORD_DURATION=20` – Recording duration (in seconds).
- `MAX_BUFFER_SIZE=5` – Maximum number of recordings in the buffer.

**S3 Storage:**

- `S3_BUCKET_NAME=your-s3-bucket-for-records` – Bucket for video recordings.
- `S3_TFSTATE_BUCKET=your-s3-bucket-for-tfstate` – Bucket for Terraform state.

**SSH:**

- `SSH_PUBLIC_KEY=your-ssh-public-key` – Public SSH key for servers.

---

## **4. Cloud Deployment**

### **4.1 Running Terraform via GitHub Actions**

**Triggers:**

- **Automatic** execution when pushing changes to the `terraform/` folder (master branch).
- **Manual** execution via the GitHub Actions interface.

**Steps:**

1. **Checkout repository** – Clones the code.
2. **Install Terraform** – Sets up the required Terraform version.
3. **Initialize Backend** – Runs `terraform init` with S3 settings.
4. **Apply Changes** – Executes `terraform apply -auto-approve`, creating or updating resources.
5. **Display IP Addresses** – Outputs public and private IPs of created EC2 instances.

![Terraform](https://github.com/user-attachments/assets/d9ad13e4-29b0-4cb3-8505-90185f793e55)


### **4.2 Running Ansible via GitHub Actions**

**Triggers:**

- **Automatically** runs after successful Terraform deployment.
- **Runs when changes are made to the `ansible/` folder.**
- **Can be manually triggered** via GitHub Actions.

**Steps:**

1. **Checkout repository** – Clones the code.
2. **Install Dependencies** – Installs Ansible, Boto3, and Botocore.
3. **Configure SSH** – Loads private SSH keys and establishes connections.
4. **Run Ansible Playbook** – Executes `ansible-playbook playbook.yaml` with AWS inventory.

**Roles Executed:**

- **Bastion:** Installs Fail2Ban, updates packages, and configures SSH access.
- **Nginx:** Installs and sets up reverse proxy for RTSP.
- **RTSP:** Installs Docker, clones the application (RTSPtoWeb + RTSP Recorder), and runs `docker-compose`.

![Ansible](https://github.com/user-attachments/assets/a980eeb7-8726-413b-bdf2-94b49a45dbac)

### **4.4 Working infrastructure**

The RTSP-to-Web infrastructure has been successfully deployed and is functioning as expected. Below is an overview of the current working setup, including real-time streaming, recording, and storage to S3.

The RTSPtoWEB interface is operational, allowing real-time streaming using multiple protocols

![UI](https://github.com/user-attachments/assets/66b10e98-594c-42bc-9dc7-3ffad353a06b)

The RTSP Recorder container is successfully recording the streams in buffer files and uploading them to an S3 bucket.

In case of stream interruptions, the system logs warnings such as:

```python
[WARNING] [CAM-1] ❌ Stream lost. Processing crash file...
```

![Upload to S3](https://github.com/user-attachments/assets/db256167-df9b-4c58-b44a-417b5f252f7c)

If a stream crash occurs, the system generates a crash file and uploads it to S3 

This mechanism ensures minimal data loss and allows for debugging and analysis of stream failures.

The RTSP-to-Web infrastructure is fully operational, with real-time streaming, automated recording, cloud storage, and error-handling mechanisms working as intended.


### **4.5 Deleting Infrastructure**

To remove deployed infrastructure, run the following commands:

```bash
cd terraform
terraform init -reconfigure -backend-config="bucket=your-s3-bucket-for-tfstate" -backend-config="region=eu-central-1"
terraform destroy --auto-approve
```

---
## **5. Planned Improvements**

- [ ]  **Monitoring:** Integrate **Prometheus and Grafana** to track EC2 and Docker container performance.
- [ ]  **HTTPS:** Set up HTTPS certificates for Nginx.
- [ ]  **Elastic IP:** Ensure Bastion Host retains a static IP after infrastructure updates.

## **Conclusion**

This project demonstrates how to automate cloud infrastructure deployment and configuration using **Terraform, Ansible, and GitHub Actions**.
