FROM nginx:1.29.1-alpine3.22

RUN apk update && apk upgrade && \
  apk add nodejs npm

WORKDIR /opt/app/
COPY . .

RUN npm ci && \
  npm run build

RUN rm /etc/nginx/conf.d/default.conf && \
    echo 'server { \
        listen 3000; \
        server_name _; \
        root /opt/app/dist; \
        index index.html; \
        location / { \
            try_files $uri /index.html; \
        } \
    }' > /etc/nginx/conf.d/default.conf
