---
tags:
  - protos
  - practica
  - guia
  - indice
---

# Índice — Apuntes Prácticos 72.07 Protocolos de Comunicación

Referencia de comandos y ejercicios para el parcial práctico.

---

## Temas

| # | Tema | Archivo | Temas clave |
|---|---|---|---|
| 01 | HTTP | [[01_http]] | curl, nginx, reverse proxy, leer config (alias/autoindex/auth), HTTPS/TLS |
| 02 | DNS | [[02_dns]] | dig, bind9, master/slave (AXFR), zona reversa (PTR), rndc |
| 03 | Mail | [[03_mail]] | SMTP (+AUTH), POP3/IMAP, MIME, RFC 2047, base64, SPF/DKIM |
| 04 | Transporte | [[04_transporte]] | TCP, UDP, nmap (+NSE), traceroute, netcat |
| 05 | Red / IP | [[05_red]] | subnetting, DHCP, NAT, iptables, routing |
| 06 | Enlace / ARP | [[06_enlace]] | arp, arping, ip neigh, ARP spoofing (MITM), forwarding |
| 07 | SSH | [[07_ssh]] | claves, SCP, tunnels -L/-R/-D |
| 08 | Sockets (C) | [[08_sockets]] | Berkeley API, TCP/UDP server/client, select |

---

## Ejercicios de referencia

- [[guia_respuestas]] — ejercicios resueltos de la guía (E1 → E104)
- [[Laboratorio]] — comandos y configuraciones del laboratorio
- [[Ejercicio_integrador]] — ejercicio integrador completo (HTTP + DNS + SSH + nmap + base64)

---

## Mapa parciales → cheatsheet

Qué hay que tener leído para resolver cada ejercicio de cada parcial.

| Parcial | Ej | Tema | Dónde está |
|---|---|---|---|
| [[2022_2c_practico]] | 2 | túnel SSH `-R` + `tail -f \| nc` | [[07_ssh#Remote Port Forwarding (-R)]] |
| [[2024_2c_practico]] | 1 | nginx reverse proxy, `proxy_set_header`, `$http_*` | [[01_http#Reverse proxy]] |
| [[2024_2c_practico]] | 2 | curl proxy SOCKS5 + Basic Auth + headers | [[01_http#curl — flags esenciales]] |
| [[2024_2c_practico]] | 3 | `ip route add`, `nmap -sS -Pn -sV`, traceroute | [[05_red#Routing — agregar rutas manualmente]], [[04_transporte#nmap — escaneo de red y puertos]] |
| [[2024_2c_practico]] | 4 | SMTP manual + MIME + RFC 2047 + POP3 | [[03_mail]] |
| [[2025_2c_practico]] | 1 | servidor DHCP, reserva por MAC | [[05_red#DHCP — proceso DORA]] |
| [[2025_2c_practico]] | 2 | `nmap -sn`, `-p-`, traceroute | [[04_transporte#nmap — escaneo de red y puertos]] |
| [[2025_2c_practico]] | 3 | errores en archivo de zona BIND | [[02_dns#Diagnóstico de errores comunes]] |
| [[2025_2c_practico]] | 4 | nginx HTTPS + cert self-signed + trust store | [[01_http#HTTPS con nginx — certificado self-signed]] |
| [[Parcial 2026 1C]] | 1 | zona BIND completa (SOA, NS, MX, CNAME, SPF) | [[02_dns#Configurar servidor BIND9]] |
| [[Parcial 2026 1C]] | 2 | nginx reverse proxy + `/etc/hosts` | [[01_http#Reverse proxy]] |
| [[Parcial 2026 1C]] | 3 | curl POST + SOCKS5h + auth + headers | [[01_http#curl — flags esenciales]] |
| [[Parcial 2026 1C]] | 4 | túnel SSH `-R` + `tail -f \| nc` | [[07_ssh#Remote Port Forwarding (-R)]] |

> [!NOTE]
> Ningún parcial práctico tomó sockets en C todavía — [[08_sockets]] queda para el teórico.
> Enlace ([[06_enlace]]) sí puede caer en el lab (ARP spoofing / forwarding).

---

## Cheatsheet rápido por herramienta

### curl
```sh
curl <url>                                              # GET
curl -X POST <url> -H "Content-Type: application/json" -d '{"k":"v"}'
curl -H "Accept-Language: es" <url>                    # negociación de contenido
curl -H "If-None-Match: \"etag\"" <url>                # caché condicional
curl -i <url>                                          # ver headers de respuesta
curl -I <url>                                          # solo headers (HEAD)
```

### nmap
```sh
sudo nmap -sS <ip>                    # stealth scan
sudo nmap -sU <ip>                    # UDP scan
sudo nmap -sV <ip>                    # detección de versiones
sudo nmap -p 49000-50000 <ip>         # rango de puertos
sudo nmap -O <ip>                     # detección de OS
```

### dig
```sh
dig <dominio>                         # A record
dig <dominio> MX                      # servidores de mail
dig <dominio> SOA                     # info de zona (serial)
dig <dominio> +trace                  # traza completa
dig <dominio> @<dns-server>           # usar un DNS específico
```

### SSH tunnels
```sh
ssh -L <local>:<host>:<remoto> user@server   # acceder al remoto desde local
ssh -R <remoto>:<host>:<local> user@server   # exponer local en el servidor
ssh -D <local> user@server                   # proxy SOCKS
```

### netcat
```sh
nc -l <puerto>                        # escuchar (TCP)
nc -u -l <puerto>                     # escuchar (UDP)
nc -C localhost 25                    # SMTP (con CRLF)
cat archivo | nc <ip> <puerto>        # enviar archivo
```

### iptables NAT
```sh
iptables -t nat -A POSTROUTING -o <iface> -j MASQUERADE          # SNAT
iptables -t nat -A PREROUTING -p tcp --dport <p> -j DNAT --to <ip>:<p>  # DNAT
iptables -t nat -L --line-numbers                                 # ver reglas
iptables -t nat -D <nro>                                          # borrar regla
```

### arp
```sh
arp -n                                # ver tabla
arp -s <ip> <mac>                     # entrada estática
sudo arp -d <ip>                      # borrar entrada
```

### Tabla de ruteo
```sh
route -n                              # ver tabla
ip route                              # ver tabla (moderno)
ip route add <red>/<mask> via <gw>    # agregar ruta
sysctl net.ipv4.ip_forward=1          # habilitar forwarding
```
