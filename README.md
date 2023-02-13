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

1. using TLS in between services inside the cluster and
2. using TLS at the ingress for communicating securely with a client outside the cluster
   
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

### mTLS for the sidecars
Istio is configured per default using mTLS in ```PERMISSIVE``` mode, which means, services can accept plain http and https traffic.

So first lets prevent the use of HTTP all together by adding a ```skaffold.yaml``` in the root folder of the project where everything shall be configured that is globally needed by all modules. For example the global mTLS strategy.

#### Check TLS is enabled
Now, how can we be sure that the motd-service calls the hello-service indeed using TLS? At last, we only use a sinmple ```RestTemplate``` in our motd-service controller, calling explicitly http:

    restTemplate.getForObject("http://hello-service:8080/hello/" + name.trim(), String.class);

##### Programmatically in our services
Everything happens completely transparently by Istios sidecars. The motd- and hello-service both log the HTTP headers. If you check their logs you will find the header ```x-forwarded-client-cert```. In the documentation it says, that this header is set if mTLS is working.

    [motd-service] 2023-02-12T11:55:57.852Z  INFO 1 --- [nio-8080-exec-9] c.n.scaffold.motdservice.MotdController  : Header x-forwarded-client-cert: By=spiffe://cluster.local/ns/default/sa/default;Hash=903daa98bdbfee8784bfc8266d058968effc9cfdf39e92c0ed4efc949ac9c978;Subject="";URI=spiffe://cluster.local/ns/istio-system/sa/istio-ingressgateway-service-account

##### Investigating network traffic
If you don't believe the documentation you can capture the network traffix between the services using ```tcpdump``` from within the sidecar.

**Before you can do so, you have to install Istio with ```values.global.proxy.privileged=true```**. We take the opportunity to get rid of the demo profile that we have installed into the cluster up to now by just installing the default profile that serves as a good starting point for production environments.

    istioctl install --set values.global.proxy.privileged=true

Now after starting your services you can interactively exec into the sidecar of the motd-service pod like so

    kubectl exec -ti <pod-name> -c istio-proxy -n <namespace> -- /bin/bash

Now you can use tcpdump to capture traffic between the motd- and the hello-service. Type ```ifconfig``` to get the ip address of the ```eth0``` device. 

    sudo tcpdump -vvvv -A -i eth0 '((dst port 8080 and (net <ip-address>)))'

All you see is encrypted unreadable content. Try the opposite, disable mTLS completely by setting the mode to ```DISABLE``` in ```cluster/k8s/mtls.yaml``` and install it by executing ```skaffold run``` in the root folder of the project. And then repeat the steps from above.



    
