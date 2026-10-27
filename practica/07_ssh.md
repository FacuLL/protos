---
tags:
  - protos
  - practica
  - ssh
  - tunnels
  - guia
---

# Guía Práctica: SSH y Tunnels

---

## Conexión básica

```sh
ssh usuario@host
ssh usuario@host -p 2222          # puerto distinto al 22
ssh usuario@host -v               # verbose (para debugging)
ssh usuario@host -i ./clave       # usar clave privada específica
ssh usuario@host -C               # compresión de datos

# Con ProxyCommand (tunnel a través de intermediario)
ssh -o ProxyCommand="docker run --rm -i cloudflare/cloudflared access ssh --hostname %h" usuario@host
```

→ Ver [[Ejercicio_integrador#Como conectarse]]

---

## Claves SSH

### Generar par de claves

```sh
ssh-keygen                        # genera id_rsa + id_rsa.pub (RSA)
ssh-keygen -t ed25519             # más moderno y seguro
ssh-keygen -t rsa                 # RSA explícito
# La clave privada queda en ~/.ssh/id_rsa
# La clave pública en ~/.ssh/id_rsa.pub
```

### Copiar clave pública al servidor

```sh
ssh-copy-id usuario@host          # copia ~/.ssh/id_rsa.pub a authorized_keys
ssh-copy-id -i ./clave.pub usuario@host  # especificar qué clave
```

### Dar permisos correctos a una clave descargada

```sh
chmod 600 ./clave_privada
ssh -i ./clave_privada usuario@host
```

→ Ver [[guia_respuestas#E100|E100]], [[Laboratorio#Protocolo SSH]]

---

## Archivos SSH importantes

| Archivo | Dónde | Para qué |
|---|---|---|
| `~/.ssh/known_hosts` | Cliente | Claves públicas de servidores conocidos |
| `~/.ssh/authorized_keys` | Servidor | Claves públicas de clientes autorizados |
| `~/.ssh/id_rsa` | Cliente | Tu clave privada (nunca compartir) |
| `~/.ssh/id_rsa.pub` | Cliente | Tu clave pública (se copia al servidor) |
| `/etc/ssh/sshd_config` | Servidor | Configuración del servidor SSH |

---

## Transferencia de archivos

```sh
# Copiar archivo local → remoto
scp ./archivo usuario@host:/ruta/destino/

# Copiar archivo remoto → local
scp usuario@host:/ruta/archivo ./local/

# Con clave específica
scp -i ./clave usuario@host:/etc/passwd ./passwd_copia.txt
```

→ Ver [[guia_respuestas#E101|E101]]

---

## Port Forwarding — los 3 tipos

### Local Port Forwarding (-L)

**"Accedo desde mi PC a algo que solo es visible desde el servidor SSH"**

```sh
ssh -L <puerto_local>:<host_destino>:<puerto_destino> usuario@servidor_ssh
```

```sh
# Ejemplo: acceder a la base de datos en localhost:5432 del servidor, desde mi puerto local 1234
ssh -L 1234:localhost:5432 usuario@servidor

# Ahora desde mi PC:
psql -h localhost -p 1234

# Ejemplo: acceder a google.com:80 a través de pampero, en mi puerto 8080
ssh -L 8080:google.com:80 rohernandez@pampero.itba.edu.ar
curl localhost:8080
```

→ Ver [[guia_respuestas#E104|E104]], [[Laboratorio#Tunel]]

---

### Remote Port Forwarding (-R)

**"Expongo un servicio de mi PC en un puerto del servidor SSH"**

```sh
ssh -R <puerto_remoto>:<host_local>:<puerto_local> usuario@servidor_ssh
```

```sh
# Ejemplo: exponer mi puerto local 1234 en el puerto 9999 de pampero
ssh -R 9999:localhost:1234 rohernandez@pampero.itba.edu.ar

# Ahora desde pampero, conectarse a localhost:9999 es como conectarse a mi máquina en el 1234

# Caso del ejercicio: exponer mis luces (en la red local) en pampero
ssh -R 9090:luces:80 rohernandez@pampero.itba.edu.ar
# Korman en pampero hace: curl localhost:9090/...

# Caso clásico: exfiltrar /etc/passwd desde pampero a mi PC
# En mi PC, escucho en 1234:
nc -l 1234 > contrasenias.txt
# Abro el túnel:
ssh -R 9999:localhost:1234 rohernandez@pampero.itba.edu.ar
# Desde pampero:
cat /etc/passwd | nc localhost 9999
```

#### Variante: seguir un log remoto **en tiempo real**

Mismo túnel, pero con `tail -f` en vez de `cat` — el stream queda abierto y va bajando
cada línea nueva a medida que se escribe:

```sh
# 1. En mi PC: abrir el túnel inverso
ssh -R 5522:localhost:8080 rohernandez@pampero.itba.edu.ar

# 2. En mi PC (otra terminal): escuchar y volcar a un archivo
nc -l localhost 8080 > archivo.log

# 3. En pampero: enchufar el log al túnel
tail -f /tmp/parcial-20261 | nc localhost 5522

# 4. En mi PC: leerlo mientras llega
tail -f archivo.log
```

> [!NOTE]
> El `nc -l` tiene que estar escuchando **antes** de que pampero haga el `nc localhost 5522`,
> sino la conexión se rechaza. Si el server se cae tras la primera conexión, usar `nc -kl`.

→ Ver [[2022_2c_practico#Ejercicio 2]], [[Parcial 2026 1C#Ejercicio 4]]

→ Ver [[guia_respuestas#E101|E101]], [[guia_respuestas#E103|E103]]

---

### Dynamic Port Forwarding (-D)

**"Convierto al servidor SSH en un proxy SOCKS para navegar con su IP"**

```sh
ssh -D <puerto_local> usuario@servidor_ssh
```

```sh
# Crear proxy SOCKS en localhost:9090 usando pampero como salida
ssh -D 9090 rohernandez@pampero.itba.edu.ar

# Usar el proxy con curl (socks5 = resuelve DNS localmente)
curl -x socks://localhost:9090 ifconfig.me

# socks5h = el servidor SSH resuelve el DNS (más privado)
curl -x socks5h://localhost:9090 ifconfig.me

# Para el browser: configurar en Firefox/Chrome → proxy SOCKS 127.0.0.1:9090
```

→ Ver [[guia_respuestas#E102|E102]], [[Laboratorio#SSH]]

---

## Túneles que NO funcionan — el error clásico

```sh
ssh localhost -L 1234:127.0.0.1:1234
```

No anda: el túnel escucha en **tu** `127.0.0.1:1234` y reenvía a `127.0.0.1:1234`
**del servidor**… que es la misma máquina. El túnel apunta a sí mismo → loop
(o `bind: Address already in use`, porque el puerto local ya lo tomó el propio forward).

**Regla:** en `-L <local>:<host>:<remoto>`, el `<host>:<remoto>` se resuelve **desde el
servidor SSH**. Si origen y destino son la misma máquina, el forward no tiene sentido.
Los dos puertos tienen que ser distintos, o las máquinas distintas.

---

## Cuadro resumen de tunnels

| Flag | Nombre | Quién inicia la conexión | Caso de uso |
|---|---|---|---|
| `-L puerto_local:host:puerto` | Local port forwarding | Yo (desde mi PC) | Acceder a recursos internos del servidor |
| `-R puerto_remoto:host:puerto` | Remote port forwarding | Alguien en el servidor | Exponer mi servicio local en el servidor |
| `-D puerto_local` | Dynamic (SOCKS proxy) | Aplicaciones en mi PC | Navegar con la IP del servidor, saltar bloqueos |

---

## ssh-agent — no tipear passphrase cada vez

```sh
eval $(ssh-agent)             # iniciar el agente
ssh-add                       # agregar clave (pide passphrase una sola vez)
ssh-add -l                    # ver claves cargadas
ssh usuario@host              # ya no pide passphrase
```

---

## Warning de host key cambiada

Si ves este mensaje:
```
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@    WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!     @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
```

Significa que la clave del servidor cambió (o cambiaste de servidor manteniendo el mismo nombre en `/etc/hosts`).

```sh
# Borrar la entrada vieja de known_hosts
ssh-keygen -R <hostname>
# o editar ~/.ssh/known_hosts manualmente
```

→ Ver [[guia_respuestas#E99|E99]]

---

## Instalar servidor SSH

```sh
sudo apt install openssh-server
systemctl start ssh
systemctl status ssh

# Ver claves del servidor
ls -l /etc/ssh/ssh_host_*
```
