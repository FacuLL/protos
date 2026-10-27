---
tags:
  - protos
  - practica
  - red
  - ip
  - dhcp
  - nat
  - routing
  - guia
---

# Guía Práctica: Capa de Red (IP, DHCP, NAT, Routing)

---

## Comandos de red esenciales

```sh
# Ver interfaces y sus IPs
ifconfig
ip addr

# Asignar IP a una interfaz
ifconfig <interfaz> <ip>/<bits>
ip addr add <ip>/<bits> dev <interfaz>
ip link set <interfaz> up

# Ver tabla de ruteo
route -n         # formato clásico (usar en parcial)
ip route         # formato moderno

# Agregar ruta
route add -net <ip>/<bits> [gw <gateway>] [dev <interfaz>]
ip route add <ip>/<bits> via <gateway>
ip route add <ip>/<bits> via <gateway> dev <interfaz>

# Habilitar forwarding (hacer que un host funcione como router)
sysctl net.ipv4.ip_forward=1

# Ver puertos abiertos
netstat -tulpn
```

→ Ver [[Laboratorio#IP]] y [[Ejercicio_integrador#Inicio]]

---

## Subnetting — fórmulas clave

| Lo que quiero saber | Fórmula |
|---|---|
| Bits para hosts | `n bits de host` |
| Cantidad de hosts usables | `2^n - 2` (sin dirección de red ni broadcast) |
| Dirección de red | IP AND máscara |
| Broadcast | Dirección de red OR (NOT máscara) |
| Bits necesarios para k subredes | `⌈log₂(k)⌉` bits |
| Hosts necesarios para N hosts | `⌈log₂(N+2)⌉` bits |

### Máscaras por prefijo

| /prefijo | Máscara | Hosts usables |
|---|---|---|
| /24 | 255.255.255.0 | 254 |
| /25 | 255.255.255.128 | 126 |
| /26 | 255.255.255.192 | 62 |
| /27 | 255.255.255.224 | 30 |
| /28 | 255.255.255.240 | 14 |
| /29 | 255.255.255.248 | 6 |
| /30 | 255.255.255.252 | 2 |

### Truco para verificar si una IP pertenece a una red

Hacer AND entre la IP y la máscara. Si da la dirección de red, pertenece.

```
IP: 192.168.1.93   = 1100 0000.1010 1000.0000 0001.0101 1101
Máscara /27 = 255.255.255.224 = ...1110 0000
AND:                                              0101 1100 = 92 = 0101 1100 
¿Es .64? → red es 64 (0100 0000), broadcast es 95 (0101 1111)
93 está entre 65-94 → SI pertenece
```

→ Ver [[notas/6_Red#Preguntas|Preguntas IP]]

---

## DHCP — proceso DORA

```
D → Discover: cliente hace broadcast buscando servidor DHCP
O → Offer:    servidor ofrece una IP
R → Request:  cliente pide formalmente la IP ofrecida (broadcast)
A → ACK:      servidor confirma la asignación
```

### Instalar y configurar servidor DHCP (en R)

```sh
sudo apt install isc-dhcp-server

# Matar NetworkManager primero
sudo systemctl stop NetworkManager.service

# Darle IP fija a la interfaz que mira al cliente
sudo ip addr add 192.168.100.1/24 dev enp0s8
```

Editar `/etc/dhcp/dhcpd.conf`:

```
subnet 192.168.100.0 netmask 255.255.255.0 {
    range 192.168.100.10 192.168.100.50;
    option domain-name-servers 1.1.1.1;
    option subnet-mask 255.255.255.0;
    option routers 192.168.100.1;
    option broadcast-address 192.168.100.255;
    default-lease-time 20;
    max-lease-time 600;

    # IP fija para un host específico
    host maquina_h {
        hardware ethernet aa:bb:cc:dd:ee:ff;
        fixed-address 192.168.100.5;
        option host-name "maquina-H";
    }
}
```

Editar `/etc/default/isc-dhcp-server` → configurar la interfaz que mira al cliente (ej: `enp0s8`).

```sh
systemctl restart isc-dhcp-server
systemctl status isc-dhcp-server
journalctl -xeu isc-dhcp-server   # ver logs de error
```

### Probar el servidor DHCP sin tener un cliente

```sh
# Manda un DISCOVER por broadcast y muestra el OFFER que devuelve el server
sudo nmap --script broadcast-dhcp-discover

# Simulando una MAC puntual — sirve para verificar la reserva de IP fija
sudo nmap --script broadcast-dhcp-discover     --script-args "broadcast-dhcp-discover.mac=0B:08:27:AE:C8:6A"
```

Si la reserva está bien hecha, el OFFER tiene que traer la `fixed-address`, no una IP del
`range`. También sirve para chequear `domain-name-servers`, `routers` y los lease times.

```sh
# Ver las concesiones ya entregadas
cat /var/lib/dhcp/dhcpd.leases
```

### Denegar DHCP a un host

```
host maquina_h {
    hardware ethernet <mac>;
    deny booting;
}
```

---

### Corregir errores en un `dhcpd.conf` (ejercicio típico)

**Validar PRIMERO** — el equivalente a `named-checkzone`. Dice la línea exacta del error:

```sh
dhcpd -t                               # testea /etc/dhcp/dhcpd.conf
dhcpd -t -cf /etc/dhcp/dhcpd.conf      # testear un archivo puntual
dhcpd -T                               # ademas testea el archivo de leases
```

> Si `dhcpd -t` da `Configuration file errors encountered`, el servicio **no arranca**.
> `systemctl status` muestra el mismo error. Siempre correrlo antes de reiniciar.

#### Error #1: `option` que sobra o falta

La mitad de los errores plantados son esto. Hay keywords que **llevan** `option` y otras que **no**:

| **SIN** `option` (parámetros del server) | **CON** `option` (se le mandan al cliente) |
|---|---|
| `range` | `option routers` |
| `default-lease-time` | `option subnet-mask` |
| `max-lease-time` | `option broadcast-address` |
| `hardware ethernet` | `option domain-name-servers` |
| `fixed-address` | `option domain-name` |
| `deny booting` | `option host-name` |

> `routers 192.168.100.1;` → **mal** (falta `option`). `option range ...;` → **mal** (sobra).

#### Error #2: valores incoherentes

| Regla | Mal | Bien |
|---|---|---|
| El `range` tiene que estar **dentro** de la subred | subnet `192.168.100.0/24` con `range 192.168.1.10 ...` | `range 192.168.100.10 192.168.100.50` |
| `option routers` = un gateway **dentro** de la subred | `option routers 10.0.0.1` en subnet `192.168.100.0` | `option routers 192.168.100.1` |
| `fixed-address` dentro de la subred (y mejor **fuera** del range, para no pisar) | `fixed-address 192.168.5.5` | `fixed-address 192.168.100.5` |
| `netmask` coherente con el prefijo | `subnet 192.168.100.0 netmask 255.255.0.0` | `netmask 255.255.255.0` |
| `max-lease-time >= default-lease-time` | `default 600` / `max 20` | `default 20` / `max 600` |
| MAC válida (6 bytes hex) | `hardware ethernet AA:BB:CC:DD:EE` | 6 octetos |

#### Error #3: sintaxis

- **Falta `;`** al final de una sentencia — el error más común. **Toda** línea termina en `;`
  (incluida `hardware ethernet ...;` dentro del `host`).
- **Múltiples valores van separados por COMA**, no por espacio:
  `option domain-name-servers 8.8.8.8 8.8.4.4;` → **mal**;
  `option domain-name-servers 8.8.8.8, 8.8.4.4;` → bien. Idem `option routers a, b;`.
- **Llaves `{ }`** sin cerrar, o un `host`/`subnet` sin su bloque.
- La IP de `subnet` tiene que ser la **dirección de red** del par IP/máscara, no un host:
  `subnet 192.168.100.0 netmask 255.255.0.0` es inválido (`/16` → la red es `192.168.0.0`) →
  `dhcpd -t` tira `bad subnet number/mask combination`. Arreglar la máscara (`255.255.255.0`)
  o la dirección de red (`192.168.0.0`).

#### Error #4: el servidor arranca pero no entrega IPs

- **No hay una `subnet` para la red de la interfaz.** El server **exige** una declaración
  `subnet`/`netmask` que matchee la red de **cada** interfaz por la que escucha, aunque
  esté vacía. Si no, tira `No subnet declaration for enp0s8`.
- La interfaz en `/etc/default/isc-dhcp-server` (`INTERFACESv4="enp0s8"`) no es la que mira al cliente.
- Falta `authoritative;` → el server no manda **DHCPNAK** cuando un cliente pide una IP
  inválida (necesario para el ejercicio de "rechazar" y para ser el DHCP oficial de la red):

```
authoritative;     # va en el scope global, arriba de todo

subnet 192.168.100.0 netmask 255.255.255.0 {
    ...
}
```

#### Scope: global vs. subnet

Una `option` **fuera** de todo bloque es global (aplica a todas las subredes). **Dentro** de
un `subnet {}` o `host {}` pisa a la global solo para ese scope.

```
option domain-name-servers 1.1.1.1;    # global: para todos

subnet 192.168.100.0 netmask 255.255.255.0 {
    option routers 192.168.100.1;        # solo para esta subred
    host impresora {
        fixed-address 192.168.100.8;     # solo para este host
    }
}
```

→ Ver [[guia_respuestas#E88|E88]], [[guia_respuestas#E91|E91]], [[guia_respuestas#E92|E92]], [[Laboratorio#DHCP]], [[2025_2c_practico#Ejercicio 1]]

---

## NAT con iptables

```sh
# Ver tabla NAT
iptables -t nat -L
iptables -t nat -L --line-numbers   # con números de línea

# Borrar una regla
iptables -t nat -D <número>

# SNAT (enmascarar tráfico saliente — para que H salga a internet a través de R)
iptables -t nat -A POSTROUTING -o <interfaz_salida> -j MASQUERADE

# DNAT (redirigir tráfico entrante — exponer un servicio interno)
iptables -t nat -A PREROUTING -p tcp --dport <puertoR> -i <interfaz_interna> -j DNAT --to <ipH>:<puertoH>
```

> SNAT se aplica después del ruteo (POSTROUTING). DNAT se aplica antes (PREROUTING).

→ Ver [[Laboratorio#Salir a internet]]

---

## Routing — agregar rutas manualmente

```sh
# Ruta a una red específica via un gateway
route add -net 192.168.124.0/24 gw 192.168.123.200
ip route add 192.168.124.0/24 via 192.168.123.200

# Ruta default (para todo lo que no matchee otras rutas)
route add default gw 192.168.1.1
ip route add default via 192.168.1.1
```

→ Ver [[Ejercicio_integrador#Inicio]]

---

## Tablas de ruteo con VPN — full tunnel vs split tunnel

Ejercicio típico: *"dibujá la tabla de ruteo"*. Contexto de ejemplo: IP local `192.168.3.2`,
red local `192.168.3.0/24`, router `192.168.3.1`, servidor VPN en `24.232.1.1`,
red interna de la VPN `10.3.0.0/24`, gateway VPN `10.3.0.1`, interfaz del túnel `vpn0`.

### Full tunnel — **todo** el tráfico sale por la VPN

| Red | Máscara | Interfaz | Gateway |
|---|---|---|---|
| 127.0.0.0 | /8 | lo | — |
| 192.168.3.2 | /32 | lo | — |
| 192.168.3.0 | /24 | eth0 | — |
| **0.0.0.0** | **/0** | **vpn0** | **10.3.0.1** |
| 10.3.0.0 | /24 | vpn0 | — |
| **24.232.1.1** | **/32** | **eth0** | **192.168.3.1** |

> [!IMPORTANT] La ruta `/32` al servidor VPN es obligatoria
> Sin ella, los paquetes que **sostienen el túnel** matchearían la default y querrían salir
> por `vpn0` → **loop infinito** (el túnel intentando viajar dentro de sí mismo).
> La ruta `/32` es más específica, gana el longest-prefix match, y manda ese tráfico por `eth0`.

### Split tunnel — internet sale normal, la VPN solo para la red interna

| Red | Máscara | Interfaz | Gateway |
|---|---|---|---|
| 127.0.0.0 | /8 | lo | — |
| 192.168.3.2 | /32 | lo | — |
| 192.168.3.0 | /24 | eth0 | — |
| **0.0.0.0** | **/0** | **eth0** | **192.168.3.1** |
| 10.3.0.0 | /24 | vpn0 | — |

> Acá **no hace falta** la ruta `/32`: la default ya sale por `eth0`, así que los paquetes
> del túnel llegan al servidor VPN sin riesgo de loop.

| | Full tunnel | Split tunnel |
|---|---|---|
| Ruta default | `vpn0` via gw de la VPN | `eth0` via router local |
| Ruta `/32` al server VPN | **obligatoria** | no hace falta |
| Tráfico a internet | sale con la IP de la VPN | sale con tu IP real |
| Uso | privacidad / saltar bloqueos geográficos | solo acceder a recursos internos |

> [!NOTE] Regla general que resuelve estos ejercicios
> El kernel elige **siempre la ruta con el prefijo más largo** (más específica), sin importar
> el orden en la tabla. `/32` le gana a `/24`, que le gana a `/0`.

```sh
ip route get 8.8.8.8          # pregunta cual ruta usaria el kernel para ese destino
ip route get 10.3.0.5
```

→ Ver [[Laboratorio#Tablas de routeo con vpn]]

---

## Routing dinámico — resumen conceptual

| Protocolo | Tipo | Métrica | Límite | Uso |
|---|---|---|---|---|
| **RIP v1** | Distance Vector | Saltos | 15 hops | Redes pequeñas, sin VLSM |
| **RIP v2** | Distance Vector | Saltos | 15 hops | Redes medianas con VLSM |
| **OSPF** | Link State | Costo | Sin límite | Redes grandes, convergencia rápida |
| **BGP** | Path Vector | Políticas | — | Entre sistemas autónomos (ISPs) |

**Distance Vector (RIP)**: cada router solo conoce el camino a través de sus vecinos. Problema: **cuenta al infinito**.

**Link State (OSPF)**: cada router tiene mapa completo de la red. Usa Dijkstra. Converge más rápido.

### Instalar RIP con FRR

```sh
sudo apt install frr

# Habilitar RIP
# En /etc/frr/daemons: ripd=no → ripd=yes

sudo systemctl restart frr
sudo systemctl status frr
```

Después hay que **configurar** RIP. FRR se configura con `vtysh` (una CLI tipo Cisco):

```sh
sudo vtysh
```

```
configure terminal
router rip
 version 2                       # v2 soporta VLSM/CIDR; v1 no
 network 192.168.100.0/24        # anunciar esta red por RIP
 network enp0s8                  # y/o mandar RIP por esta interfaz
 no passive-interface enp0s8     # permitir mandar updates por ahi
end
write memory                     # guardar la config
```

Verificar:

```
show ip rip                      # rutas aprendidas por RIP
show ip route rip                # las que entraron a la tabla de ruteo
show running-config              # toda la config actual
```

> También se puede editar directo `/etc/frr/frr.conf` con los mismos comandos y
> `systemctl restart frr`. RIP manda updates cada 30s por broadcast/multicast; esperar
> a que converja.

> [!NOTE]
> Sin `ip_forward=1` el router no reenvía aunque RIP aprenda las rutas:
> `sudo sysctl -w net.ipv4.ip_forward=1`.

→ Ver [[guia_respuestas#E93|E93]], [[notas/7_Routing|Routing]]

---

## ICMP y diagnóstico

```sh
ping <ip>                    # verificar conectividad básica
ping -c 4 <ip>               # 4 pings
traceroute <ip>              # ruta de saltos hasta el destino
traceroute -I <ip>           # con ICMP en lugar de UDP
```

---

## Opciones de red en VirtualBox

| Modo | Descripción |
|---|---|
| **NAT** | La VM usa la IP del host para salir. No es accesible desde afuera |
| **Bridge** | La VM tiene su propia IP en la red física |
| **Internal** | Solo VMs entre sí, sin acceso al host ni internet |
| **Host-Only** | Red privada entre host y VMs, sin internet |
| **Red NAT** | Como NAT pero las VMs se ven entre sí |

Para configurar 2 VMs conectadas entre sí: usar **Internal Network** con el mismo nombre en ambas.

→ Ver [[Laboratorio#Opciones de red vm]]

---

## IPs reservadas

| Rango | Uso |
|---|---|
| `127.x.x.x` | Loopback |
| `10.x.x.x` | Red privada clase A |
| `172.16.x.x` a `172.31.x.x` | Red privada clase B |
| `192.168.x.x` | Red privada clase C |
| `169.254.x.x` | Link-local (APIPA, cuando no hay DHCP) |
| `224.x.x.x` a `239.x.x.x` | Multicast |
