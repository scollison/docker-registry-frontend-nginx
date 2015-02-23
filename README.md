# Docker Registry Frontend (NGINX) #

## About ##

* Fork of `docker-registry-frontend`

* Uses Ubuntu, rather than Debian

* Uses NGINX as a lightweight, fast alternative to Apache

* Many of the existing features have been removed, in preference of mounting the configuration as a volume

* NGINX has been compiled and configured to output errors to `STDERR` and information to `STDOUT`, accessible with

        docker logs my_container_id

## Usage ##
* Create a configuration directory on the host

        mkdir -p /etc/nginx-docker/registry-frontend

* Create an ssl configuration with the server keys, if using SSL

        mkdir -p /etc/nginx-docker/registry-frontend/ssl
        cp my_server.crt /etc/nginx-docker/registry-frontend/ssl
        cp my_server.key /etc/nginx-docker/registry-frontend/ssl

* Add a configuration file for NGINX to serve

        vi /etc/nginx-docker/registry-frontend/my_site.conf
        ---
        # file: /etc/nginx-docker/registry
            upstream registry {
        # The address of your registry
            server docker-registry:5000;
        }
        # Redirect HTTP requests to HTTPS
        server {
            listen 80;
            server_name my_server; # Set your server name
            return 301 https://$server_name$request_uri;
        }
        # SSL Site
        server {
            listen 443;
            ssl on;
            ssl_certificate /etc/nginx/conf.d/server.crt
            ssl_certificate_key /etc/nginx/conf.d/server.key
            # Pass on client details
            proxy_set_header Host $http_host;
            proxy_set_header X-Real_IP $remote_addr;
            # Disable image upload limits (e.g. HTTP 413)
            client_max_body_size 0;
            chunked_transfer_encoding on;
            # Serve the frontend-files from here
            location / {
                root /var/www/html
            }
            # Serve Docker Repo from here
            location /v1/ {
                proxy_pass http://registry
            }
        }

* Run the image, mounting the configuration
    
    docker run -d \
        -p 80:80 \
        -p 443:443 \
        -v /etc/nginx-docker/registry-frontend:/etc/nginx/conf.d \
        jgriffiths1993/docker-registry-frontend-nginx

