# docker/Dockerfile - layanan web kecil yang dimonitor (non-root, port 8080)
FROM nginxinc/nginx-unprivileged:1.27-alpine
COPY html/ /usr/share/nginx/html/
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=3s CMD wget -q -O /dev/null http://127.0.0.1:8080/ || exit 1
