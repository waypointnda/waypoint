FROM node:fermium-buster

# Accept EULA for Microsoft fonts
RUN echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | debconf-set-selections
RUN echo deb http://httpredir.debian.org/debian buster main contrib non-free > /etc/apt/sources.list
RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y make libreoffice ttf-mscorefonts-installer python-pip
RUN fc-cache -f
RUN pip install docxcompose

WORKDIR /workdir

COPY package.json /workdir/package.json
COPY package-lock.json /workdir/package-lock.json
RUN npm ci

COPY . /workdir

CMD make
