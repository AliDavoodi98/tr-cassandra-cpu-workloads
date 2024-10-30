# tr-cassandra-cpu-workloads
Store the ECR Password in an Environment Variable:
export ECR_PASSWORD=$(aws ecr get-login-password --region [region])

Use the Environment Variable in the Docker Login Command:
echo $ECR_PASSWORD | docker login --username AWS --password-stdin [account-id].dkr.ecr.us-east-1.amazonaws.com


Build the Docker Image:
docker build -t ansible-playbook-repo .
This command builds the Docker image from the Dockerfile in your current directory. It tags the image as ansible-playbook-repo.

Tag the Docker Image:
docker tag ansible-playbook-repo:latest <account_id>.dkr.ecr.<region>.amazonaws.com/ansible-playbook-repo:latest
Here, you’re tagging the image to prepare it for pushing to ECR. Replace <account_id> and <region> with your AWS account ID and region.

Push the Image to ECR:
docker push <account_id>.dkr.ecr.<region>.amazonaws.com/ansible-playbook-repo:latest
This command pushes your Docker image to the specified ECR repository. Replace <account_id> and <region> as before.