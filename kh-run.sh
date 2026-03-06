#podman compose run --rm nanobot-cli onboard 
#podman compose down --remove-orphans nanobot-gateway
#podman compose up -d --build --remove-orphans nanobot-gateway
mkdir -p ~/.nanobot
podman compose run --rm nanobot-cli agent
#pipx install nanobot-ai
