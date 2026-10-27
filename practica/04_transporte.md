---
tags:
  - protos
  - practica
  - transporte
  - tcp
  - udp
  - guia
---

# Guía Práctica: Capa de Transporte (TCP/UDP)

---

## Netcat — herramienta universal

```sh
# Escuchar en un puerto (TCP)
nc -l <puerto>
nc -l <puerto> > archivo_recibido.txt   # guardar lo que llega

# Conectarse a un host:puerto
nc <ip> <puerto>

# Enviar contenido de un archivo
cat archivo.txt | nc <ip> <puerto>

# UDP: agregar -u
nc -u -l <puerto>
cat archivo.txt | nc -u <ip> <puerto>

# CRLF (para protocolos como SMTP/HTTP)
nc -C localhost 25

# Mantener el servidor abierto después de la primera conexión
nc -kl <puerto>
```

---

## ncat — el netcat de nmap (el que piden en el parcial)

`ncat` es el netcat que viene con nmap. Tiene flags que el `nc` clásico no tiene y que son
**los que se usan para armar servicios a mano**.

```sh
ncat -l <puerto>                    # servidor (socket pasivo)
ncat -l <ip> <puerto>               # servidor atado a UNA IP concreta
ncat -l <puerto> -k                 # iterativo: no muere al cerrarse la conexión
ncat -l <puerto> -k -c "<comando>"  # pipea la conexión a traves de un comando
ncat <host> <puerto>                # cliente
ncat --recv-only <host> <puerto>    # solo recibe; al cerrar el socket cierra stdout
ncat --send-only <host> <puerto>    # solo envia; al cerrar stdin cierra el socket
ncat -u ...                         # UDP
ncat --ssl <host> <puerto>          # TLS (lo que nc no sabe hacer)
```

| Flag | Qué hace |
|---|---|
| `-l` | socket pasivo, "modo servidor" |
| `-k` | servidor **iterativo**: en vez de terminar al cerrarse el socket, espera otra conexión |
| `-c "cmd"` | pipea los datos entrantes y salientes del socket a través de `cmd` |
| `--recv-only` | el socket solo recibe |
| `--send-only` | el socket solo envía |

### Servidores de una línea

```sh
# Echo server iterativo
ncat -l 8080 -k -c "cat"

# Server que contesta siempre lo mismo y cierra
ncat -l 8080 -k -c "echo hola"

# Server HTTP minimo
ncat -l 8080 -k -c "printf 'HTTP/1.1 200 OK
Content-Length: 5

hola
'"

# Servir un archivo una sola vez
ncat -l 8080 --send-only < index.html
```

> [!IMPORTANT]
> **Dos servicios distintos en el mismo puerto, según por qué IP entrás.**
> Ejercicio clásico. Se resuelve atando cada `ncat` a una IP distinta — el puerto es el
> mismo pero el socket es `(IP, puerto)`, así que no chocan:
>
> ```sh
> ncat -l 127.0.0.1  3333 -k -c "echo hola"    # responde a ncat 127.0.0.1 3333
> ncat -l 10.16.1.100 3333 -k -c "echo chau"   # responde a ncat 10.16.1.100 3333
> ```
>
> Cada uno en su terminal, o con `&` al final para mandarlos a background
> (después matarlos con `kill %1` / `pkill ncat`).

```sh
# Verificar que ambos quedaron escuchando y en qué IP
netstat -tlnp | grep 3333
ss -tlnp | grep 3333
```

> `0.0.0.0:3333` = escucha en todas las interfaces. `127.0.0.1:3333` = solo loopback.
> Si usás `ncat -l 3333` a secas, agarra **todas** las IPs y el segundo server no puede levantar.

→ Ver [[guia_respuestas#E74|E74]]

---

## nmap — escaneo de red y puertos

```sh
# Escaneo básico de puertos
nmap <ip>
nmap -p 22,80,443 <ip>          # puertos específicos
nmap -p 1-1024 <ip>             # rango
nmap -p- <ip>                    # todos los puertos (1-65535)
nmap -p 49000-50000 <ip>         # rango acotado

# Tipos de escaneo
sudo nmap -sS <ip>               # SYN scan (stealth, default, no completa handshake)
nmap -sT <ip>                    # TCP connect (sin sudo, completa handshake)
sudo nmap -sU <ip>               # UDP scan (lento)
sudo nmap -sn 192.168.0.0/24     # solo ver qué hosts están up en la red (sin escanear puertos, pings ips)

# Detección de servicios y OS
sudo nmap -sV <ip>               # detectar versiones de servicios
sudo nmap -O <ip>                # detectar sistema operativo
sudo nmap -A <ip>                # agresivo: versiones + OS + scripts + traceroute

# Velocidad
sudo nmap -T4 <ip>               # más rápido (T0=paranoid, T5=insane, default=T3)

# Descubrimiento de host
nmap -Pn <ip>                    # NO hacer ping previo — asumir que el host está vivo
```

> [!IMPORTANT]
> **`-Pn` es el flag que salva el parcial.** Por defecto nmap pinguea el host antes de
> escanear; si ICMP está bloqueado por un firewall, nmap lo da por caído y **no escanea
> ningún puerto** (`Host seems down`). Con `-Pn` escanea igual.

```sh
# Combo típico de parcial: host detrás de firewall, quiero servicios + versiones
sudo nmap -sS -Pn -sV <ip>
```

### NSE — scripts de nmap

```sh
nmap --script <nombre|categoria> <target>
nmap --script <nombre> --script-args "<clave>=<valor>" <target>

nmap --script-help <nombre>           # qué hace y qué args acepta
ls /usr/share/nmap/scripts/           # listar todos los scripts disponibles
```

Los que aparecen en los parciales:

```sh
# Probar un servidor DHCP: manda un DISCOVER por broadcast y muestra el OFFER
sudo nmap --script broadcast-dhcp-discover
sudo nmap --script broadcast-dhcp-discover     --script-args "broadcast-dhcp-discover.mac=AA:BB:CC:DD:EE:FF"

# Ver qué métodos de autenticación acepta un SSH
nmap --script ssh-auth-methods <ip>
```

> El nombre del arg lleva el **prefijo del script**: `broadcast-dhcp-discover.mac`, no `mac`.

```sh
nmap -sC <ip>                         # correr los scripts de la categoria "default"
```

### Guardar la salida de nmap

```sh
nmap -oN salida.txt <target>     # formato legible (normal)
nmap -oX salida.xml <target>     # XML
nmap -oG salida.gnmap <target>   # grepeable
nmap -oA salida <target>         # los tres a la vez (salida.nmap/.xml/.gnmap)
```

> Si el enunciado pide "adjuntar la evidencia del escaneo", `-oN` o `-oA` es la respuesta.

### Estados de un puerto en nmap

| Estado           | Significado                            |
| ---------------- | -------------------------------------- |
| `open`           | Hay un servicio escuchando             |
| `closed`         | Respondió con RST (no hay servicio)    |
| `filtered`       | Sin respuesta (probable firewall)      |
| `open\|filtered` | No se puede distinguir (típico de UDP) |

→ Ver [[guia_respuestas#E77|E77]], [[guia_respuestas#E78|E78]], [[Ejercicio_integrador#The Vaullt]]

---

## xinetd — exponer un servicio en un puerto sin escribir un servidor

`xinetd` es un **super-servidor**: escucha él los puertos y, cuando entra una conexión,
levanta el binario que vos le digas y le enchufa el socket a stdin/stdout.

```sh
sudo apt install xinetd
ls /etc/xinetd.d/            # servicios disponibles (echo, daytime, chargen, time...)
```

### Activar un servicio ya existente

Editar `/etc/xinetd.d/echo` y cambiar:

```
disable = yes     →     disable = no
```

### Crear un servicio propio

```sh
sudo apt install telnetd     # deja el binario en /usr/sbin/telnetd
```

`/etc/xinetd.d/telnet`:

```
service telnet {
    disable     = no
    id          = telnet
    socket_type = stream
    protocol    = tcp
    wait        = no
    user        = root
    server      = /usr/sbin/telnetd
}
```

| Campo | Qué significa |
|---|---|
| `disable` | `no` para que el servicio ande |
| `socket_type` | `stream` para TCP, `dgram` para UDP |
| `protocol` | `tcp` / `udp` |
| `wait` | `no` = un proceso por conexión (TCP). `yes` = un solo proceso (típico de UDP) |
| `user` | con qué usuario corre el binario |
| `server` | ruta absoluta al ejecutable |
| `port` | solo si el servicio no está en `/etc/services` |

```sh
systemctl restart xinetd
netstat -tulpn | grep xinetd     # verificar que esta escuchando
```

> [!NOTE]
> `wait = no` + `socket_type = stream` es la combinación para TCP. El binario lee de
> **stdin** y escribe a **stdout** — no tiene que saber nada de sockets. Por eso con xinetd
> podés exponer un script de shell como si fuera un servicio de red.

→ Ver [[Laboratorio#Xinetd]]

---

## Puertos de servicios comunes

| Servicio | Puerto | Protocolo |
|---|---|---|
| FTP | 21 | TCP |
| SSH | 22 | TCP |
| Telnet | 23 | TCP |
| SMTP | 25 | TCP |
| DNS | 53 | UDP/TCP |
| HTTP | 80 | TCP |
| POP3 | 110 | TCP |
| IMAP | 143 | TCP |
| HTTPS | 443 | TCP |
| daytime | 13 | TCP/UDP |
| time | 37 | TCP/UDP |

---

## TCP: 3-way handshake y cierre

### Apertura (3-way handshake)

```
Cliente  →  Servidor: SYN (Seq=x)
Servidor →  Cliente:  SYN+ACK (Seq=y, Ack=x+1)
Cliente  →  Servidor: ACK (Ack=y+1)
```

### Cierre (4-way)

```
A → B: FIN
B → A: ACK
B → A: FIN
A → B: ACK
```

### Flags TCP

| Flag | Uso |
|---|---|
| `SYN` | Iniciar conexión |
| `ACK` | Confirmación de recepción |
| `FIN` | Cerrar conexión de forma ordenada |
| `RST` | Cortar conexión abruptamente |
| `PSH` | Push datos directamente a la aplicación |
| `URG` | Datos urgentes |

---

## TCP vs UDP: cuándo usar cada uno

| | TCP | UDP |
|---|---|---|
| Orientado a conexión | ✅ | ❌ |
| Confiable (garantiza entrega) | ✅ | ❌ |
| Control de flujo y congestión | ✅ | ❌ |
| Overhead | Mayor (20 bytes header) | Menor (8 bytes header) |
| Demultiplexación | (IP src, puerto src, IP dst, puerto dst) | (IP dst, puerto dst) |
| Uso típico | HTTP, SSH, SMTP, FTP | DNS, streaming, VoIP |

---

## traceroute / tracepath

```sh
traceroute <ip o dominio>       # muestra cada salto (usa UDP por default)
traceroute -I <destino>         # usa ICMP en lugar de UDP
traceroute -T <destino>         # usa TCP
tracepath <destino>             # alternativa más simple
```

Funciona enviando paquetes con TTL=1, 2, 3... Los routers intermedios devuelven ICMP Time Exceeded cuando el TTL llega a 0.

→ Ver [[guia_respuestas#E79|E79]], [[guia_respuestas#E80|E80]]

---

## Fragmentación IP

Si un paquete supera el **MTU** (Maximum Transmission Unit, típicamente 1500 bytes en Ethernet):
- IP fragmenta el paquete
- Los fragmentos tienen el mismo **ID**
- El campo **Offset** indica la posición de cada fragmento (en bloques de 8 bytes)
- El flag **MF** (More Fragments) = 1 en todos excepto el último

Overhead de headers: UDP=8B, IPv4=20B, Ethernet=24B → payload disponible = MTU − 52

→ Ver [[guia_respuestas#E81|E81]], [[notas/6_Red#Pregunta 3|Pregunta Red 3]]

---

## Wireshark: qué buscar

| Situación | Qué ver en Wireshark |
|---|---|
| TCP conectado | SYN → SYN+ACK → ACK al inicio |
| TCP rechazado | SYN → RST+ACK |
| UDP enviado | Solo los datagramas, sin handshake |
| Forwarding IP | Las MACs cambian en cada salto, las IPs no |
| DHCP | DISCOVER → OFFER → REQUEST → ACK |
| ARP | Broadcast request → unicast reply |

→ Ver [[guia_respuestas#E73|E73]], [[guia_respuestas#E75|E75]], [[guia_respuestas#E76|E76]]

---

## Tabla de estados TCP (lo que muestra `netstat`)

```sh
netstat -tulpn        # ver puertos escuchando
netstat -an           # ver todas las conexiones con estados
```

| Estado | Significado |
|---|---|
| `LISTEN` | Esperando conexiones entrantes |
| `SYN_SENT` | SYN enviado, esperando SYN+ACK |
| `ESTABLISHED` | Conexión activa |
| `TIME_WAIT` | Esperando que expiren paquetes en tránsito |
| `CLOSE_WAIT` | Recibió FIN del otro extremo |

---

## ICMP

```sh
ping <ip>                  # envía ICMP Echo Request, espera Echo Reply
ping -c 4 <ip>             # solo 4 pings
ping -s 4000 <ip>          # paquetes grandes (para probar fragmentación)
```

Tipos de mensajes ICMP relevantes:
- **Echo Request/Reply** (ping)
- **Destination Unreachable** (el destino no es alcanzable)
- **Time Exceeded** (TTL=0 → usado por traceroute)
- **Redirect** (hay un gateway mejor)
