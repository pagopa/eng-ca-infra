# Eng Certification Authority

## How to create a valid CSR for the CA

In this section we will create a valid CSR for the Certification Authority.

1. Go to the root of the project, or change the command below based on your location in the repository;
2. Create a CSR with the following command:  
    `openssl req -config doc/client-certificate.cnf -newkey rsa:2048 -keyout ca.key -out ca.csr -nodes`  
    All configuration parameters are stored in the `doc/client-certificate.cnf` file.
3. [OPTIONAL] if you want to specify all information manually run:  
    `openssl req  -newkey rsa:2048 -keyout ca.key -out ca.csr -nodes`


After these simple steps we will have two new files in the repo: `ca.key` and `ca.csr`, the second one is the CSR file we wanted to create.

## CA operator Workflow

### Get a valid github token
In order to use and fully interact with CA you must get a valid Github Personal access token.
To do so
1. Navigate to [token page](https://github.com/settings/tokens)
2. Create "New personal access token (classic)"
3. Give the `read:orgRead org and team membership, read org projects` permission
4. Store it to a safe place

### Use operator/signer.py
Using this tool you will be able to:
- Sign a brand new certificate
- List all certificate in a given intermediate
- Get a single certificate
- Revoke a certificate

#### How to use it
First, navigate to `operator/` folder then, you need to edit line 13 to make sure which env you want to use.

Set for *DEV* environment as follow  
```SERVER_ADDRESS = "https://api.dev.ca.eng.pagopa.it"```

for *PROD* instead  
```SERVER_ADDRESS = "https://api.ca.eng.pagopa.it"```

Then run a dependecy install by  
`pip install -r requirements.txt`

**List all certificate in a given intermediate**  
`python3 signer.py list 17`

**Sign a certificate in a given intermediate**  
We previous created `ca.csr` let's use it here  
`python3 signer.py sign 17 ca.csr`  
A valid serial should be returned, copy it.

**GET a certificate**  
Let's get a previously signed certificate. To do so we should use the serial returned from sign API, replace all `:` with `-` and use it as follow

`python3 signer.py get 17 serial`  
The signed certificate should be returned.

**Revoke a certificate**  
Let's revoke now the previously signed certificate. To do so we should use the serial returned from sign API, replace all `:` with `-` and use it as follow  
`python3 signer.py revoke serial`

## CA manual Workflow

### GET root CA
1. Get root CA:  
`curl -s https://api.ca.eng.pagopa.it/00/ca > ca.der`

2. Convert it from DER to PEM:  
`openssl x509 -inform DER -in ca.der -outform PEM -out ca.pem`

### GET intermediate
Get an intermediate CA and check using openssl  
`curl -s https://api.ca.eng.pagopa.it/intermediate/17/ca | openssl x509 -inform der -noout -text`

### GET CRL
1. Get intermediate CRL  
`curl -s https://api.ca.eng.pagopa.it/intermediate/17/crl > crl.der`

2. Convert it from DER to PEM:  
`openssl crl -inform DER -in crl.der -outform PEM -out crl.pem`

### Simple check
`curl -s https://api.ca.eng.pagopa.it/intermediate/17/crl | openssl crl -inform der -noout -text`

## Get a certificate
1. Login

`curl --location 'https://api.ca.eng.pagopa.it/login' --header 'Content-Type: application/json' --data '{"token":"***"}'`

2. Save the outcome token to a local env var

`export VAULT_TOKEN="***"`

3. Get both a valid certificate and a revoked one. Replace `xxx` with a valid certificate and `yyy` with a revoked id. Please remember to replace all `:` from serial with `-`.  
`curl -H "Authorization: Bearer ${VAULT_TOKEN}" https://api.ca.eng.pagopa.it/intermediate/17/certificate/xxx |jq .certificate| awk  '{gsub("\\\\n","\n")};1'|tr -d '"' > cert.pem`  
`curl -H "Authorization: Bearer ${VAULT_TOKEN}" https://api.ca.eng.pagopa.it/intermediate/17/certificate/yyy |jq .certificate| awk  '{gsub("\\\\n","\n")};1'|tr -d '"' > cert_revoked.pem`

### Validate against CA
`openssl verify -CAfile <(cat intermediate-17.pem ca.pem) cert.pem`

### Validate a valid certificate against CA and CRL
`openssl verify -crl_check -CAfile <(cat intermediate-17.pem ca.pem crl.pem) cert.pem`

### Validate a revoked certificate against CA and CRL
`openssl verify -crl_check -CAfile <(cat intermediate-17.pem ca.pem crl.pem) cert_revoked.pem`
