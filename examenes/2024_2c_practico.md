
# Parcial 2024 2C Practico

## Ejercicio 1

![](attachments/Pasted%20image%2020260524104040.png)

### Solución

Nginx como reverse proxy tiene que reenviar el header `X-Parcial-Protos` del cliente al backend. Por defecto nginx no pasa headers personalizados — hay que declararlos explícitamente con `proxy_set_header`.

```nginx
location / {
    proxy_pass http://localhost:8080;
    proxy_set_header X-Parcial-Protos $http_x_parcial_protos;
}
```

- `proxy_set_header <Header> <valor>`: define o reemplaza un header en el request que nginx envía al backend.
- `$http_<nombre>`: variable nginx que contiene el valor del header recibido del cliente. El nombre del header se convierte a minúsculas y los guiones (`-`) se reemplazan por guiones bajos (`_`): `X-Parcial-Protos` → `$http_x_parcial_protos`.

→ Ver [[01_http#proxy_set_header — reenvío de headers]]
## Ejercicio 2

![754](attachments/Pasted%20image%2020260524104232.png)

La solucion era este comando

```sh
curl -x socks5://proxy.sebikul.com:1080 -u usuario:password -H "Accept: text/plain" -H "Accept-Language: es" http://ejercicio2.sebikul.com:8080/foo/
```

- `-x` le dice a curl que use un proxy. El esquema (`socks5://`, `socks5h://`, `http://`) define el tipo.
- Esta solución usa `socks5://` (sin `h`): **tu máquina** resuelve el DNS de `ejercicio2.sebikul.com`. Funcionó acá porque el hostname resuelve públicamente.
- Si el hostname solo existe en la red del lab, usar `socks5h://` (con `h`) para que el **proxy** resuelva el DNS.
- `-u usuario:password` (`--user`): Basic Auth. Curl encodea `usuario:password` en base64 y agrega el header `Authorization: Basic dXN1YXJpbzpwYXNzd29yZA==` automáticamente. Equivalente a `-H "Authorization: Basic dXN1YXJpbzpwYXNzd29yZA=="` pero más limpio.

## Ejercicio 3

![](attachments/Pasted%20image%2020260524105909.png)

El host `192.168.1.3` es el gateway de la red `10.0.0.0/24`. Hay que descubrir los servicios de `10.0.0.1`, acceder por HTTP si existe, y mostrar los routers que intervienen.

> [!WARNING] La VM tiene que estar en modo Bridge conectada a la red Lab, sino no ve la red `192.168.1.x`.

### Solución

```sh
# 1. Verificar que llegamos al gateway
ping 192.168.1.3

# 2. Agregar ruta para poder llegar a 10.0.0.0/24 via el gateway
sudo ip route add 10.0.0.0/24 via 192.168.1.3

# 3. Escanear servicios en 10.0.0.1
nmap -sS -Pn -sV 10.0.0.1

# 4. Si nmap muestra HTTP (puerto 80 u otro), acceder:
curl http://10.0.0.1
# o con el puerto que haya encontrado nmap:
curl http://10.0.0.1:<puerto>

# 5. Ver los routers que intervienen en la comunicación
traceroute 10.0.0.1
```

- El paso 2 es el más importante: sin la ruta, los paquetes a `10.0.0.x` no saben por dónde salir y el resto no funciona.
- `-sS`: TCP SYN scan, rápido y no completa el handshake.
- `-Pn`: no hace ping previo al host — si ICMP está bloqueado, nmap sin esto asume que el host está caído y no escanea nada.
- `-sV`: detecta versiones de servicios en los puertos abiertos.
- `traceroute`: muestra cada hop con su IP y latencia. El primer hop debería ser `192.168.1.3`.

→ Ejercicio similar: [[2025_2c_practico#Ejercicio 2]]

## Ejercicio 4

![](attachments/Pasted%20image%2020260524110528.png)


primero nos conectamos mediante `netcat`

```sh
nc -C mail.sebikul.com smtp
```

y ahora para mandar el mail ponemos

```
EHLO localhost
MAIL FROM: <rohernandez@itba.edu.ar>
RCPT TO: <rohernandez@itba.edu.ar>
DATA
MIME-Version: 1.0
Date: Sun, 24 May 2026 11:24:55 -0300
Message-ID: <CA+rx+vp022o93CKmjFfmkCibN=2qt6FaaGYNwAmuSVP93KGdNg@mail.gmail.com>
Subject: =?UTF-8?B?wqFCdWVub3MgZMOtYXMh?=
From: Alicia <alicia@tuvi.com>
To: Alessio <alissini@mail.sebikul.com>
Content-Type: multipart/alternative; boundary="000000000000a450ba06529106fd"

--000000000000a450ba06529106fd
Content-Type: text/plain; charset="UTF-8"
Content-Transfer-Encoding: quoted-printable

=C2=A1Hola mundo!

--000000000000a450ba06529106fd
Content-Type: text/plain; charset="UTF-8"
Content-Transfer-Encoding: base64

wqFIb2xhIG11bmRvIQo=

--000000000000a450ba06529106fd--
.
QUIT
```


### Verificar con POP3 (servidor del parcial)

```sh
nc -C mail.sebikul.com pop3
```

```
USER 65522
PASS <contraseña>
LIST
RETR 1
QUIT
```

- `LIST`: lista los mensajes con su número y tamaño en bytes
- `RETR 1`: descarga el mensaje 1 completo (headers + body)
- `QUIT`: cierra la sesión y aplica cambios (borrados, etc.)

---

### Práctica local con la VM



Como no tenemos acceso a `mail.sebikul.com` fuera del parcial, lo practicamos con la VM del laboratorio que tiene postfix + dovecot instalados.

#### Mandar el mail por SMTP

```sh
nc -C localhost 25
```

```
EHLO localhost
MAIL FROM: <rohernandez@itba.edu.ar>
RCPT TO: <rodri@pdc.lab>
DATA
MIME-Version: 1.0
Date: Sun, 24 May 2026 11:24:55 -0300
Subject: =?UTF-8?B?wqFCdWVub3MgZMOtYXMh?=
From: Rodrigo Alejandro Hernandez <rohernandez@itba.edu.ar>
To: rodri <rodri@pdc.lab>
X-Parcial: 2024/2
Content-Type: multipart/alternative; boundary="000000000000a450ba06529106fd"

--000000000000a450ba06529106fd
Content-Type: text/plain; charset="UTF-8"
Content-Transfer-Encoding: quoted-printable

=C2=A1Hola mundo!

--000000000000a450ba06529106fd
Content-Type: text/plain; charset="UTF-8"
Content-Transfer-Encoding: base64

wqFIb2xhIG11bmRvIQo=

--000000000000a450ba06529106fd--

.
QUIT
```

> [!NOTE]
> El dominio `pdc.lab` es el que configuramos en postfix durante el laboratorio. Si el tuyo es distinto, ajustarlo. El usuario `rodri` tiene que existir en el sistema (`id rodri` para verificar).

#### Leer el mail con POP3

```sh
nc -C localhost pop3
```

```
USER rodri
PASS <contraseña del sistema>
LIST
RETR 1
QUIT
```

> [!TIP]
> Si postfix está configurado con `home_mailbox=Maildir/` (como en el laboratorio), los mails llegan a `~/Maildir`. Podés verificar sin POP3 directamente con `ls ~/Maildir/new/` y `cat` del archivo.

→ Ver [[03_mail]]

