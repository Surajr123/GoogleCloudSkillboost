#!/bin/bash

# Enhanced Color Definitions
BLACK=$'\033[0;90m'
RED=$'\033[0;91m'
GREEN=$'\033[0;92m'
YELLOW=$'\033[0;93m'
BLUE=$'\033[0;94m'
MAGENTA=$'\033[0;95m'
CYAN=$'\033[0;96m'
WHITE=$'\033[0;97m'

BG_BLACK=`tput setab 0`
BG_RED=`tput setab 1`
BG_GREEN=`tput setab 2`
BG_YELLOW=`tput setab 3`
BG_BLUE=`tput setab 4`
BG_MAGENTA=`tput setab 5`
BG_CYAN=`tput setab 6`
BG_WHITE=`tput setab 7`

BOLD=`tput bold`
RESET=`tput sgr0`

echo "${BLUE}${BOLD}⚡ Initializing Artifact Registry Setup...${RESET}"
echo

# Environment Setup
echo "${GREEN}${BOLD}▬▬▬▬▬▬▬▬▬ ENVIRONMENT CONFIGURATION ▬▬▬▬▬▬▬▬▬${RESET}"
echo "${YELLOW}Retrieving project details...${RESET}"
export ZONE=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-zone])")
export REGION=$(echo "$ZONE" | cut -d '-' -f 1-2)
export PROJECT_ID=$(gcloud config get-value project)
export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format='value(projectNumber)')

echo "${YELLOW}Project ID: ${WHITE}${BOLD}$PROJECT_ID${RESET}"
echo "${YELLOW}Project Number: ${WHITE}${BOLD}$PROJECT_NUMBER${RESET}"
echo "${YELLOW}Zone: ${WHITE}${BOLD}$ZONE${RESET}"
echo "${YELLOW}Region: ${WHITE}${BOLD}$REGION${RESET}"
echo

# Service Enablement
echo "${GREEN}${BOLD}▬▬▬▬▬▬▬▬▬ ENABLING SERVICES ▬▬▬▬▬▬▬▬▬${RESET}"
echo "${YELLOW}Enabling Artifact Registry API...${RESET}"
gcloud services enable artifactregistry.googleapis.com
echo "${GREEN}✅ Artifact Registry API enabled successfully!${RESET}"
echo

# Repository Setup
echo "${GREEN}${BOLD}▬▬▬▬▬▬▬▬▬ REPOSITORY SETUP ▬▬▬▬▬▬▬▬▬${RESET}"
echo "${YELLOW}Cloning Java Docs Samples repository...${RESET}"
git clone https://github.com/GoogleCloudPlatform/java-docs-samples
cd java-docs-samples/container-registry/container-analysis
echo "${GREEN}✅ Repository cloned successfully!${RESET}"
echo

# Maven Repository Creation
echo "${GREEN}${BOLD}▬▬▬▬▬▬▬▬▬ MAVEN REPOSITORY CREATION ▬▬▬▬▬▬▬▬▬${RESET}"
echo "${YELLOW}Creating container-dev-java-repo...${RESET}"
gcloud artifacts repositories create container-dev-java-repo \
    --repository-format=maven \
    --location=$REGION \
    --description="Java package repository for Container Dev Workshop"
echo "${GREEN}✅ Maven repository created successfully!${RESET}"

echo "${YELLOW}Describing repository...${RESET}"
gcloud artifacts repositories describe container-dev-java-repo \
    --location=$REGION
echo "${GREEN}✅ Repository details displayed!${RESET}"
echo

# Remote Repository Setup
echo "${GREEN}${BOLD}▬▬▬▬▬▬▬▬▬ REMOTE REPOSITORY SETUP ▬▬▬▬▬▬▬▬▬${RESET}"
echo "${YELLOW}Creating Maven Central cache...${RESET}"
gcloud artifacts repositories create maven-central-cache \
    --project=$PROJECT_ID \
    --repository-format=maven \
    --location=$REGION \
    --description="Remote repository for Maven Central caching" \
    --mode=remote-repository \
    --remote-repo-config-desc="Maven Central" \
    --remote-mvn-repo=MAVEN-CENTRAL
echo "${GREEN}✅ Maven Central cache created successfully!${RESET}"
echo

# Virtual Repository Configuration
echo "${GREEN}${BOLD}▬▬▬▬▬▬▬▬▬ VIRTUAL REPOSITORY SETUP ▬▬▬▬▬▬▬▬▬${RESET}"
echo "${YELLOW}Creating policy.json file...${RESET}"
cat > ./policy.json << EOF
[
  {
    "id": "private",
    "repository": "projects/${PROJECT_ID}/locations/$REGION/repositories/container-dev-java-repo",
    "priority": 100
  },
  {
    "id": "central",
    "repository": "projects/${PROJECT_ID}/locations/$REGION/repositories/maven-central-cache",
    "priority": 80
  }
]
EOF
echo "${GREEN}✅ Policy file created successfully!${RESET}"

echo "${YELLOW}Creating virtual Maven repository...${RESET}"
echo "${YELLOW}This may take a few moments...${RESET}"
gcloud artifacts repositories create virtual-maven-repo \
    --project=${PROJECT_ID} \
    --repository-format=maven \
    --mode=virtual-repository \
    --location=$REGION \
    --description="Virtual Maven Repo" \
    --upstream-policy-file=./policy.json
echo "${GREEN}✅ Virtual Maven repository created successfully!${RESET}"
echo

