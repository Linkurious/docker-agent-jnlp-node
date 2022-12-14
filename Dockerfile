ARG PRIVATE_REGISTRY=hub.docker.nexus3.linkurious.net/
FROM ${PRIVATE_REGISTRY}linkurious/docker-agent-jnlp:0.0.19
LABEL maintainer="Edward Nys <edward@linkurio.us>"
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
USER root
# Latest Google Chrome installation package
RUN curl -fsSL https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
  && sh -c 'echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list'

# Latest Ubuntu Google Chrome, XVFB and JRE installs
# renovate: datasource=repology depName=aur/google-chrome versioning=loose
ARG GOOGLE_CHROME_STABLE_VERSION=108.0.5359.124-1
# renovate: datasource=repology depName=debian_11/firefox-esr versioning=loose
ARG FIREFOX_ESR_VERSION=102.5.0esr-1~deb11u1
RUN apt-get update -qqy && \
    apt-get -qqy install  --no-install-recommends \
        #xvfb=2:1.20.4-1 \
        #xauth=1:1.0.10-1 \
        google-chrome-stable=$GOOGLE_CHROME_STABLE_VERSION \
        firefox-esr=$FIREFOX_ESR_VERSION \
        && apt-get clean \
        && rm -rf /var/lib/apt/lists/*
#RUN echo kernel.unprivileged_userns_clone = 1 | tee /etc/sysctl.d/00-local-userns.conf

USER jenkins

# renovate: datasource=github-releases depName=nvm-sh/nvm
ARG NVM_VERSION=v0.39.1
# hadolint ignore=SC1091, SC2016
RUN git clone --depth 1 --branch "$NVM_VERSION" https://github.com/nvm-sh/nvm.git ~/.nvm && \
    echo -e 'export NVM_DIR="$HOME/.nvm"\n[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm\n' >> ~/.bashrc \
    && echo -e 'export NVM_DIR="$HOME/.nvm"\n[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm\n' >> ~/.profile \
    && source ~/.bashrc \
    && export NVM_DIR="$HOME/.nvm" && \. "$NVM_DIR/nvm.sh" \
    && nvm install 16.18.1 \
    && nvm install 14.20.0 \
    && nvm install 10.24.1
#for loading profile, to make nvm available for sh
ENV ENV='$HOME/.profile'
# hadolint ignore=SC1091
RUN export NVM_DIR="$HOME/.nvm" && \. "$NVM_DIR/nvm.sh"
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true \
    PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome-stable
COPY .angular-config.json /home/jenkins/.angular-config.json

ARG BUILD_VERSION
LABEL maintainer="Edward Nys <edward@linkurio.us>" \
      org.opencontainers.image.description="Linkurious jenkins jnlp agent node" \
      org.opencontainers.image.documentation="https://github.com/Linkurious/docker-agent-jnlp-node" \
      org.opencontainers.image.title="Jenkins jnlp agent node for Linkurious" \
      org.opencontainers.image.url="https://github.com/Linkurious/docker-agent-jnlp-node" \
      org.opencontainers.image.vendor="Linkurious" \
      org.opencontainers.image.version="${BUILD_VERSION}"
