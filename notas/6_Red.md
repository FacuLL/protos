---
materia: protos
tipo: apuntes
---

# Capa de Red y Protocolos de Routing

---

## Servicios de la Capa de Red

El objetivo de la capa de red es **trasladar paquetes de un host a otro**, que pueden estar en distintas redes.

### Servicios Básicos
- **Encapsulamiento:** Colocar el dato o segmento dentro de un paquete/datagrama IP.
- **Forwarding (Reenvío):** Paso de paquetes de una interfaz de entrada a una de salida usando reglas locales (tablas de ruteo).
- **Routing (Enrutamiento):** Proceso de determinar la ruta que deben tomar los paquetes (algoritmos y protocolos de ruteo).

> [!NOTE]
> **Servicios Adicionales**
> Un protocolo de capa de red puede ofrecer: entrega garantizada, demora mínima garantizada, orientación a conexión, entrega en orden, ancho de banda mínimo, integridad de datos y encriptación.

### Redes de Datagramas vs. Circuitos Virtuales

| Característica | Datagrama (Internet) | Circuito Virtual |
| :--- | :--- | :--- |
| Establecer conexión | No requerido | Requerido |
| Direccionamiento | ID de host origen y destino | Número de CV |
| Info de estado | No | Tabla de subred con números de CV en routers |
| Enrutamiento | Cada paquete una ruta independiente | Todos los paquetes una misma ruta |
| Falla de nodo | Se pierden algunos paquetes | Todos los CV que pasan por el nodo finalizan |
| Control de congestión | Complejo | Simple |
| Complejidad | En la capa de transporte | En la capa de red |

---

## Direccionamiento IPv4 y Subredes

IPv4 utiliza direcciones de 32 bits ($2^{32} \approx 4.294$ millones de direcciones).

> [!TIP]
> **Direcciones IP Reservadas**
> - **Loopback:** 127.x.x.x (RFC 990).
> - **Redes Privadas (RFC 1918):** `10.x.x.x`, `172.16.x.x` a `172.31.x.x`, `192.168.x.x`.
> - **Link Local (RFC 3927):** `169.254.x.x`.

![Pasted image 20260416200416.png](attachments/Pasted%20image%2020260416200416.png)

### VLSM (Máscara de Subred de Longitud Variable)
Permite dividir una red en subredes de distinto tamaño. Busca resolver el agotamiento de direcciones y simplificar la administración.
- **Motivos:** Hosts distantes, interconexión de capas físicas, filtrado de tráfico, mapeo de estructura organizacional.

### CIDR (Enrutamiento entre Dominios sin Clases) / Superredes
Permite agregar varias subredes continuas bajo una única máscara más corta para optimizar las tablas de ruteo.
- El router decide por dónde enviar el paquete basándose en la **coincidencia del prefijo más largo** (Longest Prefix Match).

![Pasted image 20260416210610.png](attachments/Pasted%20image%2020260416210610.png)

![Pasted image 20260416210549.png](attachments/Pasted%20image%2020260416210549.png)

### Fragmentación y Ensamblado
Si un paquete supera el **MTU** (Maximum Transmission Unit) de un enlace, se fragmenta. Los fragmentos se identifican por el mismo ID y se ordenan mediante el **Offset**. El flag **MF** (More Fragments) indica si hay más fragmentos en camino.

---

## DHCP (Dynamic Host Configuration Protocol)

Asigna direcciones IP y otros parámetros de red de forma dinámica.

> [!NOTE]
> **Proceso DORA**
> 1. **D**iscover: El cliente busca servidores DHCP (Broadcast).
> 2. **O**ffer: El servidor ofrece una IP (Broadcast o Unicast).
> 3. **R**equest: El cliente solicita la IP ofrecida (Broadcast).
> 4. **A**CK: El servidor confirma la asignación (Broadcast o Unicast).

- **DHCP Relay Agent:** Permite que un servidor DHCP atienda a clientes en subredes distintas a la suya, reenviando los mensajes Discover como Unicast al servidor.

---

## NAT (Network Address Translation)

### Tipos de NAT
- **Source NAT (SNAT):** Traduce la dirección de origen. Permite que múltiples hosts privados compartan una IP pública.
- **Destination NAT (DNAT / Port Forwarding):** Traduce la dirección de destino para permitir el acceso a servidores internos desde el exterior.
- **NAT64:** Permite la comunicación entre redes IPv6 y servidores IPv4 mediante traducción.

> [!NOTE]
> **Mecanismos de Relación**
> Para permitir comunicación entre dispositivos detrás de NAT se pueden usar protocolos como **UPnP** (IGD) o servidores **Relay**.

---

## ICMP (Internet Control Message Protocol)

Protocolo de control utilizado para notificaciones de error y diagnóstico.

### Mensajes Comunes
- **Echo Request / Reply:** Utilizado por el comando `ping`.
- **Destination Unreachable:** Notifica que un destino no es alcanzable.
- **Redirect Message:** El router informa al host sobre un gateway mejor para un destino específico.
- **Time Exceeded:** Utilizado por `traceroute` enviando paquetes con TTL incremental.

---

## IPv6

Diseñado para resolver el agotamiento de direcciones IPv4.
- **Direcciones de 128 bits.**
- **Encabezado fijo** de 40 bytes para ruteo más rápido.
- **No permite fragmentación** en routers (solo en origen).
- **Seguridad (IPSec)** incorporada por diseño.

### Tipos de Direcciones
- **Global Unicast:** Ruteable en Internet (prefijo `2000::/3`).
- **Unique Local Address (ULA):** Uso interno organizacional (prefijo `fc00::/7`).
- **Link Local Address:** Configuración automática obligatoria (prefijo `fe80::/10`).

### Transición IPv4-IPv6
- **Dual Stack:** Ambas pilas funcionando en paralelo.
- **Tunneling:** Encapsular paquetes IPv6 dentro de IPv4 para atravesar redes que no soportan IPv6.
- **NAT64 / DNS64:** Traducción entre protocolos.

---

## IPSec y Seguridad de Red

La seguridad se rige por la tríada **CIA**: **Confidencialidad**, **Integridad** y **Disponibilidad** (Availability).

### Protocolos de IPSec
- **AH (Authentication Header):** Provee integridad y autenticidad. No cifra datos.
- **ESP (Encapsulating Security Payload):** Provee confidencialidad (cifrado), integridad y autenticidad.

### Modos de Operación
- **Modo Transporte:** Protege el payload pero mantiene la cabecera IP original.
- **Modo Túnel:** Encapsula el paquete IP original completo dentro de uno nuevo. Ideal para VPNs.

---

## Firewalls e IPTables

**IPTables** es el sistema de filtrado de paquetes en Linux, organizado en tablas y cadenas.

### Tablas y Cadenas Principales

| Tabla      | Función                                                      |
| :--------- | :----------------------------------------------------------- |
| **filter** | Filtrado (ACCEPT, DROP, REJECT).                             |
| **nat**    | Traducción (DNAT, SNAT, Masquerade).                         |
| **mangle** | Modificaciones avanzadas (TTL, ToS).                         |
| **raw**    | Manipulacion de paquetes antes del seguimiento de conexiones |

| Cadena | Momento de Acción |
| :--- | :--- |
| **PREROUTING** | Antes del enrutamiento. |
| **INPUT** | Paquetes dirigidos al sistema local. |
| **FORWARD** | Paquetes que atraviesan el sistema. |
| **OUTPUT** | Paquetes generados localmente. |
| **POSTROUTING** | Después del enrutamiento. |

#### Ejemplo de Comandos

```bash
# Habilitar Masquerade (SNAT dinámico)
iptables -t nat -A POSTROUTING -o eth1 -j MASQUERADE

# Publicar un servidor interno (DNAT)
iptables -t nat -A PREROUTING -d 24.232.138.143 -p tcp --dport 80 -j DNAT --to-destination 192.168.2.3
```

## Preguntas

### Pregunta 1

![](attachments/Pasted%20image%2020260428145254.png)

c) Un servicio sin conexion y sin reconocimiento (ACK)

### Pregunta 2

![](attachments/Pasted%20image%2020260428145812.png)

*Forwarding*: Decision que toma un host en base a su tabla de routeo. Que cuando recibe una IP que no es la propia
*Routing*: Refiere al modo en que se crea la tabla de routeo

### Pregunta 3

![](attachments/Pasted%20image%2020260428151551.png)

Si tenemos en cuenta los headers:
- UDP: 8B
- IPv4: 20B
- Ethernet: 24B

Eso nos deja con $800 - 8 - 20 -24 = 748B$ de datos para enviar en cada fragmento.

Luego necesitamos $\lceil{3100/748}\rceil = 4$  fragmentos

### Pregunta 4

![](attachments/Pasted%20image%2020260428152139.png)

Sí, siempre y cuando en la red privada haya un firewall que hace NAT entre la red privada y la red pública

### Pregunta 5

![](attachments/Pasted%20image%2020260428152318.png)

Ninguna cumple las condiciones pues los ultimos bits que son para identificar al host deberian estar en 0

para /24 o /255.255.255.0 deberian ser x.x.x.0

y para la /8 deberia ser x.0.0.0

### Pregunta 6

![](attachments/Pasted%20image%2020260428152522.png)

16d es 0001 0000b. Para ser de esta red el primer nibble del ultimo octeto debe ser 0001
Osea los que esten entre 16 y 31

a) **Si**
b) **NO** pues 14d = 0000 11110
c) **SI**
d) **NO** pues es la ip que identifica a la red
e) **NO** pues es la ip del boradcast
f) **NO** puse 15d = 0000 1111

### Pregunta 7

![](attachments/Pasted%20image%2020260428153310.png)

iii. 6

Osea /30. Si usasemos 8, lit no queda ni un bit para los hosts. Si usasemos 7 queda un bit solo, osea tengo el que identifica a la red y la de broadcast (no me queda lugar para ningun host)

![](attachments/Pasted%20image%2020260428153805.png)

De la ip sabemos que es clase C, osea /24
De la mascara vemos que el ultimo octeto es 224d = 1110 0000
Luego se usaron 3 bits para la subred

![](attachments/Pasted%20image%2020260428154121.png)
![](attachments/Pasted%20image%2020260428154127.png)

Clase B es /16, osea los 2 primeros octetos de la mascara seran 255 
luego 4 bits para la subred, entonces el 3er octeto es 1111 0000b = 240d
por lo tanto es iii. 255.255.240.0

![](attachments/Pasted%20image%2020260428154503.png)

ii. AND

### Pregunta 8

![](attachments/Pasted%20image%2020260428154523.png)

Es clase C porque empieza con 192, cuya mascara default es /24, 

Luego la direccion de la red es -> 192.15.205.0

Pero como esta haciendo supernetting (CIDR) y como 205 & 252 = 204. 
Aplicando and entre la ip y la mascara de la superreed tenemos que
La superred es -> 192.15.204.0

### Pregunta 9

![](attachments/Pasted%20image%2020260428155152.png)

Necesito 10 subredes, La potencia de 2 inmediata superior es $16 = 2^4$ por lo que necesito al menos 4 bits del ultimo octeto para la red. Como pide con la mayor cantidad de hosts posible, el ultimo octeto debe ser 1111 0000b = 240d

Luego la respuesta es la e) 255.255.255.240

### Pregunta 10

![](attachments/Pasted%20image%2020260428155451.png)

si es /28, tengo $2^4 = 16$ posibles redes, con $2^4 - 2 = 14$ hosts. Luego la respuesta correcta es la f)

### Pregunta 11

![](attachments/Pasted%20image%2020260428155710.png)

para ello hagamos 172.16.210.0 and 255.255.252.0 = 172.16.208.0
Osea la b)

### Pregunta 12

![](attachments/Pasted%20image%2020260428160022.png)

a) 7d = 0000 0111. Luego los unicos que varian son los ultimos 3 bits. Por lo que podemos hacer una red unica 192.16.0.0/21
b) 2d = 0000 0010. No se puede unificar a una unica subred
c) 9d = 0000 1001. No se puede unificar a una unica subred

### Pregunta 14

![](attachments/Pasted%20image%2020260428184400.png)

como es /27 -> los ultimos 5 bits identifican al host, estos no pueden ser ni todos 1 (broadcast), ni todos 0 (red)

a) 64d = 0011 1111 -> **NO**
b) 93d = 0101 1101 -> **SI**
c) ...

### Pregunta 15
![](attachments/Pasted%20image%2020260428184816.png)

la potencia de 2 inmediatamente superior a 459 es 512 = $2^9$ 

Luego necesitamos usar los ultimos 9 bits, red /23 -> b) 255.255.254.0 

### Pregunta 16
![](attachments/Pasted%20image%2020260428185116.png)

224d = 1110 0000 -> luego los ultimos 5 bits no pueden ser todos 1 (broadcast), ni todos 0 (red)
TLT -> es igual al 14

### Pregunta 17

![](attachments/Pasted%20image%2020260428185251.png)

necesitamos que el ultimo octeto sea 0000 xyzw, donde xyzw no pueden ser todos 0 ni todos 1.

osea que se pueden asignar a todas las que: 0 < ultimo octeto < 15

a) 2 -> **SI**
b) 175 -> **NO**
...

### Pregunta 18

![](attachments/Pasted%20image%2020260428185700.png)

En una conexion serial punto a punto, solamente vamos a tener 2 hosts

Sabemos que la cantidad de hosts que pueden haber para n bits de host son $2^n-2$ 

osea que queremos $2^n-2 = 2 \rightarrow n = 2$ 

luego la mas eficiente sera aquella que tenga los ultimos 2 bits en 0. Osea la que el ultimo octeto sea 1111 1100b = 252

Luego es la d)

### Pregunta 20

![](attachments/Pasted%20image%2020260428190147.png)

Son direcciones de multicast, que se usan únicamente como destino, para evitar que un mismo paquete sea enviado unicast a muchos destinos

### Pregunta 21

![](attachments/Pasted%20image%2020260428190306.png)
![](attachments/Pasted%20image%2020260428190353.png)

a) F. No es un protocolo
b) V
c) V
d) V
e) F. Puede ser que no quiera contestar el ping (osea que no quiera contestar ICMP)
f) V/F. Osea podria enviarlo como no. Si la pregunta es si *debe* responder con eso, la respuesta es no.
g) V
h) V para IPv4, en IPv6 **no** hay fragmentacion
i) V
j) F. son agnosticos a lo que hace IP por debajo
k) V
l) F. no lo hace el router, lo hace el firewall
m) V
n) V ya que la que se da es un prefijo /64, luego los aparatos completan los 64 restantes con su MAC address, Haciendo que ahora el router no tenga que hacer NAT sino que directamente puede forwardear los paquetes directamente. Eso no quita que uno quiera seguir haciendo SNAT para ocultar y/o prohibir el acceso directo a los hosts de la red local
o) V
p) V

### Pregunta 22

![](attachments/Pasted%20image%2020260428194224.png)

Sirve para identificar los paquetes que refieren a un mismo flujo (un recurso HTTP, una conversación de voz, etc.). La finalidad es que un router use el mismo “next hop” para todos los paquetes con el mismo flujo, lo que evitaría que lleguen en desorden en caso de ser respetado por todos los routers intermedios


### Pregunta 23

![](attachments/Pasted%20image%2020260428195026.png)

En caso de querer filtrar o aplicar calidad de servicio de acuerdo al protocolo transportado, es más eficiente acceder al header del payload

### Pregunta 24

![](attachments/Pasted%20image%2020260428195203.png)


Para ser posible, el host con IPv6 tendría que tener una IPv6 del tipo “IPv4 mapped” y existir un router capaz de crear un túnel u otro mecanismo de traducción de IPv4 a IPv6. Una posibilidad para el host con IPv4 es usar IPv6 tunneling, provisto por un tercero ( ver [https://tinyurl.com/y392map9](https://tinyurl.com/y392map9) )   


### Pregunta 25
![](attachments/Pasted%20image%2020260428195642.png)


| Red          | Mascara               | Interfaz | Gateway      |
| ------------ | --------------------- | -------- | ------------ |
| 127.0.0.0    | 255.0.0.0             | Lo       | -            |
| 192.168.1.15 | 255.255.255.255       | Lo       | -            |
| 192.168.2.4  | 255.255.255.255       | Lo       | -            |
| 192.168.2.0  | 255.255.255.0         | Eth0     | -            |
| 192.168.1.0  | 255.255.255.0         | Eth1     | -            |
| 192.168.3.0  | 255.255.255.224 (/27) | Eth0     | 192.168.2.15 |
| 0.0.0.0      | 0.0.0.0               | Eth0     | 192.168.2.1  |
| 0.0.0.0      | 0.0.0.0               | Eth1     | 192.168.2.1  |
### Pregunta 26

![](attachments/Pasted%20image%2020260428200606.png)

Hay que considerar distintos momentos en los cuales se pide renovar el uso de la IP otorgada:

1. Cuando aún no vence el tiempo de la licencia otorgada. Normalmente esto se hace cuando se llega al 50% del tiempo otorgado, y si no hay respuesta se envía nuevamente cuando se llega al 87,5% del tiempo otorgado. Si tampoco hay respuesta, se enviará una vez que venza el tiempo

2. Si el tiempo de licencia de uso ya expiró y no se recibe respuesta, entonces se sigue usando la IP otorgada. No es lo mismo que recibir una respuesta negativa, en este caso el host debe dejar de usar esa IP y comenzar el proceso nuevamente ( Discovery, etc.)


### Pregunta 27

![](attachments/Pasted%20image%2020260428200726.png)

Se puede en el caso de que uno tenga IPv4 y el otro IPv6 (está claro que son dos protocolos distintos), si un firewall intermedio implementa NAT64 (hacer IPv6 tunneling). Para el caso de transporte al momento no es posible, ambos hosts deben usar el mismo protocolo.

