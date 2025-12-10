# Déploiement du POC Algohive sur Kubernetes (Local)

Ce document décrit la procédure pas-à-pas pour déployer l'architecture microservices Algohive sur un cluster Kubernetes local (Kind).

## Prérequis

Avant de commencer, assurez-vous d'avoir les outils suivants installés sur votre poste :
* **Docker** (Daemon lancé)
* **Kind** (Kubernetes in Docker)
* **Kubectl** (CLI Kubernetes)
* **Git**

---

## 1. Déploiement des manifestes

**Important** : L'ordre d'application doit être respecté pour gérer les dépendances (Config > DB > Apps)

### 1.1. Créer le namespace
```shell
kubectl apply -f k8s/00-namespace.yaml
```

### 1.2. Appliquer la conf (secrets et configmap)
```shell
kubectl apply -f k8s/01-config.yaml
```

### 1.3. Déployer les DB
```shell
kubectl apply -f k8s/02-db.yaml
kubectl apply -f k8s/03-redis.yaml
```

### 1.4. Déployer le backend
```shell
kkubectl apply -f k8s/04-server.yaml
kubectl apply -f k8s/05-beeapi.yaml
```

### 1.5. Déployer les interfaces (front et hub admin)
```shell
kubectl apply -f k8s/06-client.yaml
kubectl apply -f k8s/07-beehub.yaml
```

### 1.6. Valider le déploiement
```shell
kubectl get pods -n algohive -w
NAME                                    READY   STATUS    RESTARTS   AGE
algohive-cache-6c799c7b8f-bp7tr         1/1     Running   0          7h16m
algohive-client-85666d7ddc-6tx4g        1/1     Running   0          7h3m
algohive-db-8f856ff75-96cr8             1/1     Running   0          7h20m
algohive-server-7499d5ffc5-56dq9        1/1     Running   0          7h9m
beeapi-server-lyon-86545fdf7d-9bwbf     1/1     Running   0          7h10m
beeapi-server-mpl-5df98bd955-bwpj6      1/1     Running   0          7h10m
beeapi-server-staging-97d66fb65-mf4mp   1/1     Running   0          7h10m
beeapi-server-tlse-686c59fc97-2pv9c     1/1     Running   0          7h10m
beehub-6ccbdc578f-fwdbn                 1/1     Running   0          7h2m
```

## 2. Accès aux applis (Port Forward)
En environnement local (Kind), nous n'avons pas d'Ingress Controller public. Nous utilisons le `port-forward` pour accéder aux services.

Ouvrir 3 terminaux séparés :

Terminal A - Interface Étudiant
```shell
# URL d'accès : http://localhost:7002
kubectl port-forward service/algohive-client 7002:80 -n algohive
```

Terminal B - API Backend
```shell
# URL d'accès : http://localhost:8001/swagger/index.html
kubectl port-forward service/algohive-server 8001:8080 -n algohive
```

Terminal C - Interface Admin (BeeHub)
```shell
# URL d'accès : http://localhost:8002
kubectl port-forward service/beehub 8002:8081 -n algohive
```

## 2. Validation des accès

### 2.1 Test de l'interface étudiant :
Non fonctionnel pour le moment (vu avec Eric)
On ne peut pas se connecter en tant qu'admin pour créer des comptes.
Il faut rebuild l'image
```shell
$ git clone https://github.com/AlgoHive-Coding-Puzzles/AlgoHive-Client.git
# // Edit le env.production
$ docker build .
```
Il faudra changer l'url d'api : http://localhost:PORT_API/api/v1

### 2.2 Test de l'interface admin :
Connexion avec admin/admin

Pour ajouter les puzzles, il faut saisir une clé API qui se génère au lancement du pod

```shell
kubectl logs pods/beeapi-server-lyon-86545fdf7d-9bwbf -n algohive
2025/11/23 11:00:21 API key initialized: N6qORMoLfTLmi24Zo9UnLAmTI7AB0gbrjpCL8DPyGxE=
2025/11/23 11:00:21 Extracting puzzles...
2025/11/23 11:00:21 Loading puzzles...
2025/11/23 11:00:21 Server starting on port 5000
[GIN] 2025/11/23 - 11:00:59 | 200 |      49.724µs |     10.244.0.27 | GET      "/name"
[GIN] 2025/11/23 - 11:07:53 | 200 |      28.402µs |     10.244.0.30 | GET      "/name"
```
