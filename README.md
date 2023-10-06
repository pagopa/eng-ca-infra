# Eng CA

## How to create a valid CSR for the CA

In this section we will create a valid CSR for the Certification Authority.

1. Go to the root of the project, or change the command below based on your location in the repository;
2. Create a CSR with the following command:  
    `openssl req -config doc/client-certificate.cnf -newkey rsa:2048 -keyout ca.key -out ca.csr -nodes`  
    All configuration parameters are stored in the `doc/client-certificate.cnf` file.
After these simple steps we will have two new files in the repo: `ca.key` and `ca.csr`, the second one is the CSR file we wanted to create.
