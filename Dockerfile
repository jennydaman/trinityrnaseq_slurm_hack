FROM docker.io/trinityrnaseq/trinityrnaseq:2.13.2

RUN apt-get update
RUN apt-get install -y openssh-client

COPY ./HpcGridRunner /opt/HpcGridRunner
COPY ./chorus.sh /usr/local/bin/chorus.sh
