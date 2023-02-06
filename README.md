# Azure Infrastructure Operations Project: Deploying a scalable IaaS web server in Azure

### Introduction
This Terraform configuration will deploy:
- A policy to require indexed resources to have a tag
- A resource group to contain all deployed resources
- A Network Load balancer and associated resources
- A user-specificed number of Ubuntu 18.04-LTS VMs with a user-specified password and 16GB managed disks

### Getting Started
1. Clone this repository
2. Verify all dependencies
2. Login to your Azure account using "az login"
3. Create your VM image using Packer
4. Deploy this Terraform configuration

### Dependencies
1. Create an [Azure Account](https://portal.azure.com) 
2. Install the [Azure command line interface](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
3. Install [Packer](https://www.packer.io/downloads)
4. Install [Terraform](https://www.terraform.io/downloads.html)

### Instructions
1. Clone this repository using `git clone https://github.com/p-bish/udacity-devops.git`
2. Log in to your Azure account using `az login`
3. Create a service principal for Packer to use
  1. `az ad sp create-for-rbac -n "PackerSP" --role Contributor --scopes "/subscriptions/==yoursubscriptionid==`
  2. Save the password/secret and application id
4. Inside the "packer" folder you will find server.json. Use this to create your VM Image.
  1. Modify the "Created by" tag with your name
  2. Modify "managed_image_resource_group_name" with the name of an existing resource group to store your final image
  3. Modify the "managed_image_name" to specify the name of your final image. Record this name to use in your Terraform deployment
  4. If you wish to build the image using an existing resource group, modify "build_resource_group_name" 
  5. If you wish for packer to create a temporary resource group only during the build process, replace "build_resource_group_name" with `"location": "your preferred region"`
  6. Specify the following environmental variables
    1. PACKER_CLIENT_ID = application/client id recieved from the az ad sp create-for-rbac command
    2. PACKER_CLIENT_SECRET = password/secret recieved from the az ad sp create-for-rbac command
    3. PACKER_SUBSCRIPTION_ID = the subscription ID from your Azure account
  7. Run the command `packer build server.json` from within the packer folder
5. Inside the main "udacity-devops" folder, initialize and deploy the Terraform configuration
  1. Execute `terraform init` to initialize the modules and install the required providers
  2. Execute `terraform plan -out solution.plan`
  3. Answer the prompts, storing the password that you create for use to log into the virtual machines.
    1. Note - The password must meet complexity requirements. Between 6 and 72 characters long, with uppercase, lowercase, special character, and number. 
  4. If there are no errors, execute `terraform apply "solution.plan"`
6. If desired, you can execute `terraform destroy` to destroy the infrastructure that was built

### Output
1. The result should generate everything needed to stand up a specified number of VMs, tagged with the Creator, along with the required networking resources.
2. The output should include:
  1. The admin username of the VMs (you provided the password during creation)
  2. The public IP and FQDN of the Load balancer
  3. The names of the Virtual Machines created

