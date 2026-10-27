---
tags:
  - protos
  - practica
  - http
  - guia
---

# Guía Práctica: HTTP

---

## curl — flags esenciales

```sh
curl <url>                          # GET básico
curl -i <url>                       # incluye headers en la respuesta
curl -v <url>                       # verbose: muestra request + response completos
curl -X POST <url>                  # cambiar método
curl -H "Header: Valor" <url>       # agregar header
curl -d '{"key":"val"}' <url>       # body (implica POST)
curl --compressed <url>             # pedir compresión gzip
curl -0 / --http1.1 / --http2       # elegir versión HTTP
curl -s <url>                       # silent (sin progreso, útil en scripts)
curl -L <url>                       # seguir redirects
curl -x socks5h://host:port <url>   # proxy SOCKS5, DNS lo resuelve el proxy (usar en parcial)
curl -x socks5://host:port <url>   # proxy SOCKS5, DNS lo resuelve tu máquina
curl -o archivo <url>               # guardar respuesta en archivo
curl -r 0-999 <url>                 # Range request (reanudar descarga)
curl -u user:pass <url>             # autenticación básica
```

### wget — cuándo en vez de curl

```sh
wget <url>                 # descargar un archivo al disco (por default guarda con su nombre)
wget -O archivo <url>      # elegir nombre de salida
wget -c <url>              # continuar una descarga cortada (usa Range)
wget -r <url>              # descarga recursiva (espejar un sitio)
wget -q <url>              # silencioso
```

> `curl` transfiere datos y los tira a stdout (inspeccionar, POST, headers). `wget`
> descarga archivos al disco y sabe bajar recursivo. Si la consigna dice *"descargar"* o
> *"espejar el sitio"* → `wget`; si dice *"mandar/ver/inspeccionar"* → `curl`.

### Combinaciones frecuentes en parcial

```sh
# Proxy SOCKS5 con headers (típico de parcial)
# socks5h: el proxy resuelve el DNS → usar cuando el hostname solo existe en la red del lab
curl -x socks5h://proxy.host:1080 -H "Accept: text/plain" -H "Accept-Language: es" http://servidor:8080/ruta/

# Proxy SOCKS5 + Basic Auth
# -u usuario:password agrega Authorization: Basic <base64> automáticamente
# equivalente a -H "Authorization: Basic dXN1YXJpbzpwYXNzd29yZA==" pero sin calcular el base64 a mano
curl -x socks5h://proxy.host:1080 -u usuario:password -H "Accept: text/plain" http://servidor:8080/ruta/

# GET con header personalizado
curl 192.168.1.1 -H "Tiki: Taka"

# POST con JSON
curl -X POST <url>/endpoint -H "Content-Type: application/json" -d '{"rta": "valor"}'

# Negociación de contenido por idioma
curl <url>/recurso -H "Accept-Language: es"

# ETag / caché condicional
curl -i -H 'If-None-Match: "abc123"' <url>
curl -i -H "If-Modified-Since: Thu, 13 Mar 2025 19:51:16 GMT" <url>

# Ver solo headers de respuesta (HEAD)
curl -I <url>
```

→ Ver aplicación en [[Ejercicio_integrador#Inicio]] y [[guia_respuestas#E19|E19]], [[guia_respuestas#E21|E21]]

---

## Netcat — HTTP manual

Para enviar \r\n (CRLF) en la terminal: `ctrl+v` luego `Enter` → imprime `^M`, después `Enter` normal.

> [!TIP]
> **Pruebas con Netcat**
> Al usar `netcat` para probar protocolos de texto, el flag `-C` es fundamental para enviar fines de línea tipo **CRLF** (\r\n), que es el estándar requerido por protocolos como SMTP y HTTP.
> Para pruebas reales, se puede utilizar el servidor **pampero**.

```sh
# Ponerse a escuchar en un puerto (simular servidor)
nc -l 9090

# Conectarse a un servidor (simular cliente)
nc <ip> 80
```

Ejemplo de request HTTP 1.1 manual:

```
GET / HTTP/1.1\r\n
Host: localhost\r\n
\r\n
```

Ejemplo de response HTTP:

```
HTTP/1.1 200 OK\r\n
Content-Type: text/html\r\n
Content-Length: 20\r\n
\r\n
<h1>Hola Mundo</h1>
```

→ Ver [[guia_respuestas#E17|E17]], [[guia_respuestas#E18|E18]], [[guia_respuestas#E19|E19]]

---

## Nginx — virtual hosts y reverse proxy

### Instalación

```sh
sudo apt install nginx-core
sudo -i   # escalar a root para configurar
```

### Configurar virtual host

Crear `/etc/nginx/sites-available/foo`:

```nginx
server {
    listen 80;
    server_name foo;

    root /var/www/foo;
    index index.html;

    location / {
        try_files $uri $uri/ =404;
    }
}
```

Para el server **default**: usar `server_name _;` y `listen 80 default_server;`

```sh
# Habilitar: crear symlink
ln -s /etc/nginx/sites-available/foo /etc/nginx/sites-enabled/foo

# Crear contenido
mkdir /var/www/foo
echo "Bienvenido a foo!" > /var/www/foo/index.html

# Agregar alias en /etc/hosts
echo "127.0.0.1 localhost foo bar" >> /etc/hosts

# Verificar y recargar
nginx -t
systemctl reload nginx

# Probar
curl -v http://localhost -H "host:foo"
```

### Reverse proxy

Reemplazar `try_files` por `proxy_pass` en `/etc/nginx/sites-available/xxx`. Nginx **no reenvía headers personalizados por defecto** — declararlos con `proxy_set_header`:

```nginx
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Custom-Header $http_x_custom_header;
    }
}
```

>[!important]
>Las variables `$http_*` mapean los headers del cliente: todo a minúsculas y guiones → guiones bajos.

| Header del cliente | Variable nginx |
|---|---|
| `X-Parcial-Protos` | `$http_x_parcial_protos` |
| `Accept-Language` | `$http_accept_language` |

### `proxy_pass` — la barra final cambia todo

```nginx
location /api/ {
    proxy_pass http://backend;       # SIN barra → manda el path COMPLETO: /api/users → /api/users
}

location /api/ {
    proxy_pass http://backend/;      # CON barra → REEMPLAZA el prefijo: /api/users → /users
}
```

Para un proxy reverso transparente (`sitio/xyz` → `upstream/xyz`), usar `location /` y
`proxy_pass` **sin** barra ni path:

```nginx
location / {
    proxy_pass http://protos.foo;
    proxy_set_header Host protos.foo;
}
```

> [!IMPORTANT]
> `proxy_set_header Host <upstream>` casi siempre hace falta: sin él nginx manda
> `Host: <tu-sitio>` al upstream y el upstream no matchea su propio vhost (te devuelve
> su default, un 404, o el sitio equivocado).
>
> `proxy_set_header Host $host` reenvía el Host **original del cliente** — úsalo cuando el
> upstream tiene que ver el nombre con el que entró el cliente.

Upstream HTTPS: `proxy_pass https://...` (nginx valida el cert del upstream; si es
self-signed, agregar `proxy_ssl_verify off;`).

---

## Cómo elige nginx el `server` block

Orden de decisión, **en este orden**:

1. **IP:puerto del `listen`** — el bloque con IP explícita gana sobre el genérico.
2. **`server_name`** — se compara contra el header `Host` del request.
3. **`default_server`** — si nada matcheó.

```nginx
listen 80;                  # = 0.0.0.0:80, todas las interfaces
listen 127.0.0.1:80;        # SOLO loopback
listen 192.168.1.84:80;     # SOLO esa interfaz
listen 80 default_server;   # el que atiende si ningun server_name matchea
```

### Servir contenido distinto según **por qué IP** entraron

Ejercicio clásico. No se puede con `server_name` (eso mira el `Host`), hay que usar la IP
en el `listen`:

```nginx
server {
    listen 127.0.0.1:80;
    location / { return 200 "hola, yo!
"; }
}

server {
    listen 192.168.1.84:80;
    location / { return 200 "vos no sos yo
"; }
}
```

```sh
curl 127.0.0.1        # -> hola, yo!
curl 192.168.1.84     # -> vos no sos yo
```

> Los bloques existentes con `listen 80` a secas no molestan: nginx prioriza el que tiene
> IP explícita.

### Catch-all: cualquier otro nombre

```nginx
server {
    listen 80 default_server;
    server_name _;
    location / { return 200 "What?
"; }
}
```

> `return 200 "texto";` sirve respuestas inline sin crear archivos — más rápido que
> `root` + `index.html` cuando la consigna solo pide un mensaje.

### Loop de redirects (para provocar "too many redirects")

```nginx
location / { return 302 $request_uri; }    # se redirige a si mismo
```

```sh
# Con ncat, sin nginx:
ncat -l 8080 -k -c "printf 'HTTP/1.1 302 Found
Location: /

'"
curl -L localhost:8080        # -> Maximum (50) redirects followed
```

→ Ver [[guia_respuestas#E36|E36]], [[guia_respuestas#E39|E39]], [[2024_2c_practico#Ejercicio 1]]

---

## Leer una config nginx para recorrer un servidor

Te dan el `nginx.conf` ya hecho y hay que encontrar un archivo /
entrar a un recurso navegando con `curl`. No se configura nada: se **lee** la config y se
arma el `curl`.

### Qué mirar en cada directiva

| Directiva | Qué te dice |
|---|---|
| `listen 8080;` | en qué puerto contesta ese `server` block |
| `server_name secreto.lab;` | el bloque **solo** responde si el request trae `Host: secreto.lab`; si no, cae al `default_server` |
| `root /var/www/x;` | la URL se **pega** al root: `/a/b.txt` → `/var/www/x/a/b.txt` |
| `location /files/ { alias /srv/f/; }` | `alias` **reemplaza** el prefijo: `/files/k` → `/srv/f/k` (ojo: ≠ root) |
| `autoindex on;` | si pedís la **carpeta**, te lista los archivos (incluso sin `index`) |
| `index index.html;` | qué archivo sirve si pedís una carpeta |
| `return 302 /otro;` / `rewrite` | redirige → seguilo con `-L` o pedí el destino a mano |
| `proxy_pass http://...;` | ese path lo contesta **otro** servidor |
| `allow <ip>; deny all;` | solo esas IPs entran a ese path (si te bloquea, hay que entrar desde la IP permitida) |
| `auth_basic "..."` + `auth_basic_user_file` | pide usuario y contraseña → `curl -u user:pass` |

### root vs alias (la confusión clásica)

```nginx
location /files/ { root  /srv/f; }    # /files/k.txt -> /srv/f/files/k.txt  (pega la URL entera)
location /files/ { alias /srv/f/; }   # /files/k.txt -> /srv/f/k.txt        (reemplaza el prefijo)
```

### Recorrer el server con curl

```sh
# Elegir el vhost por Host (el server_name que leíste en la config)
curl -v -H "Host: secreto.lab" http://<IP>:8080/

# Equivalente, resolviendo el nombre a esa IP (sirve también para HTTPS/SNI):
curl --resolve secreto.lab:8080:<IP> http://secreto.lab:8080/

# Si hay autoindex, pedir la carpeta lista los archivos
curl -H "Host: secreto.lab" http://<IP>:8080/files/ -o lista.html

# Bajar un archivo puntual (ej: una clave que encontraste en el listado)
curl -H "Host: secreto.lab" http://<IP>:8080/files/id_rsa -o key

# Path con auth_basic
curl -u usuario:password -H "Host: secreto.lab" http://<IP>:8080/privado/
```

> `--resolve <host>:<puerto>:<ip>` fuerza a qué IP resuelve ese host sin tocar `/etc/hosts`.
> Es como `-H "Host:"` pero además arregla el SNI en TLS — con `https://` usá `--resolve`, no `-H`.

### Después: entrar por SSH y cazar la contraseña (final del integrador)

```sh
chmod 600 key                      # ssh rechaza claves con permisos abiertos (0644)
ssh -i ./key usuario@<IP>          # puede pedir passphrase de la clave

# ya adentro, buscar la contraseña entre todos los archivos:
find . -type f                     # qué archivos hay
ls -la                             # incluye ocultos (.algo)
grep -rni "pass\|clave\|secret\|password" .   # -r recursivo, -n línea, -i sin case
echo "dGV4dG8=" | base64 -d        # si algo está en base64
```

→ Ver [[Ejercicio_integrador]], [[2024_2c_practico#Ejercicio 2]]

---

## HTTPS con nginx — certificado self-signed

Caso típico de parcial: *"que `https://seguro.foo` sirva el contenido de `http://parcial.foo`
sin que cambie la URL en el browser, y que `curl` funcione sin flags extra"*.

> [!IMPORTANT]
> **Sin cambiar la URL → `proxy_pass`, NO `return 301/302`.**
> Un redirect cambia la barra de direcciones. `proxy_pass` sirve el contenido de forma
> transparente.

### 1. Resolver los nombres primero

```sh
ip addr show                                            # ver nuestra IP
echo "192.168.x.y  seguro.protos.foo"  >> /etc/hosts    # nuestro nginx
echo "192.168.x.z  parcial.protos.foo" >> /etc/hosts    # el upstream, si el DNS no lo resuelve
```

> [!WARNING]
> Nginx resuelve el upstream **al arrancar**. Si `parcial.protos.foo` no resuelve,
> `nginx -t` falla con `host not found in upstream` y el servicio no levanta.

### 2. Generar el certificado

```sh
openssl req -x509 -newkey rsa:4096 \
  -keyout /etc/ssl/private/seguro.key \
  -out /etc/ssl/certs/seguro.crt \
  -days 365 -nodes \
  -subj "/CN=seguro.protos.foo" \
  -addext "subjectAltName=DNS:seguro.protos.foo"
```

| Flag | Qué hace |
|---|---|
| `-x509` | genera un cert self-signed directo (sin CSR ni CA) |
| `-newkey rsa:4096` | genera la clave privada junto con el cert |
| `-nodes` | **no** cifra la clave con passphrase — si no, nginx se cuelga pidiéndola al arrancar |
| `-subj "/CN=<host>"` | identidad del cert |
| `-addext "subjectAltName=DNS:<host>"` | **el SAN — obligatorio** (ver abajo) |
| `-days 365` | validez |

> [!WARNING]
> **curl y los browsers modernos ignoran el CN: validan el `subjectAltName` (SAN).** Un cert
> con solo `-subj "/CN=..."` y **sin** `-addext subjectAltName` falla con
> `SSL: no alternative certificate subject name matches target host name`. Siempre agregar el SAN,
> con el **mismo** hostname. Para varios nombres: `subjectAltName=DNS:a.foo,DNS:b.foo`.

- `.key` → clave privada, queda en el servidor.
- `.crt` → certificado (clave pública + identidad), se manda al cliente en el handshake.

### 3. Config nginx

`/etc/nginx/sites-available/seguro`:

```nginx
server {
    listen 443 ssl;
    server_name seguro.protos.foo;

    ssl_certificate     /etc/ssl/certs/seguro.crt;
    ssl_certificate_key /etc/ssl/private/seguro.key;

    location / {
        proxy_pass http://parcial.protos.foo;
        proxy_set_header Host parcial.protos.foo;   # el nombre del UPSTREAM, no $host
    }
}
```

```sh
ln -s /etc/nginx/sites-available/seguro /etc/nginx/sites-enabled/
nginx -t && systemctl reload nginx
```

> [!WARNING]
> **`Host` va con el nombre del upstream, NO `$host`.** El cliente entra como
> `seguro.protos.foo`, así que `$host` vale `seguro.protos.foo`. Si se lo mandás al upstream
> `parcial.protos.foo` (vhost name-based), no matchea su server block → 404 / sitio default.
> Hay que mandarle **su propio** nombre: `proxy_set_header Host parcial.protos.foo;`.
> (Sin la línea, el default de nginx ya es `$proxy_host` = `parcial.protos.foo`, correcto;
> poner `$host` lo rompe.) Usás `$host` al revés: cuando el upstream necesita ver el nombre
> con el que entró el cliente.

### 4. Hacer que el cliente confíe (curl sin `-k`)

Un cert self-signed lo firma nadie → curl responde
`SSL certificate problem: self-signed certificate`. Si la consigna prohíbe flags extra,
hay que meterlo en el trust store del sistema:

```sh
cp /etc/ssl/certs/seguro.crt /usr/local/share/ca-certificates/seguro.crt
update-ca-certificates
```

> `update-ca-certificates` solo levanta archivos con extensión **`.crt`** dentro de
> `/usr/local/share/ca-certificates/`. Con `.pem` los ignora.

### 5. Verificar

```sh
curl https://seguro.protos.foo          # tiene que andar sin -k y sin error TLS
curl -k https://seguro.protos.foo       # solo para debug: ignora la validación
openssl s_client -connect seguro.protos.foo:443 -servername seguro.protos.foo
```

### Redirigir HTTP → HTTPS (si lo piden)

```nginx
server {
    listen 80;
    server_name seguro.protos.foo;
    return 301 https://$host$request_uri;
}
```

→ Ver [[2025_2c_practico#Ejercicio 4]]

---

## Proteger un path con usuario y contraseña (auth_basic)

Lado servidor del Basic Auth (lo que hay que **leer** en la config del ejercicio de Tomás, o
**armar** si lo piden):

```nginx
location /privado/ {
    auth_basic           "Zona restringida";        # realm; cualquier texto
    auth_basic_user_file /etc/nginx/.htpasswd;       # archivo de usuarios
}
```

```sh
# Crear el archivo de credenciales (apache2-utils trae htpasswd)
sudo apt install apache2-utils
sudo htpasswd -c /etc/nginx/.htpasswd usuario     # -c crea; sin -c agrega otro user
systemctl reload nginx
```

```sh
curl -u usuario:password http://sitio/privado/     # sin -u → 401 Unauthorized
```

> Combina con `allow`/`deny` para restringir por IP:
> ```nginx
> location /admin/ { allow 192.168.1.0/24; deny all; }
> ```

---

## Caché HTTP

| Mecanismo | Header de respuesta | Header en revalidación | Respuesta si no cambió |
|---|---|---|---|
| max-age | `Cache-Control: max-age=3600` | — (no consulta al server) | — |
| Last-Modified | `Last-Modified: <fecha>` | `If-Modified-Since: <fecha>` | `304 Not Modified` |
| ETag | `ETag: "abc123"` | `If-None-Match: "abc123"` | `304 Not Modified` |

→ Ver [[guia_respuestas#E32|E32]], [[guia_respuestas#E33|E33]], [[guia_respuestas#E34|E34]]

---

## Códigos de estado importantes

| Código | Significado |
|---|---|
| 200 | OK |
| 301 | Moved Permanently |
| 302 | Found (redirect temporal) |
| 304 | Not Modified (caché válida) |
| 400 | Bad Request |
| 401 | Unauthorized (falta autenticación) |
| 403 | Forbidden (autenticado pero sin permiso) |
| 404 | Not Found |
| 405 | Method Not Allowed |
| 409 | Conflict |
| 410 | Gone (eliminado permanentemente) |
| 415 | Unsupported Media Type |
| 503 | Service Unavailable |

→ Ver [[guia_respuestas#E29|E29]]

---

## Descargas parciales / reanudar (Range)

Para bajar un archivo por tramos o reanudar una descarga cortada:

```sh
curl -r 0-999 <url>                       # pedir solo los bytes 0..999
curl -r 1000- <url>                       # desde el byte 1000 hasta el final
curl -C - -O <url>                        # reanudar automaticamente lo que falte
```

Qué headers participan:

| Lado | Header | Ejemplo |
|---|---|---|
| El server **avisa** que soporta rangos | `Accept-Ranges: bytes` | en cualquier respuesta |
| El cliente **pide** un rango | `Range: bytes=0-999` | en el request |
| El server **responde** el rango | `Content-Range: bytes 0-999/5000` | con status **`206 Partial Content`** |

> `206 Partial Content` = te mandó solo el pedazo pedido. Si el server ignora el `Range`
> y manda `200` con todo el archivo, es que **no** soporta rangos (típico de PDFs generados
> al vuelo).

---

## Content negotiation y media types

El cliente dice qué acepta; el server elige y responde con `Content-Type`.

```sh
curl <url> -H "Accept: application/json"      # quiero JSON
curl <url> -H "Accept-Language: es"           # quiero español
curl <url> -H "Accept-Encoding: gzip"         # acepto gzip
```

| Recurso | Media type (`Content-Type`) |
|---|---|
| HTML | `text/html` |
| Texto | `text/plain` |
| CSS | `text/css` |
| JS | `text/javascript` o `application/javascript` |
| JSON | `application/json` |
| Imágenes | `image/jpeg`, `image/png`, `image/gif` |
| PDF | `application/pdf` |
| Binario / descarga genérica | `application/octet-stream` |

> Estructura: `tipo/subtipo`. `application/octet-stream` = "bytes crudos, descargalo".

---

## Headers clave

```
# Request
Host: www.ejemplo.com          # obligatorio en HTTP/1.1
Accept-Language: es            # negociación de idioma
Accept: application/json       # negociación de tipo
Range: bytes=0-999             # descarga parcial
If-None-Match: "etag"          # caché condicional
Cookie: session=abc123         # sesión

# Response
Set-Cookie: session=abc123; Expires=...
Content-Type: text/html; charset=utf-8
Content-Length: 1234
Transfer-Encoding: chunked
Cache-Control: max-age=3600, public
ETag: "67d33734-c"
Location: /nueva-url           # en redirects
WWW-Authenticate: Basic realm="zona"
```

---

## Idempotencia y seguridad de métodos

| Método | Seguro (no modifica) | Idempotente |
|---|---|---|
| GET | ✅ | ✅ |
| HEAD | ✅ | ✅ |
| PUT | ❌ | ✅ |
| DELETE | ❌ | ✅ |
| POST | ❌ | ❌ |
| PATCH | ❌ | ❌ |

→ Ver [[guia_respuestas#E27|E27]]

---

## Redirect de dominio con nginx

```nginx
server {
    listen 80;
    server_name foo.pdc.lab.alt;

    location / {
        return 302 http://protos.foo$request_uri;
    }
}
```

→ Ver [[guia_respuestas#E48|E48]]
