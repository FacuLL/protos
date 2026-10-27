
# Parcial Practico

## Ejercicio 1

En `/etc/bind/named.conf.local`

```
zone "foo.example.org" {
	type master;
	file "/etc/bind/foo.example.org";
};
```

ahora creamos `/etc/bind/foo.example.org`

```bind
$ORIGIN foo.example.org.
$TTL 1m

@ IN SOA ns.foo.example.org. example\.admin.foo.com.ar. (
					20260528   ; Serial (YYYYMMDD o incremental)
					7d         ; Refresh (tiempo para que el slave pregunte al master)
					1d         ; Retry (si falla el refresh, reintentar cada tanto)
					10d        ; Expire (tiempo tras el cual el slave deja de responder si no contacta al master)
					1m         ; Negative TTL (tiempo de caché para respuestas NXDOMAIN)
)

@   IN NS ns
ns  IN A  1.2.3.4

@   7d IN MX 10 mx1.protos.foo.
@   7d IN MX 5 mx2.protos.foo.



@     1h   IN A 123.123.123.123
www      7d CNAME @


@        TXT "v=spf1 ip4:1.2.3.4 -all"
```

lo restarteamos con 

```sh
systemctl restart bind9
```

Ahora los comandos para probar

```sh
dig soa foo.example.org @localhost

dig A foo.example.org @localhost
dig A bar.protos.foo

dig CNAME foo.example.org @localhost

dig MX foo.example.org @localhost

dig TXT foo.example.org @localhost


```

## Ejercicio 2

nos metemos modo sudo con 

```sh
sudo -i
```

luego en `/etc/nginx/sites-available/metadata.local`

```nginx
server {
    listen 80;
    server_name metadata.local;

    location / {
        proxy_pass http://metadata.protos.foo;
        proxy_set_header Metadata true;
        proxy_set_header Accept application/json;
    }
}
```

link en sites enabled

```sh
ln -s ../sites-available/metadata.local ./metadata.local

systemctl reload nginx

echo "127.0.0.1 metadata.local" >> /etc/hosts
```

probamos con 

```sh
curl http://metadata.local
```




## Ejercicio 3


```sh
curl -v -X POST ejercicio3.protos.foo:3126/debugger -x socks5h://proxy.protos.foo:1080 -H "X-legajo: 65522" -H "Accept-Language: es" -H "Content-Type: application/json" -d '{"fix": "yes"}' -u "admin:admin"
```


## Ejercicio 4

Primero desde nuestra compu hacemos un tunel 

```sh
ssh -R 55522:localhost:8080 rohernandez@pampero.itba.edu.ar
```

y en nuestra compu vamos a redirigir la salida de el puerto 8080 a el `archivo.log`

```sh
nc -l localhost 8080 > archivo.log
```

Ahora en pampero

```sh
tail -f /tmp/parcial-20261 | nc localhost 55522
```

Y ahi ya lo esta redirigiendo, luego en nuestra compu podemos ver el contenido en tiempo real ejecutando

```sh
tail -f archivo.log
```


