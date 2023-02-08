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

