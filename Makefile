# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    Makefile                                           :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: mmiilpal <mmiilpal@student.42.fr>          +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2025/12/01 18:30:07 by mmiilpal          #+#    #+#              #
#    Updated: 2025/12/01 18:38:07 by mmiilpal         ###   ########.fr        #
#                                                                              #
# **************************************************************************** #

# Variables
COMPOSE_FILE = srcs/docker-compose.yml
DATA_PATH = $(HOME)/data

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
	@docker-compose -f $(COMPOSE_FILE) build

# Start containers
up:
	@echo "$(BABYPINK)Starting containers...$(RESET)"
	@docker-compose -f $(COMPOSE_FILE) up -d

# Stop containers
down:
	@echo "$(BLUE)Stopping containers...$(RESET)"
	@docker-compose -f $(COMPOSE_FILE) down

# Clean containers and networks
clean: down
	@echo "$(BLUE)Removing containers, networks...$(RESET)"
	@docker-compose -f $(COMPOSE_FILE) down -v

# Full clean (including volumes data)
fclean: clean
	@echo "$(BLUE)Removing all Docker resources and data...$(RESET)"
	@docker system prune -af --volumes
	@rm -rf $(DATA_PATH)/mariadb/*
	@rm -rf $(DATA_PATH)/wordpress/*

# Rebuild everything
re: fclean all

# Show logs
logs:
	@docker-compose -f $(COMPOSE_FILE) logs -f

# Show running containers
ps:
	@docker-compose -f $(COMPOSE_FILE) ps
