export POSTGRES_PASSWORD=$(kubectl get secret --namespace postgres postgresql -o jsonpath="{.data.postgres-password}" | base64 -d)

echo "Postgres DB Size;"

kubectl run postgresql-client --rm --tty -i --restart='Never' --namespace postgres --image docker.io/bitnami/postgresql:14.5.0-debian-11-r24 --env="PGPASSWORD=$POSTGRES_PASSWORD" \
      --command -- psql --host postgresql -U postgres -d postgres -p 5432 -c "SELECT pg_size_pretty(pg_database_size('postgres'));"








