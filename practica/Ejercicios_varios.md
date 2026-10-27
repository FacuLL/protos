# Ejercicios varios

## Ejercicio 1

### Enunciado

Obtener del host[ example.com]([http://example.com/](http://example.com/)) una respuesta HTTP 304. (Si no funciona, usar [example.org]([http://www.example.org/](http://www.example.org/)))

### Respuesta

Hacemos primero

```sh
curl -I https://example.org
```

`-I` es para pedir solo el header, tambien podemos usar `-v` para ver todo

y nos dice

```
HTTP/2 200
date: Mon, 25 May 2026 18:23:39 GMT
content-type: text/html
server: cloudflare
last-modified: Fri, 22 May 2026 08:22:30 GMT
allow: GET, HEAD
accept-ranges: bytes
age: 10424
cache-control: max-age=14400
cf-cache-status: HIT
cf-ray: a016928ead787302-EZE
```

Ahora podemos repetirlo con un `If-Modified-Since`

```sh
curl -I https://example.org -H "If-Modified-Since: Fri, 22 May 2026 08:22:30 GMT"
```

Y como no fue modificado ahi nos da el 304 que queriamos

```
HTTP/2 304
date: Mon, 25 May 2026 18:24:40 GMT
allow: GET, HEAD
age: 10485
server: cloudflare
last-modified: Fri, 22 May 2026 08:22:30 GMT
etag: "6a101246-210"
cache-control: max-age=14400
cf-cache-status: HIT
cf-ray: a016940a3aa22e50-EZE
```


## Ejercicio 2

### Enunciado

Siendo X los últimos 4 dígitos de tu legajo, exponer dos servicios distintos en el puerto X del host pampero.itba.edu.ar:
- Si accedo a ncat 127.0.0.1 X --recv-only, debería decir "hola" y luego cerrar la conexión
- Si accedo a ncat 10.16.1.100 X --recv-only, debería decir "chau" y luego cerrar la conexión
Para esto puede aprovechar los siguientes argumentos del ncat:
- "-l": permite abrir un socket pasivo, "modo servidor"
- "--recv-only": el socket no podra envíar datos, solo recibir. Una vez cerrado el socket cierra stdout.
- "--send-only": el socket no podrá recibir datos, solo envíar. Una vez cerrada stdin cierra el socket.
- "-k": permite hacer un servidor iterativo, en vez de terminar el proceso al cerrarse el socket, se queda esperando a otra conexión.
- "-c": permite pipear los datos entrantes y salientes del socket a través de un comando.
Ejemplo de un echo server iterativo: ncat -l 8080 -k -c "cat"

### Respuesta

Bueno entonces vamos a hacer como el ejemplo y ejecutamos los siguientes comandos

```sh
ncat -l localhost 3333 -k -c "echo hola"
ncat -l 10.16.1.100 3333 -k -c "echo chau"
```

Lo hice en 2 terminales distintas pero tambien se puede hacer en background usando poniendo `&` al final del comando (despues hay que acordarse de matar el proceso)

## Ejercicio 3

### Enunciado

Configur un NGINX para que:
- El sitio "puerro" funcione como proxy reverso hacia https://protos.foo/. Se puede tener que pedir cualquier recurso, o sea que puerro/xyz/... debe ir a https://protos.foo/xyz/...
- El sitio "hola" muestre una página con un mensaje de bienvenida (sacado de un archivo html)
- Cualquier otro sitio muestre "what?"
Se debe poder acceder al proxy haciendo solo "curl puerro".

### Respuesta

Lo primero es agregar los hosts necesarios en `/etc/hosts` del servidor para que nginx pueda resolverlos internamente, y también en la máquina cliente para poder hacer `curl puerro`:

```
127.0.0.1 puerro
127.0.0.1 hola
127.0.0.1 protos.foo
```

Luego creamos los archivos en `/etc/nginx/sites-available/` y los linkeamos con `ln -s` a `sites-enabled`.

**puerro** — proxy reverso a protos.foo:

```nginx
server {
    listen 80;
    server_name puerro;

    location / {
        proxy_pass http://protos.foo;
        proxy_set_header Host protos.foo;
    }
}
```

El `proxy_set_header Host protos.foo;` es importante: sin él, nginx reenvía el header `Host: puerro` al upstream y el servidor no matchea el vhost correcto. Como la `location /` pasa el path completo, `puerro/xyz/...` llega como `/xyz/...` al upstream, cumpliendo la consigna.

**hola** — página estática desde archivo HTML:

```nginx
server {
    listen 80;
    server_name hola;

    root /var/www/hola;
    index index.html;

    location / {
        try_files $uri $uri/ =404;
    }
}
```

Con `/var/www/hola/index.html` conteniendo el mensaje de bienvenida.

**default** — cualquier otro sitio devuelve "what?":

```nginx
server {
    listen 80 default_server;
    server_name _;

    root /var/www/default;
    index index.html;

    location / {
        try_files $uri $uri/ =404;
    }
}
```

Con `/var/www/default/index.html` conteniendo `What?`.

Para aplicar los cambios:

```sh
sudo nginx -t && sudo systemctl reload nginx
```


## Ejercicio 4

### Enunciado

Mandar un email a tu casilla del ITBA, y que al recibirlo y mirarlo desde gmail diga que viene de “aliceandbob@gmail.com“ y que el destino es “A quien le interese”. Poner un subject y mandar también una imágen como archivo. El cuerpo de este email debe decir “¡Hola Mundo!” (NO PUEDE FALTAR NINGUNO DE ESOS CARACTERES) y tener dos representaciones, una HTML y otra texto plano, y deben ambas estar codificadas en base64.

### Respuesta

Para enviar el mail a mano desde la terminal, primero buscamos el servidor MX de itba.edu.ar:

```sh
dig MX itba.edu.ar +short
```

Que nos devuelve que ITBA usa Google Workspace:

```
1 aspmx.l.google.com.
5 alt1.aspmx.l.google.com.
5 alt2.aspmx.l.google.com.
10 alt3.aspmx.l.google.com.
10 alt4.aspmx.l.google.com.
```

Entonces nos conectamos con ncat al MX de mayor prioridad (número más bajo) por el puerto 25:

```sh
ncat aspmx.l.google.com 25
```

> [!NOTE]
> Desde casa probablemente el ISP bloquea el puerto 25 (anti-spam). Hay que hacerlo desde la red del ITBA, por ejemplo conectado por VPN o SSH a pampero.

Una vez conectado, el servidor responde con un banner `220` y arranca el diálogo SMTP. Todo lo que enviamos es texto plano línea a línea.

Primero nos mandamos un mail con eso y vemos el source

```
MIME-Version: 1.0
Date: Mon, 25 May 2026 16:35:06 -0300
Message-ID: <CA+rx+vo6zha5Rfmqy0Q5R6dw+xtqtm6-8XSEag=46BQqZ-_zUg@mail.gmail.com>
Subject: Locura loca
From: Rodrigo Alejandro Hernandez <rohernandez@itba.edu.ar>
To: Rodrigo Alejandro Hernandez <rohernandez@itba.edu.ar>
Content-Type: multipart/mixed; boundary="000000000000cb47b30652a97965"

--000000000000cb47b30652a97965
Content-Type: multipart/alternative; boundary="000000000000cb47b10652a97963"

--000000000000cb47b10652a97963
Content-Type: text/plain; charset="UTF-8"
Content-Transfer-Encoding: quoted-printable

=C2=A1Hola Mundo!

--000000000000cb47b10652a97963
Content-Type: text/html; charset="UTF-8"
Content-Transfer-Encoding: quoted-printable

<div dir=3D"ltr"><p>=C2=A1Hola Mundo!</p></div>

--000000000000cb47b10652a97963--
--000000000000cb47b30652a97965
Content-Type: image/png; name="commercial-airplane-overhead-view-87zcetr1pklzn093.png"
Content-Disposition: attachment; filename="commercial-airplane-overhead-view-87zcetr1pklzn093.png"
Content-Transfer-Encoding: base64
X-Attachment-Id: f_mpllvf8o0
Content-ID: <f_mpllvf8o0>


--000000000000cb47b30652a97965--
```

Ahora le hacemos las modificaciones correspondientes y queda

```
EHLO rodri
MAIL FROM: <rohernandez@itba.edu.ar>
RCPT TO: <rohernandez@itba.edu.ar>
DATA
MIME-Version: 1.0
Date: Mon, 25 May 2026 16:35:06 -0300
Message-ID: <CA+rx+vo6zha5Rfmqy0Q5R6dw+xtqtm6-8XSEag=46BQqZ-_zUg@mail.gmail.com>
Subject: Locuron locuron 3
From: Alicia <aliceandbob@gmail.com>
To: A quien le interese <aquienleinterese@locura.com>
Content-Type: multipart/mixed; boundary="000000000000cb47b30652a97965"

--000000000000cb47b30652a97965
Content-Type: multipart/alternative; boundary="000000000000cb47b10652a97963"

--000000000000cb47b10652a97963
Content-Type: text/plain; charset="UTF-8"
Content-Transfer-Encoding: base64

wqFIb2xhIE11bmRvIQo=

--000000000000cb47b10652a97963
Content-Type: text/html; charset="UTF-8"
Content-Transfer-Encoding: base64

PGRpdj48cD7CoUhvbGEgTXVuZG8hPC9wPjwvZGl2Pgo=

--000000000000cb47b10652a97963--
--000000000000cb47b30652a97965
Content-Type: image/png; name="commercial-airplane-overhead-view-87zcetr1pklzn093.png"
Content-Disposition: attachment; filename="commercial-airplane-overhead-view-87zcetr1pklzn093.png"
Content-Transfer-Encoding: base64
X-Attachment-Id: f_mpllvf8o0
Content-ID: <f_mpllvf8o0>

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
RU5ErkJggg==
--000000000000cb47b30652a97965--

.
QUIT
```

## Ejercicio 5

### Enunciado

Configurar un servidor web HTTP con NGINX que muestre una página que diga “hola, yo!” cuando haces curl 127.0.0.1, pero diga “vos no sos yo” cuando te conectas con curl <ipv4 de la máquina>

### Respuesta

La clave es que nginx puede bindear cada `server` block a una IP distinta con la directiva `listen IP:puerto`. Así, cuando alguien se conecta a `127.0.0.1` entra en un bloque, y cuando se conecta a la IP real de la máquina entra en otro. Esto es lo mismo que en el Ejercicio 2: en lugar de usar `server_name` (que distingue por el header `Host`), se usa la IP en el `listen` para distinguir por qué interfaz llegó la conexión.

Creamos un nuevo archivo `/etc/nginx/sites-available/yo`:

```nginx
server {
    listen 127.0.0.1:80;

    location / {
        return 200 "hola, yo!\n";
    }
}

server {
    listen 192.168.1.84:80;

    location / {
        return 200 "vos no sos yo\n";
    }
}
```

Lo linkeamos a `sites-enabled`:

```sh
sudo ln -s /etc/nginx/sites-available/yo /etc/nginx/sites-enabled/yo
```

No hay que tocar los archivos existentes (`default`, `foo`, `puerro`, etc.) porque todos usan `listen 80` sin especificar IP (equivale a `0.0.0.0:80`). Cuando llega una conexión a `127.0.0.1:80` o `192.168.1.84:80`, nginx prioriza los bloques con IP explícita sobre los genéricos.

Recargamos nginx:

```sh
sudo nginx -t && sudo systemctl reload nginx
```

Para verificar:

```sh
curl 127.0.0.1        # → hola, yo!
curl 192.168.1.84     # → vos no sos yo
```

## Ejercicio 6

### Enunciado

Teniendo un servidor SSH localmente, hacer un túnel local a pampero usando sólo -R y no -L. Verificar el comportamiento de este túnel.

### Respuesta

Vamos a tener 2 computadoras, la mac y pampero.

Primero tenemos que habilitar remote login desde las configuraciones de sistema de nuestra mac

Queremos lograr solo usando `-R` el mismo efecto que si hicieramos desde la mac:

```sh
ssh -L 9090:algundestino:7777 usuario@pampero.itba.edu.ar
```

para este ejemplo voy a hacer en pampero lo siguiente

```sh
ncat -l 7777 -k -c "echo desde-pampero" &
```

Osea que si de pampero nos conectamos al puerto 7777, nos va a decir "desde-pampero"

Ahora hay 2 opciones:

#### Desde el ITBA

Nos fijamos la ip que nos dieron con `ifconfig` y simplemente hacemos lo siguiente desde pampero

```sh
ssh -R 9090:localhost:7777 usuario@<ip>
```

#### En mi casa

Como mi computadora en mi casa no esta expuesta a internet (NAT) vamos a exponerla abriendo en pampero un puerto remoto

```sh
ssh -R 2222:localhost:22 usuario@pampero.itba.edu.ar
```

entonces desde pampero para abrir el puerto se haria

```sh
ssh -R 9090:localhost:7777 usuario@localhost -p 2222
```

#### Validacion

tendriamos que hacer en la mac

```sh
nc localhost 9090
```

y ver como respuesta

```
desde-pampero
```


## Ejercicio 7

### Enunciado

Explicar por qué el túnel SSH creado con el siguiente comando no funciona correctamente:
ssh localhost -L1234:127.0.0.1:1234

### Respuesta

El problema es que es un loop, vemos esto cuando alguien se quiere conectar al puerto 1234

```
channel 243: open failed: connect failed: open failed
```


## Ejercicio 8

### Enunciado

Usando herramientas como ncat -l, lograr que un browser (o curl -L) tire un error de "too many redirects".

### Respuesta

Redirijamoslo siempre al mismo lugar jeje

```sh
ncat -l 1234 -k -c 'printf "HTTP/1.1 302 Found\r\nLocation: http://localhost:1234\r\nContent-Length: 0\r\n\r\n"'
```

y vemos

![](attachments/Pasted%20image%2020260525190155.png)


## Ejercicio 9

### Enunciado

Asumiendo que hay servidor proxy socks5 en pampero, puerto 1080, explicar por qué el siguiente curl falla si lo corro desde mi compu en casa, pero funciona si lo corro estando en la red del ITBA:
curl pawserver.it.itba.edu.ar -x socks5://pampero.itba.edu.ar:1080

### Respuesta

El problema es que el nombre pawserver.it.itba.edu.ar (que esta en pampero) lo esta resolviendo el cliente, pero luego se esta conectando a traves del propio pampero. Pampero rechaza conexiones con la ip publica desde su red privada

Por ejemplo si vos estas en el itba y te queres meter a tu pagina de paw pero tenes un DNS como el de cloudflare que resuelve a la ip publica, no te vas a poder conectar


> [!NOTE]
> Si se usara `socks5h://` en lugar de `socks5://`, curl le mandaría el hostname directamente al proxy para que **él** resuelva el DNS. Eso solucionaría el problema

## Ejercicio 10

### Enunciado

Configurar un servidor DNS para servir la zona carlitos.com.ar
- El servidor será la autoridad de dicha zona
- El responsable debe ser carloselmascapo@carlitos.com.ar
- carlitos.com.ar debe tener un registro A apuntando a 1.2.3.4 con un tiempo de vida de dos horas
- El subdominio mysite debe ser un registro CNAME apuntando a example.org y debe tener una validez de una semana
- El dominio para recibir correo electrónico debe ser mail20.carlitos.com.ar, mail30.carlitos.com.ar y mail40.carlitos.com.ar con las métricas 20, 30 y 40 respectivamente y una validez de 1 día
- Muestre con dig como su servidor DNS sirve todos estos registros

### Respuesta

tenemos que tener istalado bind. ver [02_dns](02_dns.md)

luego en `/etc/bind/named.conf.local` agregamos

```
zone "carlitos.com.ar" {
    type master;
    file "/etc/bind/carlitos.com.ar.local";
};
```

y creamos el archivo `/etc/bind/carlitos.com.ar.local`

```
$ORIGIN carlitos.com.ar.
$TTL 1m

@ IN SOA ns.carlitos.com.ar. carloselmascapo.carlitos.com.ar. (
            20260525   ; Serial (fecha o número, incrementar al modificar)
            7d         ; Refresh (cada cuánto el slave consulta al master)
            1d         ; Retry (si falla el refresh, reintentar cada tanto)
            10d        ; Expire (el slave deja de responder si no contacta al master)
            1m         ; Negative TTL (caché de "no existe")
)

; Nameservers (obligatorio — sin esto bind9 rechaza cargar la zona)
@   IN NS ns
ns  IN A  1.2.3.4

; Servidores de mail
@   1d IN MX 20 mail20
@   1d IN MX 30 mail30
@   1d IN MX 40 mail40

; Hosts
@       2h  IN A    1.2.3.4
mysite  7d  IN CNAME example.org.
```

Validar y recargar:

```sh
named-checkzone carlitos.com.ar /etc/bind/carlitos.com.ar.local
systemctl reload bind9
```

Verificar con dig:

```sh
dig carlitos.com.ar A @localhost       # → 1.2.3.4
dig carlitos.com.ar MX @localhost      # → mail20, mail30, mail40
dig mysite.carlitos.com.ar @localhost  # → CNAME example.org.
dig carlitos.com.ar NS @localhost      # → ns.carlitos.com.ar.
```


## Ejercicio 11

### Enunciado

Investigue la cadena de registros CNAME para el dominio foo.leak.com.ar. ¿Por qué nombres de dominio pasa? ¿Dónde está hosteado este sitio web? ¿A qué IPs se resuelve? ¿Por qué se usan registros CNAME en vez de apuntar el dominio directo a dichas IPs?

### Respuesta

vamos haciendo los dig y nos vamos fijando por donde pasamos, empezamos con 

```sh
dig foo.leak.com.ar       # ves el primer CNAME
dig <el-cname-que-aparece> # seguís la cadena
```

me dice NXDOMAIN puede que sea uno que tiene el lab y yo estoy en mi casa :(

**¿Por qué CNAME en vez de A directo?**

La razón principal es que las IPs pueden cambiar sin que haya que tocar el DNS propio. El caso típico es usar un CDN o servicio como Cloudflare, AWS, o GitHub Pages: ellos te dan un nombre canónico como `tu-sitio.cdn-proveedor.com` y vos ponés un CNAME apuntando a ese nombre. Si el proveedor cambia sus IPs (por balanceo de carga, migraciones, failover), ellos actualizan su DNS y el dominio sigue funcionando sin intervención.

Si en cambio se pusiera `A 1.2.3.4` directo, cada vez que el proveedor cambia una IP habría que actualizar el registro manualmente.

Además, un nombre canónico puede resolver a múltiples IPs distintas según la ubicación del cliente (anycast/GeoDNS) — algo que no se puede lograr hardcodeando IPs en un registro A propio.
