# Makefile

# Lance tout dans l'ordre
deploy:
	@echo === "Démarrage de l'infrastructure Algohive..." ===
	../k8s-rework/manage-bee.sh all
	@echo === "L'infra est démarrée !" ===

# Supprime tout
destroy:
	@echo  === "Suppression de l'infrastructure..."  ===
	kubectl delete namespace algohive
	@echo  === "Nettoyage terminé "  ===

# Affiche l'état des pods
status:
	kubectl get pods -n algohive