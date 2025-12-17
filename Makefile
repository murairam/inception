# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    Makefile                                           :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: mmiilpal <mmiilpal@student.42.fr>          +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2025/12/01 18:30:07 by mmiilpal          #+#    #+#              #
#    Updated: 2025/12/17 19:29:27 by mmiilpal         ###   ########.fr        #
#                                                                              #
# **************************************************************************** #

# Variables
COMPOSE_FILE = srcs/docker-compose.yml
DATA_PATH = $(HOME)/data
DOCKER_COMPOSE = docker compose

# Colors for output
BABYPINK = \033[38;5;218m
BLUE = \033[0;34m
RESET = \033[0m

.PHONY: all build up down clean fclean re logs ps

# Default target
all: build up

# Build images
build:
	@echo "$(BABYPINK)Building Docker images...$(RESET)"
	@mkdir -p $(DATA_PATH)/mariadb
	@mkdir -p $(DATA_PATH)/wordpress
	@mkdir -p $(DATA_PATH)/static-site
	@echo "$(BABYPINK)Copying static-site files...$(RESET)"
	@cp -r srcs/requirements/bonus/static-site/www/* $(DATA_PATH)/static-site/ 2>/dev/null || true
	@$(DOCKER_COMPOSE) -f $(COMPOSE_FILE) build

# Start containers
up:
	@mkdir -p $(DATA_PATH)/mariadb $(DATA_PATH)/wordpress $(DATA_PATH)/static-site
	@echo "$(BABYPINK)Starting containers...$(RESET)"
	@$(DOCKER_COMPOSE) -f $(COMPOSE_FILE) up -d

# Stop containers
down:
	@echo "$(BLUE)Stopping containers...$(RESET)"
	@$(DOCKER_COMPOSE) -f $(COMPOSE_FILE) down

# Clean containers and networks
clean: down
	@echo "$(BLUE)Removing containers, networks...$(RESET)"
	@$(DOCKER_COMPOSE) -f $(COMPOSE_FILE) down -v

# Full clean (including volumes data)
fclean: clean
	@echo "$(BLUE)Removing all Docker resources and data...$(RESET)"
	@docker system prune -af --volumes
	@sudo rm -rf $(DATA_PATH)/mariadb/*
	@sudo rm -rf $(DATA_PATH)/wordpress/*
	@sudo rm -rf $(DATA_PATH)/static-site/*

# Rebuild everything
re: fclean all

# Show logs
logs:
	@$(DOCKER_COMPOSE) -f $(COMPOSE_FILE) logs -f

# Show running containers
ps:
	@$(DOCKER_COMPOSE) -f $(COMPOSE_FILE) ps

