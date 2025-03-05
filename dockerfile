FROM mysql:8.0.41

COPY pc_komponenty_dump.sql /docker-entrypoint-initdb.d