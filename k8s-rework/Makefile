# Makefile

# Déploiement de l'infrastructure Kubernetes 
deploy:
	@../k8s-rework/manage-bee.sh all

# Suppression de l'infrastructure Kubernetes
destroy:
	@echo  === "Suppression de l'infrastructure..."  ===
	@kubectl delete namespace algohive
	@echo  === "Nettoyage terminé "  ===

# Affiche l'état des pods
status:
	@kubectl get pods -n algohive