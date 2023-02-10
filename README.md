# Spring, Kubernetes, Istio & Skaffold
This repository contains my private little training for the above mentioned topics. Each commit on the main branch is one step further into this jungle of technologies. If you want to reproduce my learning curve, simply start with the first commit and proceed with the next until you reach the last one.

## Prepare the minikube
Before you can use skaffold to incrementally deploy the application(s), you have to prepare minikube. 

I assume that you have all needed tools installed on your computer: docker, minikube, skaffold, istioctl, kubectl. Then you can execute the following commands:

    minikube start

    # istio installieren, hier das demo Profil
    istioctl manifest apply --set profile=demo

    # istio für den default namespace aktivieren
    kubectl label namespace default istio-injection=enabled

    # in a separate window to start  the external loadbalancer
    # that the istio gateway needs to bind its external
    # ip address to
    minikube tunnel

### Stopping minikube
If you only stop minikube and restart it afterwards, everything is ready as being configured previously. That means istio is installed and activated.

You only habe to start the tunnel again with

    minikube tunnel

But if you delete your minikube to create a new one, you have to go through the steps above again.

## Start the app
Currently the application consists of two REST services: The message-of-the-day-service, or motd-service, and the hello-service. The motd-service calls the hello-service in order to create its message of the day.

Start both services using skaffold by changing into their corresponding directory and execute the following command for both services:

    cd hello-service
    skaffold dev

    cd motd-service
    skaffold dev

## Test the app
You now can call the motd-service like this

    curl http://localhost/motd/tobias

Because we have configured two hello-service instances, one polite and one not, and a istio VirtualService with a route that splits the traffic to the hello-service by using the polite version in 70% of all calls and the other one 30%, you will receive either

    This is the message of the day: Hello tobias

or

    This is the message of the day: Good morning tobias

Depending on the time of day you may receive ```Good day``` or ```Good evening```.

## (m)TLS
Enabling TLS in Kubernetes means

1. using TLS inbetween services inside of the cluster and
2. using TLS at the ingress for communicating securly with a client outside the cluster
   
As usual with TLS this is not just a question of how to enable or disable it but above all how to create and use the various certificates. This section explains the easiest way of doing it by using a tiny custom certificate authority.

And because mTLS between services inside the cluster is activated per default by istio, we will start with the ingress. But before of this we need to create out tiny training CA.

### Create the training CA and some certificates
The CA used in this training repo is included in ```motd-service/ca``` and it was created like so:

    # change into the CA's root folder
    cd motd-service
    mkdir -p ca/certs ca/private ca/csr 
    cd ca

With that in place I created the root certificate like so (**the password for the root certificates key is: ```secret```**):

    # create the root certificat and key
    cd motd-service/ca
    openssl genrsa -aes256 -out private/ca.key.pem 4096
    openssl req -x509 -new -nodes -extensions v3_ca -key private/ca.key.pem -days 3650 -sha512 -out certs/ca.cert.pem

And with that I can now create server certificates:

    cd motd-service/ca
    openssl req -out csr/motd.neubert.csr -newkey rsa:2048 -nodes -keyout private/motd.neubert.key -subj "/C=DE/ST=Hamburg/L=Hamburg/O=Tobias Neubert/OU=Training Center/CN=motd.neubert/emailAddress=tobi@s-neubert.net"
    openssl x509 -req -sha256 -days 365 -CA certs/ca.cert.pem -CAkey private/ca.key.pem -set_serial 0 -in csr/motd.neubert.csr -out certs/modt.neubert.cert.pem

### TLS for the ingress-gateway
First we need to tell Istio where to find the server certificate to use for the ingressgateway. This is done as kubernetes tls secret as can be found in ```motd-service/k8s/tls.yml```.

**Important! You have to base64 encode the certificate and key before you insert them into the secrets yaml file!**

Add the ```tls.yaml``` to the skaffold config and reference it in the istio gateway resource. 

Start the motd-service with ```skaffold dev``` and request the service with:

    curl -v -HHost:motd.neubert --resolve "motd.neubert:443:127.0.0.1" --cacert "ca/certs/ca.cert.pem" https://motd.neubert/motd/tobias
