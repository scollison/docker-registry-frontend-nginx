FROM ubuntu:latest
MAINTAINER Joshua Griffiths <jgriffiths.1993@gmail.com>

ENV INITRD no
ENV DEBIAN_FRONTEND noninteractive
ENV WWW_DIR /var/www/html
ENV SOURCE_DIR /tmp/sources

# Install NGINX & friends
RUN apt-get -y --force-yes update &&\
    apt-get -y --force-yes install \
        liblz-dev libpcre3-dev libssl-dev gcc make wget &&\
    mkdir -p /tmp/nginx-source &&\
    wget -qO- http://nginx.org/download/nginx-1.6.2.tar.gz | tar -C /tmp/nginx-source -xzf - &&\
    cd /tmp/nginx-source/nginx-1.6.2 &&\
    ./configure \
        --with-http_ssl_module\
        --prefix=/etc/nginx\
        --sbin-path=/usr/sbin\
        --conf-path=nginx.conf\
        --error-log-path=/dev/stderr\
        --http-log-path=/dev/stdout\
        --user=www-data\
        --group=www-data &&\
    make install &&\
    mkdir -p /etc/nginx/conf.d &&\
    apt-get -y --force-yes remove gcc make &&\
    apt-get -y --force-yes autoremove

RUN mkdir -pv $WWW_DIR

############################################################
# This adds everything we need to the build root except those
# element that are matched by .dockerignore.
# We explicitly list every directory and file that is involved
# in the build process but. All config files (like nginx) are
# not listed to speed up the build process. 
############################################################

# Create dirs
RUN mkdir -p $SOURCE_DIR/dist
RUN mkdir -p $SOURCE_DIR/app
RUN mkdir -p $SOURCE_DIR/test

# Add dirs
ADD app $SOURCE_DIR/app
ADD test $SOURCE_DIR/test

# Dot files
ADD .jshintrc $SOURCE_DIR/
ADD .bowerrc $SOURCE_DIR/
ADD .editorconfig $SOURCE_DIR/
ADD .travis.yml $SOURCE_DIR/

# Other files
ADD bower.json $SOURCE_DIR/
ADD Gruntfile.js $SOURCE_DIR/
ADD LICENSE $SOURCE_DIR/
ADD package.json $SOURCE_DIR/
ADD README.md $SOURCE_DIR/

# Add Git version information to it's own json file app-version.json
RUN mkdir -p $SOURCE_DIR/.git
ADD .git/HEAD $SOURCE_DIR/.git/HEAD
ADD .git/refs $SOURCE_DIR/.git/refs
RUN cd $SOURCE_DIR && \
    export GITREF=$(cat .git/HEAD | cut -d" " -f2) && \
    export GITSHA1=$(cat .git/$GITREF) && \
    echo "{\"git\": {\"sha1\": \"$GITSHA1\", \"ref\": \"$GITREF\"}}" > $WWW_DIR/app-version.json && \
    cd $SOURCE_DIR && \
    rm -rf $SOURCE_DIR/.git

RUN apt-get -y --force-yes install \
      git \
      nodejs \
      nodejs-legacy \
      npm \
      --no-install-recommends && \
    git config --global url."https://".insteadOf git:// && \
    cd $SOURCE_DIR && \
    npm install && \
    node_modules/bower/bin/bower install --allow-root && \
    node_modules/grunt-cli/bin/grunt build --allow-root && \
    cp -rf $SOURCE_DIR/dist/* $WWW_DIR && \
    rm -rf $SOURCE_DIR && \
    apt-get -y --auto-remove purge git nodejs nodejs-legacy npm && \
    apt-get -y clean && \
    rm -rf /var/lib/apt/lists/*

# Add default NGINX config. Imports anything matching /etc/nginx/conf.d/*.conf
ADD nginx.conf  /etc/nginx/nginx.conf
ADD nginx-site.conf /etc/nginx/conf.d/site.conf

# Let people know how this was built
ADD Dockerfile /root/Dockerfile
ADD start-nginx.sh /usr/local/sbin/start-nginx.sh
RUN chmod 0755 /usr/local/sbin/start-nginx.sh

# Exposed ports
EXPOSE 80 443

CMD ["/usr/local/sbin/start-nginx.sh"]
