FROM push.docker.nexus3.linkurious.net/linkurious/docker-agent-jnlp:0.0.1
LABEL maintainer="Edward Nys <edward@linkurio.us>"
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# hadolint ignore=SC2016
RUN git clone --depth 1 --branch v0.35.2 https://github.com/nvm-sh/nvm.git ~/.nvm && \
    echo -e 'export NVM_DIR="$HOME/.nvm"\n[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm\n' >> ~/.bashrc \
    && echo -e 'export NVM_DIR="$HOME/.nvm"\n[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm\n' >> ~/.profile \
    && source ~/.bashrc \
    && export NVM_DIR="$HOME/.nvm" && \. "$NVM_DIR/nvm.sh" \
    && nvm install 10.21.0 \
    && nvm install 12.18.0 \
    && nvm install 14.4.0
#for loading profile, to make nvm available for sh
ENV ENV='$HOME/.profile'
