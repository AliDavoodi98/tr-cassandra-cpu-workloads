# Dockerfile

FROM amazonlinux:latest
RUN yum -y install ansible
COPY ./ansible /playbooks
WORKDIR /playbooks
