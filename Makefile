include ./Makefile.dev

gen_self_certs:
	chmod 755 .env && . ./.env && sudo rm ${CODECONNECT_DATA}/traefik/${DOMAIN}.crt && chmod 755 .env && . ./.env && sudo rm ${CODECONNECT_DATA}/traefik/${DOMAIN}.key && chmod 755 .env && . ./.env && sudo openssl req -x509 -sha256 -days 356 -nodes -newkey rsa:2048 -out ${CODECONNECT_DATA}/traefik/${DOMAIN}.crt -keyout ${CODECONNECT_DATA}/traefik/${DOMAIN}.key


##
## Start the docker containers
##
up_full_app: up_proxy up_db

up_db: gen_env
	chmod 755 .env && . ./.env && docker stack deploy -c docker-compose-db.yml ${STACK_NAME}-db

down_db: gen_env
	chmod 755 .env && . ./.env && docker stack rm ${STACK_NAME}-db

up_keycloak: build_keycloak_image gen_env
	chmod 755 .env && . ./.env && docker stack deploy -c docker-compose-keycloak.yml ${STACK_NAME}-keycloak

down_keycloak: gen_env
	chmod 755 .env && . ./.env && docker stack rm ${STACK_NAME}-keycloak

up_proxy: gen_env 
	chmod 755 .env && . ./.env && docker stack deploy -c docker-compose-proxy.yml ${STACK_NAME}-proxy

down_proxy: gen_env
	chmod 755 .env && . ./.env && docker stack rm ${STACK_NAME}-proxy

up_service: gen_env
	chmod 755 .env && . ./.env && docker stack deploy -c docker-compose-${service}.yml ${STACK_NAME}-${service}

##
## Build docker containers
##
build_image: gen_env
	. ./.env && docker compose -f docker-compose-${stack}.yml build

##
## System initialisation
##
swarm_label_true: gen_env
	chmod 755 .env && . ./.env && docker node update --label-add ${STACK_NAME}_${node_label}=true ${node}

swarm_init:
	docker swarm init

codeconnect_network:
	docker network create --driver overlay codeconnect-public

mount_prep: gen_env
	chmod 755 .env && . ./.env && mkdir -p ${CODECONNECT_DATA} && \
	echo "127.0.0.1	localhost" && \
	echo "$(ip route get 8.8.8.8 | awk -F"src " 'NR==1{split($2,a," ");print a[1]}') ${DOMAIN} ${DB_DOMAIN} ${REGISTRY_DOMAIN} ${RABBITMQ_HOST} ${KEYCLOAK_DOMAIN} ${API_DOMAIN}" >> ${CODECONNECT_DATA}/hosts && \
	echo "$(ip route get 8.8.8.8 | awk -F"src " 'NR==1{split($2,a," ");print a[1]}') portainer.${DOMAIN} grafana.${DOMAIN} swarmprom.${DOMAIN}" >> ${CODECONNECT_DATA}/hosts && \
	echo "$(ip route get 8.8.8.8 | awk -F"src " 'NR==1{split($2,a," ");print a[1]}') unsee.${DOMAIN} alertmanager.${DOMAIN}" >> ${CODECONNECT_DATA}/hosts && \
	mkdir -p ${CODECONNECT_DATA}/db && \
	mkdir -p ${CODECONNECT_DATA}/auth && \
	cp deployment/traefik_passwd ${CODECONNECT_DATA}/auth/system_passwd && \
	mkdir -p ${CODECONNECT_DATA}/keycloak && \
	mkdir -p ${CODECONNECT_DATA}/certs && \
	cp deployment/certs/* ${CODECONNECT_DATA}/certs && \
	mkdir -p ${CODECONNECT_DATA}/registry && \
	mkdir -p ${CODECONNECT_DATA}/traefik && \
	deployment/traefik/config.yml ${CODECONNECT_DATA}/traefik \
	mkdir -p ${CODECONNECT_DATA}/openkm/repository && \
	cp deployment/openkm/* ${CODECONNECT_DATA}/openkm

##
## Environment management
##
rm_env:
	rm -f .env

gen_env:
	if [ -f .env ]; then \
		rm -f .env; \
	fi
	@$(ENV)
	chmod 755 .env