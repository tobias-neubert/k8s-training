# Spring, Kubernetes, Istio & Skaffold
This repository contains my private little training for the above mentioned topics. Each commit on the main branch is one step further into this jungle of technologies. If you want to reproduce my learning curve, simply start with the first commit and proceed with the next until you reach the last one.

<!-- TOC -->

- [Spring, Kubernetes, Istio \& Skaffold](#spring-kubernetes-istio--skaffold)
  - [Prepare the minikube](#prepare-the-minikube)
    - [Stopping minikube](#stopping-minikube)
  - [Start the app](#start-the-app)
  - [Call the app](#call-the-app)
  - [(m)TLS](#mtls)
    - [Create the training CA and some certificates](#create-the-training-ca-and-some-certificates)
    - [TLS for the ingress-gateway](#tls-for-the-ingress-gateway)
    - [mTLS for the sidecars](#mtls-for-the-sidecars)
      - [Check TLS is enabled](#check-tls-is-enabled)
        - [Programmatically in our services](#programmatically-in-our-services)
        - [Investigating network traffic](#investigating-network-traffic)
  - [A first CI pipeline](#a-first-ci-pipeline)
    - [The big picture](#the-big-picture)
    - [Reduce to one service per repository](#reduce-to-one-service-per-repository)
    - [A first CI pipeline](#a-first-ci-pipeline-1)
      - [Access for the pipeline to the target repo](#access-for-the-pipeline-to-the-target-repo)
    - [No secrets in the rendered k8s resources](#no-secrets-in-the-rendered-k8s-resources)
    - [The base image](#the-base-image)
    - [Local development](#local-development)

<!-- /TOC -->

## Prepare the minikube
Before you can use skaffold to incrementally deploy the application(s), you have to prepare out local development environment. 

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

## Call the app
You now can call the motd-service like this

    curl http://localhost/motd/tobias

Because we have configured two hello-service instances, one polite and one not, and a istio VirtualService with a route that splits the traffic to the hello-service by using the polite version in 70% of all calls and the other one 30%, you will receive either

    This is the message of the day: Hello tobias

or

    This is the message of the day: Good morning tobias

Depending on the time of day you may receive ```Good day``` or ```Good evening```.

## (m)TLS
We will use TLS from the beginning. So lets enable it next. Enabling TLS in Kubernetes means

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

## A first CI pipeline
Up to now we've learned how to use skaffold for the local development loop. And we configured Istio to use TLS everywhere.

The most important part for me in the early stages of the development of an app is to get something running, and to create a complete development loop from programming, over testing to the deployment of the app. Only then can we really proceed incrementally.

So in this chapter we start by implementing a CI pipeline for our first service, that builds the image, pushes it to our container registry, renders the k8s resources for the target cluster and pushes them to another repo, k8s-training-app, from where we will deploy the app. This last step is done in the next chapter.

### The big picture
The idea is that we track our current app in the cluster using git. Every microservice will be developed in its own repository. It will be tested and built there. 

The whole app on the other hand, is composed based on this microsoervices inside another repository. That means that the build pipelines of the microsoervices will render the k8s resources needed for the application and push them into the applications repository.

In a later chapter we will react to those new files pushed to the application repository by triggering some kind of deployment to the target cluster.

To learn the basics we will not work with different environments yet. So for example, we will not have any kind of staging environment. Instead we assume that there is currently only one kubbernetes cluster with one running application. 

### Reduce to one service per repository
The hello service served its purpose. Now, to proceed the forst step is to make this repo a single module project. Every service shall have its own repository. So this is now the repo for the motd-service.

### A first CI pipeline
We use Github actions for our CI pipeline. You will find it in ```.github/workflows/build-motd-service.yml```.

It is easy, it is short. And nonetheless it took me several days to get it running with skaffold. What I did not undestand is why ```./gradlew jib``` worked perfectly fine, but ```skaffold build``` which only uses the former command to build and push the image to our github repository. 

I needed some time to understand that after skaffold built and pushed the image, it tries to get the new digest of the image by reading it from the repo and that it therefore needs to authenticat against ghcr. But because it does not know about the authentication configuration of the gradle jib plugin, it failed doing so. 

The solution is to call ```docker login ghcr.io``` before we call skaffold. In general this is not a good idea because that way my ghcr password will be saved unencrypted on the build machine in the docker config file. But because github generates a token for each build, I think it does no harm.

#### Access for the pipeline to the target repo
You have to create a ssh keypair and set the public key to the target repo via settings --> deploy keys of the target repo and the private key to the source repo via settings->secrets and variables->action secret. The name of that secret has to be the one we use in the github actions workflow.

### No secrets in the rendered k8s resources
Important: Because we now push the rendered k8s resources to another repository in plain text, we have to make sure that no secret will be published. In our case it means we must not publish the tls secrets. We have to install them somewhere else. I think we will do that in the next chapter when we have to prepare the cluster itself.

### The base image
As you can see in the gradle build file, I chose to push the base image to my private docker registry at ghcr.io. In a production environment you would of course configure your registry as a proxy or mirror for the docker hub.

### Local development
For local development you now have to save the github user and password in your ```gradle.properties``` file.


