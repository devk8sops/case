export REDIS_PASSWORD=$(kubectl get secret --namespace redis redis -o jsonpath="{.data.redis-password}" | base64 -d)

kubectl run --namespace redis redis-client --restart='Never'  --env REDIS_PASSWORD=$REDIS_PASSWORD  --image docker.io/bitnami/redis:7.0.5-debian-11-r7 --command -- sleep infinity

sleep 5

kubectl exec --tty -i redis-client --namespace redis -- bash -c 'REDISCLI_AUTH="$REDIS_PASSWORD" redis-cli -h redis-master PING'

sleep 2

kubectl delete pod redis-client --namespace redis --grace-period=0 --force

exit

