---
tags:
  - protos
  - practica
  - mail
  - smtp
  - pop3
  - mime
  - guia
---

# Guía Práctica: Mail (SMTP, POP3, MIME, TLS)

---

## Los tres agentes — vocabulario de las consignas

| Sigla | Qué es | Ejemplo | Protocolo que habla |
|---|---|---|---|
| **MUA** | Mail User Agent — el cliente que usás | Thunderbird, Outlook, `nc` a mano | SMTP (enviar) + POP3/IMAP (leer) |
| **MTA** | Mail Transfer Agent — mueve el mail entre servidores | Postfix, Sendmail | SMTP |
| **MDA** | Mail Delivery Agent — lo deja en la casilla | Dovecot, procmail | — |

```
MUA  --SMTP-->  MTA  --SMTP-->  MTA  -->  MDA  -->  casilla  <--POP3/IMAP--  MUA
(vos)          (tu server)     (el del destino)                             (el que recibe)
```

> Cuando la consigna dice *"debe poder leerlo un MUA que no soporte X"*, habla del **cliente
> final**, no del servidor. Lo que importa es cómo codificaste el mensaje.

---

## SMTP — comandos y sesión manual

SMTP usa **TCP puerto 25**. Con netcat se puede simular un cliente:

```sh
nc -C localhost 25   # -C envía CRLF (\r\n) — OBLIGATORIO en SMTP
```

### Secuencia de comandos

```
EHLO localhost
MAIL FROM: <remitente@dominio>
RCPT TO: <destinatario@dominio>
DATA
<headers MIME>
<línea en blanco>
<cuerpo del mensaje>
.                    ← línea con solo un punto termina el mensaje
QUIT
```

### Códigos de respuesta — leer lo que contesta el servidor

Cada comando devuelve un número. **El primer dígito es lo único que importa de entrada:**

| 1º dígito | Significa |
|---|---|
| **2xx** | OK, seguí |
| **3xx** | OK pero falta más input (solo `354` tras `DATA`) |
| **4xx** | Error **temporal** — reintentar más tarde (greylisting cae acá) |
| **5xx** | Error **permanente** — no reintentar, el mail rebota |

| Código | Cuándo aparece |
|---|---|
| `220` | banner de bienvenida al conectarse |
| `250` | comando aceptado (`EHLO`, `MAIL FROM`, `RCPT TO`, y el mensaje final) |
| `250-` | línea intermedia de la respuesta a `EHLO` (el `-` = "sigue"); la última lleva `250 ` con espacio |
| `354` | "mandá el mensaje, terminá con `.`" — respuesta a `DATA` |
| `221` | adiós, respuesta a `QUIT` |
| `235` | autenticación exitosa |
| `334` | el servidor pide el siguiente dato del `AUTH` (en base64) |
| `421` | servicio no disponible, cierra la conexión |
| `450` / `451` | buzón ocupado / error local — temporal |
| `550` | buzón inexistente o rechazado por política (SPF/spam) |
| `551` / `553` | destinatario no local / dirección mal formada |
| `554` | transacción fallida (típico de open relay denegado) |

### Sesión real anotada (`S:` servidor, `C:` cliente)

```
S: 220 mail.sebikul.com ESMTP Postfix
C: EHLO itba.edu.ar
S: 250-mail.sebikul.com
S: 250-PIPELINING
S: 250-SIZE 10240000
S: 250-STARTTLS
S: 250-AUTH PLAIN LOGIN
S: 250 8BITMIME
C: MAIL FROM: <flopezllopis@itba.edu.ar>
S: 250 2.1.0 Ok
C: RCPT TO: <65522@mail.sebikul.com>
S: 250 2.1.5 Ok
C: DATA
S: 354 End data with <CR><LF>.<CR><LF>
C: <headers + linea en blanco + cuerpo>
C: .
S: 250 2.0.0 Ok: queued as 4ABCD1234
C: QUIT
S: 221 2.0.0 Bye
```

### `EHLO` vs `HELO`

- `HELO` → SMTP original (RFC 821). El servidor contesta una sola línea.
- `EHLO` → **ESMTP**. El servidor lista sus **extensiones**. Usar siempre este.

Qué te dice cada extensión del `250-`:

| Extensión | Para qué sirve |
|---|---|
| `SIZE 10240000` | tamaño máximo de mensaje en bytes → acá sale el ejercicio del adjunto de 9 MB |
| `STARTTLS` | se puede subir la conexión a TLS |
| `AUTH PLAIN LOGIN` | **requiere/acepta autenticación**, y con qué mecanismos |
| `PIPELINING` | se pueden mandar varios comandos sin esperar respuesta |
| `8BITMIME` | acepta cuerpo en 8 bits |

> [!IMPORTANT]
> **Dot-stuffing.** El mensaje termina con una línea que es solo `.`. Si una línea del
> **cuerpo** empieza con un punto, hay que **duplicarlo**, sino el servidor corta el mail ahí:
>
> ```
> .Hola        → se manda como     ..Hola
> ```
>
> El receptor saca el punto extra. Mandar el cuerpo en **base64** evita el problema entero
> (base64 nunca genera una línea que arranque con `.`).

> [!NOTE]
> Líneas de máximo **998 caracteres** (RFC 5321). Por eso base64 se corta en 76 por línea.

### Ejemplo completo con MIME

```
EHLO localhost
MAIL FROM: <hola@example.com>
RCPT TO: <rodri@pdc.lab>
DATA
MIME-Version: 1.0
Date: Thu, 9 Apr 2026 21:44:07 -0300
Subject: Gran mail
From: Tomas Peloso <tomi@itba.edu.ar>
To: Alicia <rohernandez@itba.edu.ar>
Content-Type: multipart/alternative; boundary="limite123"

--limite123
Content-Type: text/plain; charset="UTF-8"
Content-Transfer-Encoding: base64

aG9sYSBtYW5vbGEK
--limite123--
.
QUIT
```

→ Ver [[Laboratorio#Servidor smtp]] y [[guia_respuestas#E57|E57]]

---

## Headers: envelope vs. cabecera

Son **dos cosas distintas** y el servidor no las compara:

| | Quién lo usa | Comando / header |
|---|---|---|
| **Envelope** (sobre) | El MTA, para ruteo | `MAIL FROM:` / `RCPT TO:` |
| **Cabecera** (header) | El MUA, para mostrar | `From:` / `To:` / `Cc:` |

Por eso un mail puede tener `MAIL FROM: <a@x.com>` y `From: Otro <b@y.com>`. Eso es
exactamente lo que explota el spam → por eso existen SPF/DKIM.

> [!IMPORTANT]
> `Bcc:` **nunca** va en la cabecera. Se manda como un `RCPT TO:` más y listo.

### Headers que un mail "bien formado" debe tener

Obligatorios según RFC 5322:

```
From: Nombre Apellido <usuario@dominio>
Date: Thu, 9 Apr 2026 21:44:07 -0300
```

Buenas prácticas (los pide cualquier ejercicio de parcial):

```
To: Nombre <destinatario@dominio>
Subject: ...
Message-ID: <algo-unico@dominio>
MIME-Version: 1.0
Content-Type: ...
Content-Transfer-Encoding: ...
```

Headers propios → **siempre** con prefijo `X-`:

```
X-Parcial: 2024/2
X-Mailer: nc
```

Formato de `Date:` (RFC 5322) — generarlo con:

```sh
date -R          # Thu, 09 Apr 2026 21:44:07 -0300
```

Formato de `From:`/`To:` con nombre:

```
From: Facundo Lopez Llopis <flopezllopis@itba.edu.ar>
```

Si el nombre tiene caracteres no-ASCII o comas, va entre comillas y/o codificado
(ver RFC 2047 más abajo).

---

## AUTH — cuando el servidor pide autenticación

Si el `EHLO` lista `AUTH`, el servidor **no es open relay**: hay que loguearse antes de
`MAIL FROM`, sino devuelve `530 Authentication required` o `554 Relay access denied`.

### AUTH LOGIN (usuario y clave por separado, cada uno en base64)

```sh
printf 'flopezllopis@itba.edu.ar' | base64     # ZmxvcGV6bGxvcGlzQGl0YmEuZWR1LmFy
printf 'mipassword'               | base64     # bWlwYXNzd29yZA==
```

```
C: AUTH LOGIN
S: 334 VXNlcm5hbWU6              <- "Username:" en base64
C: ZmxvcGV6bGxvcGlzQGl0YmEuZWR1LmFy
S: 334 UGFzc3dvcmQ6              <- "Password:" en base64
C: bWlwYXNzd29yZA==
S: 235 2.7.0 Authentication successful
```

### AUTH PLAIN (todo junto en un solo base64)

El formato es `\0usuario\0password` — **con bytes NUL separando**, no espacios:

```sh
printf '\0flopezllopis@itba.edu.ar\0mipassword' | base64
```

```
C: AUTH PLAIN AGZsb3Blemxsb3Bpc0BpdGJhLmVkdS5hcgBtaXBhc3N3b3Jk
S: 235 2.7.0 Authentication successful
```

> [!WARNING]
> Base64 **no es cifrado** — cualquiera que capture el tráfico lee la contraseña.
> Por eso `AUTH` va siempre sobre TLS (puerto 587 con `STARTTLS`, o 465).

---

## Instalar y configurar Postfix (servidor SMTP)

```sh
sudo apt install postfix
```

Elegir `internet site` y luego el nombre del dominio, por ejemplo `pdc.lab`.

Verificar que está corriendo con `netstat -tulpn`. Conectarse con:

```sh
nc -C localhost 25
```

Los mails quedan en `/var/spool/mail/<usuario>`. También se puede enviar desde un archivo:

```sh
cat email.txt | nc -C localhost 25
```

Si mandamos varios, los mensajes se van concatenando en el mismo archivo.

Para que cada mail quede en un archivo separado (necesario para que dovecot lo pueda leer), agregar al inicio de `/etc/postfix/main.cf`:

```
home_mailbox=Maildir/
```

y reiniciar:

```sh
systemctl restart postfix
```

Ahora los mails llegan al directorio `~/Maildir`.

→ Ver [[Laboratorio#Servidor smtp]] y [[guia_respuestas#E57|E57-E60]]

---

## POP3 — leer mails remotamente

```sh
sudo apt install dovecot-pop3d
```

Si postfix está configurado con `home_mailbox=Maildir/`, dovecot también necesita saber que los mails están ahí. Por defecto busca en `/var/spool/mail/` y no encontraría nada. Editar `/etc/dovecot/conf.d/10-mail.conf` y cambiar la línea `mail_location`:

```
mail_location = maildir:~/Maildir
```

y reiniciar:

```sh
systemctl restart dovecot
```

Conectarse con:

```sh
nc -C localhost pop3   # o nc -C localhost 110
```

### Comandos POP3 (en orden)

```
USER rodri          # identificar usuario
PASS contraseña     # autenticar (en texto plano)
LIST                # listar mails (número + tamaño)
RETR 1              # leer el mail nro 1
DELE 1              # marcar mail 1 para borrar
RSET                # deshacer los DELE de esta sesión
UIDL                # listar IDs únicos de los mails
QUIT                # aplicar cambios y cerrar
```

Comandos que faltan y a veces piden:

```
STAT                # cantidad de mensajes + tamaño total  →  +OK 2 1340
TOP 1 10            # headers del mail 1 + las primeras 10 lineas del cuerpo
NOOP                # no hace nada, mantiene viva la sesion
APOP user <digest>  # login con hash MD5 en vez de clave en claro
```

`TOP` es el que sirve en el parcial para **ver solo los headers** sin bajarse el adjunto entero.

### Respuestas POP3

A diferencia de SMTP, POP3 **no usa códigos numéricos**:

| Respuesta | Significa |
|---|---|
| `+OK` | salió bien |
| `-ERR` | falló |

Las respuestas multilínea (`LIST`, `RETR`, `TOP`, `UIDL`) terminan con una línea de solo `.`
— igual que el `DATA` de SMTP.

### Estados POP3

```
AUTH → (USER + PASS) → TRANSACTION → (QUIT) → UPDATE
```

Los DELE solo se aplican al hacer QUIT. Si hacés Ctrl+C, no se borra nada.

### POP3 vs IMAP

| | POP3 (110) | IMAP (143) |
|---|---|---|
| Filosofía | descargar y borrar | todo queda en el servidor |
| Múltiples dispositivos | no sincroniza | sincroniza |
| Leído / no leído | no lo distingue | sí (flags) |
| Carpetas en el servidor | no | sí |
| Descarga parcial de un mail | solo `TOP` | sí, parte por parte |
| Backup | tuyo (local) | del servidor |
| Uso de recursos del server | poco | mucho |

> Si la consigna dice *"quiero leer el mismo mail desde el celu y la compu"* → **IMAP**.
> Si dice *"descargar los mails y liberar el servidor"* → **POP3**.

→ Ver [[Laboratorio#Servidor para leer mails pop3]]

---

## MIME — codificación y tipos

### Headers MIME esenciales

```
MIME-Version: 1.0
Content-Type: text/plain; charset="UTF-8"
Content-Transfer-Encoding: base64
```

### Content-Type multipart

```
Content-Type: multipart/mixed;      boundary="limite"   # partes de distinta naturaleza (texto + adjunto)
Content-Type: multipart/alternative; boundary="limite"  # misma info en formatos distintos (text/html + text/plain)
Content-Type: multipart/related;    boundary="limite"   # partes que se referencian (HTML + imagen embebida)
```

Estructura de un cuerpo multipart:

```
--limite
Content-Type: text/plain
...texto...
--limite
Content-Type: image/jpeg
Content-Transfer-Encoding: base64
...datos en base64...
--limite--     ← cierre del multipart (doble guión al final)
```

> [!IMPORTANT]
> El boundary **no puede aparecer** dentro de ninguna parte. Por eso los MUAs reales usan
> strings largos y raros (`000000000000a450ba06529106fd`). Apertura: `--limite`.
> Cierre: `--limite--`. Falta el `--` final → el mail queda roto.

### Adjuntos — `Content-Disposition`

El `Content-Type` dice **qué es**; el `Content-Disposition` dice **cómo mostrarlo**:

```
Content-Disposition: inline                              # mostrar dentro del mail
Content-Disposition: attachment; filename="notas.pdf"    # ofrecer como descarga
```

Mail con texto + un adjunto → `multipart/mixed`:

```
Content-Type: multipart/mixed; boundary="limite"

--limite
Content-Type: text/plain; charset="UTF-8"
Content-Transfer-Encoding: base64

wqFIb2xhIG11bmRvIQ0K
--limite
Content-Type: application/pdf; name="notas.pdf"
Content-Transfer-Encoding: base64
Content-Disposition: attachment; filename="notas.pdf"

JVBERi0xLjQKJeLjz9MKMyAwIG9iago8PC9UeXBl...
--limite--
```

```sh
# Generar el base64 del adjunto, cortado en lineas de 76
base64 -w 76 notas.pdf
```

> Si el nombre del archivo tiene acentos, va codificado con **RFC 2047**
> (`filename="=?UTF-8?B?...?="`).

### Multipart anidado (texto + HTML + adjunto)

Se meten unos dentro de otros, cada nivel con **su propio boundary**:

```
multipart/mixed; boundary="EXT"
├─ multipart/alternative; boundary="INT"
│   ├─ text/plain      ← para MUAs viejos
│   └─ text/html       ← el que prefiere el MUA moderno
└─ application/pdf  (Content-Disposition: attachment)
```

> En `multipart/alternative` el MUA muestra **la última parte que entiende** → poner
> siempre el `text/plain` **primero** y el formato rico después.

### Content-Transfer-Encoding

| Valor              | Cuándo usarlo                                            |
| ------------------ | -------------------------------------------------------- |
| `7bit`             | Solo ASCII 7 bits, líneas cortas                         |
| `base64`           | Datos binarios (imágenes, adjuntos)                      |
| `quoted-printable` | Texto mayormente ASCII con algunos caracteres especiales |

### Quoted-Printable

Representa caracteres no-ASCII como `=HH` (hex). Ej: `=C3=B1` es `ñ`, `=3D` es `=`.

Reglas que se olvidan siempre:

- El `=` literal **debe** escribirse `=3D`.
- Líneas de máximo 76 caracteres; si hay que cortar, se termina la línea con `=`
  (soft line break, no cuenta como salto real).
- Espacio/tab al final de línea → `=20` / `=09`.

```sh
# Codificar / decodificar quoted-printable
echo "¡Hola mundo!" | qprint -e        # o: python3 -c "..."
printf '=C2=A1Hola mundo!' | qprint -d
```

> [!WARNING]
> Si el enunciado dice **"debe poder leerlo un MUA que no soporte quoted-printable"**,
> entonces NO uses `quoted-printable`. Usá `base64`, que todo MUA MIME entiende.

---

## RFC 2047 — caracteres no-ASCII en los HEADERS

Los headers son **ASCII de 7 bits**. `Content-Transfer-Encoding` codifica el **cuerpo**,
no la cabecera. Entonces un `Subject: ¡Buenos días!` crudo está **mal**.

Solución: *encoded-word*

```
=?charset?encoding?texto-codificado?=
         ^ B = base64   Q = quoted-printable (variante header)
```

Ejemplos:

```
Subject: =?UTF-8?B?wqFCdWVub3MgZMOtYXMh?=
Subject: =?UTF-8?Q?=C2=A1Buenos_d=C3=ADas!?=
```

```sh
# Armar el encoded-word en base64
printf '¡Buenos días!' | base64
# wqFCdWVub3MgZMOtYXMh

# Decodificarlo
echo 'wqFCdWVub3MgZMOtYXMh' | base64 -d
```

Reglas:

- Máximo **75 caracteres** por encoded-word. Si no entra, se parten en varios
  encoded-words separados por espacio/CRLF+espacio.
- En la variante `Q` el **espacio se escribe `_`** (o `=20`), no como espacio literal.
- Aplica a `Subject:`, al *display name* de `From:`/`To:`, a nombres de adjunto.
  **Nunca** a la dirección de mail en sí (`<flopezllopis@itba.edu.ar>` va tal cual).

```
From: =?UTF-8?Q?Mart=C3=ADn_P=C3=A9rez?= <mperez@itba.edu.ar>
```

---

## Base64

```sh
# Codificar
echo "hola mundo" | base64

# Decodificar
echo "aG9sYSBtdW5kbwo=" | base64 -d

# Decodificar contenido de mail
echo "UGVybyBxIGJ1ZW5v..." | base64 -d
```

**Tamaño**: base64 convierte 3 bytes → 4 caracteres, por lo tanto el tamaño es `⌈original × 4/3⌉`.  
Si tengo 9 MB y el límite es 10 MB: `9 × 4/3 = 12 MB` → **no entra**.

→ Ver [[guia_respuestas#E63|E63]], [[guia_respuestas#E65|E65]], [[Ejercicio_integrador#papopepoparapapapapiparapopepo]]

---

## Autenticación de mails (anti-spam)

| Mecanismo | Cómo funciona | Limitación |
|---|---|---|
| **SPF** | Registro TXT en DNS con IPs autorizadas para enviar | Se rompe con forwarding |
| **DKIM** | Firma criptográfica en cada mail, clave pública en DNS | Más complejo de configurar |
| **Greylisting** | Rechazo temporal 4xx al primer intento (los spambots no reintentan) | Demora el primer mail |
| **Filtros bayesianos** | Estadística sobre palabras del contenido | Requiere entrenamiento |

```sh
# Ver registro SPF del ITBA
dig TXT itba.edu.ar

# Ver registros MX
dig MX itba.edu.ar
```

→ Ver [[guia_respuestas#E61|E61]], [[guia_respuestas#E62|E62]]

---

## TLS / SMTP seguro

| Puerto | Protocolo |
|---|---|
| 25 | SMTP (texto plano, entre servidores) |
| 587 | SMTP con STARTTLS (envío desde cliente) |
| 465 | SMTPS (SSL/TLS desde el inicio) |
| 993 | IMAPS |
| 995 | POP3S |
| 443 | HTTPS |

**STARTTLS**: permite "subir" una conexión de texto plano a TLS sin cambiar de puerto. Se inicia con el comando `STARTTLS` en la sesión SMTP.

---

## Ver a qué servidor SMTP hay que conectarse

Para enviar un mail a `usuario@dominio.com`, el MTA mira el registro **MX** de `dominio.com`:

```sh
dig MX dominio.com
# Resultado: 10 mail.dominio.com.  ← conectarse al puerto 25 de esta IP
```

### Ejemplo: mandar mail a itba.edu.ar

```sh
# 1. Descubrir el servidor de mail del dominio
dig MX itba.edu.ar
# Resultado: itba-edu-ar.mail.protection.outlook.com.  ← ese es el servidor

# 2. Conectarse a ese servidor y mandar el mail
nc -C itba-edu-ar.mail.protection.outlook.com 25
```

```
EHLO localhost
MAIL FROM: <rohernandez@itba.edu.ar>
RCPT TO: <destinatario@itba.edu.ar>
DATA
...
.
QUIT
```

> [!NOTE]
> El resultado de `dig MX` puede cambiar. Siempre correr el dig antes de conectarse — no hardcodear el hostname del MX.

→ Ver [[notas/4_mail-tls-ssl#Pregunta 4|Pregunta Mail 4]]

---

## Conectarse a servidores reales (TLS / herramientas)

`nc` no habla TLS. Para puertos 465/993/995 o para hacer STARTTLS:

```sh
# SMTPS (465) — TLS desde el principio
openssl s_client -crlf -connect mail.sebikul.com:465

# SMTP + STARTTLS (587)
openssl s_client -crlf -starttls smtp -connect mail.sebikul.com:587

# POP3S (995)
openssl s_client -crlf -connect mail.sebikul.com:995

# POP3 plano (110)
nc -C mail.sebikul.com 110
```

`-crlf` en openssl cumple el mismo rol que `-C` en netcat: manda CRLF.

> [!NOTE]
> El usuario POP3 a veces es la **dirección completa** (`12345@mail.sebikul.com`),
> no solo la parte local. Si `USER legajo` da `-ERR`, probá con la dirección entera.

---

## Ejercicio tipo parcial — resuelto paso a paso

> Enviar un mail cumpliendo estándares y buenas prácticas que:
> a) tenga el header `X-Parcial: 2024/2`; b) subject `¡Buenos días!`;
> c) remitente con nombre, apellido y cuenta del ITBA; d) cuerpo `¡Hola mundo!`;
> e) se entregue a `{legajo}@mail.sebikul.com`;
> f) lo pueda leer un MUA que **no** soporte quoted-printable.
> Verificar recepción por POP3 en `mail.sebikul.com`.

### 1. Desarmar el enunciado

| Requisito | Qué implica |
|---|---|
| (a) header propio | `X-Parcial: 2024/2` — prefijo `X-` |
| (b) subject con `¡` y `í` | no-ASCII en header → **RFC 2047 encoded-word** |
| (c) remitente completo | `From: Nombre Apellido <cuenta@itba.edu.ar>` |
| (d) cuerpo con `¡` | no-ASCII en cuerpo → `charset=UTF-8` + encoding |
| (f) sin quoted-printable | el encoding del cuerpo **y** del encoded-word debe ser **base64** (`?B?`) |
| (e) entrega | `RCPT TO:` + resolver el MX del dominio |
| buenas prácticas | `Date`, `To`, `Message-ID`, `MIME-Version` |

### 2. Preparar los datos

```sh
dig MX mail.sebikul.com        # a qué servidor conectarse
date -R                        # Date: válido

printf '¡Buenos días!' | base64      # → wqFCdWVub3MgZMOtYXMh   (subject)
printf '¡Hola mundo!
' | base64     # → wqFIb2xhIG11bmRvIQ0K   (cuerpo)
```

### 3. Sesión SMTP completa

```
EHLO itba.edu.ar
MAIL FROM: <flopezllopis@itba.edu.ar>
RCPT TO: <12345@mail.sebikul.com>
DATA
From: Facundo Lopez Llopis <flopezllopis@itba.edu.ar>
To: <12345@mail.sebikul.com>
Date: Sun, 26 Oct 2026 12:00:00 -0300
Subject: =?UTF-8?B?wqFCdWVub3MgZMOtYXMh?=
Message-ID: <parcial-2024-2-flopezllopis@itba.edu.ar>
X-Parcial: 2024/2
MIME-Version: 1.0
Content-Type: text/plain; charset="UTF-8"
Content-Transfer-Encoding: base64

wqFIb2xhIG11bmRvIQ0K
.
QUIT
```

> [!IMPORTANT]
> La **línea en blanco** entre headers y cuerpo es obligatoria. Sin ella, el
> `Content-Transfer-Encoding` se interpreta como texto y el mail llega roto.

### 4. Errores que cuestan puntos

- `Subject: ¡Buenos días!` crudo → header no-ASCII, **mal**.
- `=?UTF-8?Q?...?=` en el subject → es quoted-printable, viola (f).
- `Content-Transfer-Encoding: 8bit` → no es estándar interoperable.
- Olvidar `MIME-Version: 1.0` → el MUA no interpreta el base64.
- Olvidar `From:`/`Date:` porque ya se puso `MAIL FROM:` → son cosas distintas.
- Usar `nc` sin `-C` → el servidor nunca ve el fin de línea.

### 5. Verificar por POP3

```sh
nc -C mail.sebikul.com 110
```

```
USER 12345@mail.sebikul.com
PASS 12345@mail.sebikul.com
LIST
RETR 1
QUIT
```

Y decodificar lo que vuelve:

```sh
echo 'wqFIb2xhIG11bmRvIQ0K' | base64 -d     # ¡Hola mundo!
echo 'wqFCdWVub3MgZMOtYXMh' | base64 -d     # ¡Buenos días!
```

### Demostrar que el mail funcionó — las 3 pruebas

Un `250 Ok: queued` **no** alcanza (solo dice que lo aceptó, no que lo entregó). Mostrar:

```sh
# 1. mandar la sesión (corregida)
nc -C localhost 25

# 2. que Postfix lo ENTREGÓ (no solo que lo encoló)
sudo grep status=sent /var/log/mail.log      # buscar la línea status=sent
sudo tail -f /var/log/mail.log               # ver en vivo mientras lo mandás

# 3. leerlo de vuelta por POP3
nc -C localhost 110                          # USER / PASS / LIST / RETR 1
ls ~/Maildir/new/ && cat ~/Maildir/new/*     # o directo en el Maildir
```

> `status=sent` = entregado. `status=deferred` = reintentando (algo falla, ver el motivo
> en la misma línea). `status=bounced` = rechazado.
