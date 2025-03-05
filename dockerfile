FROM mysql:8.0.41

COPY pc_komponenty.sql /docker-entrypoint-initdb.d

EXPOSE 3306