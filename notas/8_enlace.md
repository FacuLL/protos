---
materia: protos
tipo: apuntes
---
# Enlace

La **capa de enlace** (Data Link Layer) es el nivel 2 del modelo OSI. Su función principal es el traslado de paquetes desde un nodo al nodo adyacente a través de un enlace de comunicación físico.

---

## Servicios del Nivel de Enlace

El nivel de enlace ofrece una serie de servicios fundamentales para la comunicación entre nodos vecinos:

- **Encapsulamiento**: Empaqueta los datagramas de la capa de red en tramas (frames), agregando un encabezado y un trailer.
- **Acceso al medio**: Determina cómo se comparte el canal de comunicación.
- **Comunicación confiable**: Garantiza que las tramas lleguen sin errores (opcional en algunos protocolos).
- **Control de Flujo**: Evita que un emisor rápido sature a un receptor lento.
- **Detección y Corrección de Errores**: Identifica si hubo bits alterados durante la transmisión y, en algunos casos, permite reconstruirlos.
- **Modos de transmisión**:
	- **Half-Duplex**: Los nodos pueden transmitir y recibir, pero no simultáneamente.
	- **Full-Duplex**: Los nodos pueden transmitir y recibir al mismo tiempo.

---

## Tipos de Enlaces y Protocolos

Existen dos categorías principales de comunicación en el nivel de enlace:

### 1. Comunicaciones Punto a Punto (WAN)
Utilizadas típicamente en enlaces directos entre dos nodos.
- **SLIP (Serial Line IP)**: Protocolo muy simple para encapsular IP sobre líneas seriales.
- **PPP (Point-to-Point Protocol)**: Sucesor de SLIP. Soporta múltiples protocolos, autenticación, detección de errores y negociación de opciones.

### 2. Redes de Difusión o Broadcast (LAN)
Un canal compartido por múltiples nodos donde pueden ocurrir **colisiones** (cuando un nodo recibe dos o más señales simultáneamente). Requieren protocolos de **Acceso al Medio (MAC)**:

- **Acceso Aleatorio**:
	- **ALOHA**: Los nodos transmiten apenas tienen datos. Si hay colisión, retransmiten tras un tiempo aleatorio.
	- **CSMA (Carrier Sense Multiple Access)**: El nodo "escucha" el canal antes de transmitir.
		- *1-Persistent*: Si está ocupado, espera y transmite apenas se libera.
		- *Non-Persistent*: Si está ocupado, espera un tiempo aleatorio.
	- **CSMA/CD (Collision Detection)**: Usado en Ethernet cableado. El nodo detecta la colisión mientras transmite y aborta la operación.
	- **CSMA/CA (Collision Avoidance)**: Usado en redes inalámbricas.
- **Acceso Controlado**:
	- **Polling**: Un nodo maestro coordina quién transmite.
	- **Token Passing**: Se rota un "token" (permiso) entre los nodos (ej. Token Ring).
- **Acceso Canalizado**:
	- **FDMA** (Frecuencia), **TDMA** (Tiempo), **CDMA** (Código).

---

## Ethernet

Es el estándar más utilizado en LANs cableadas debido a su bajo costo y simplicidad.

![](attachments/Pasted%20image%2020260430204237.png)

> [!IMPORTANT]
> **Dirección MAC (Media Access Control)**: Identificador único de 48 bits (6 bytes) grabado en la placa de red (NIC).
> - Primeros 3 bytes: **OUI** (Organizationally Unique Identifier).
> - Últimos 3 bytes: Número de serie de la placa.

### Estructura de la Trama Ethernet
| Preámbulo (8B) | Destino (6B) | Origen (6B) | Tipo (2B) | Datos (46-1500B) | CRC (4B) |
| :--- | :--- | :--- | :--- | :--- | :--- |

- **Preámbulo**: Sincronización (patrón 10101010).
- **CRC**: Verificación de redundancia cíclica para descartar tramas con errores.

---

## Protocolo ARP (Address Resolution Protocol)

ARP permite obtener la **Dirección MAC** de un destino conociendo su **Dirección IP**.

> [!NOTE]
> Los hosts mantienen una **Tabla ARP** dinámica que relaciona IPs con MACs. Se puede visualizar con el comando `arp -a`.

### Funcionamiento de ARP
1. Si un host A quiere enviar a un host B en la misma red y no tiene su MAC, envía un **ARP Request** (Broadcast: `ff:ff:ff:ff:ff:ff`).
2. El host B responde con un **ARP Reply** (Unicast) informando su MAC.
3. El host A guarda la entrada en su tabla y envía la trama de datos.

### ARP en diferentes subredes
Si el destino está en otra red:
1. El host A determina que debe enviar el paquete al **Gateway** (Router).
2. Host A usa ARP para obtener la MAC del Router.
3. El Router recibe la trama, desencapsula el paquete IP, y usa ARP en la red destino para encontrar la MAC del host final.

### Variantes de ARP
- **RARP**: De MAC a IP (obsoleto, reemplazado por DHCP).
- **Proxy ARP**: El router responde con su propia MAC a un request destinado a otra red.
- **Gratuitous ARP**: Un host anuncia su propia MAC para detectar conflictos de IP.

---

## Seguridad: ARP Spoofing

Consiste en enviar respuestas ARP falsas para asociar la MAC del atacante con la IP de otra víctima (o el Gateway).

- **Ataques posibles**: Man-in-the-Middle (MITM), Denial of Service (DoS), Session Hijacking.
- **Defensas**: Entradas ARP estáticas, DHCP Snooping, herramientas de monitoreo como `arpwatch`.



### Pregunta 1

![](attachments/Pasted%20image%2020260506193538.png)

Hay un host que estaba abusando de la red tirando muchos mensajes de broadcast. Al separarlo en 2 redes, solo molestaria a una de estas 2.

### Pregunta 2

![](attachments/Pasted%20image%2020260506193827.png)

a. Opera en la capa 2 (la de enlace, como esta guia)

### Pregunta 3

![](attachments/Pasted%20image%2020260506193951.png)

c. Router

### Pregunta 4

![](attachments/Pasted%20image%2020260506194057.png)

a. Los mensajes de broadcast no pasan de un segmento a otro


La opcion c tambien podra ser ya que si dentro de la LAN se producian muchas colisiones, bajaran las colisiones

### Pregunta 5

![](attachments/Pasted%20image%2020260506194850.png)

A nivel enlace, ambos van a recibirlo (desp puede ser que ip lo descarte porque tiene otra ip que la que se le asigno)

### Pregunta 6

![](attachments/Pasted%20image%2020260506194957.png)

c. un host desea conocer la direccion MAC de otro host

### Pregunta 7

![](attachments/Pasted%20image%2020260506195040.png)

c. a todos los nodos de la red

### Pregunta 8

![](attachments/Pasted%20image%2020260506195124.png)

d. Se manda a la mac del que hizo la request

### Pregunta 9

![](attachments/Pasted%20image%2020260506195239.png)

b. La direccion ip de un destino esta en otra red

### Pregunta 10

DESPUES SIGO, TLT

### Pregunta 11

Teniendo en cuenta los casos del ejercicio anterior responder:

![](attachments/Pasted%20image%2020260517172608.png)

#### a.

Puede el B agregar a su tabla arp una entrada con la ip 192.168.2.13 y la mac de eth0, asegurandose que en la tabla de routeo no tenga un gateway esa ip

A al recibirlo, que hace depende de si tiene habilitado forwarding o no. Si no lo tiene lo descarta, porque no es la ip de esa interfaz. Si tiene forwarding habilitado va a ver que la ip destino es de su otra interfaz y lo procesa normalmente

#### b. 


1. El enunciado dice “el host B envía un paquete ARP request para el IP 192.168.2.13”, entonces la respuesta es “no es posible”. Si el enunciado fuera “B quiere enviar un paquete IP a 192.68.2.13, ¿bajo  qué circunstancias relacionaría esa IP con la MAC de eth0 de A en su tabla ARP?” la respuesta sería: si B tiene configurado en su tabla de ruteo que el Gateway para 192.168.2.13 es el IP 192.168.2.1
2. Esto sería lo esperable
3. Similar a i, si por ejemplo en la tabla de ruteo B tiene sólo la entrada de localhost y el Gateway

#### c.

Contestado en el punto anterior

#### d.

1. B puede agregar una entrada estática en la tabla ARP relacionando la IP 192.168.2.13 con la mac eth0 de A. Además debe asegurarse en su tabla de ruteo que para ese IP no tenga como Gateway al router.
2. Debe asegurarse que en su tabla ARP no figure 192.168.2.13 relacionado con la eth0 de A, y en su tabla de ruteo tener una entrada para ese IP indicando que el Gateway es 192.168.2.10 (osea el router)  
3. Puede ser por dos razones: en la tabla de ruteo para el IP 192.168.2.13 el Gateway es 192.168.2.10, o averiguando la MAC de 192.168.2.10 agregar una entrada estática en la tabla ARP relacionando esa MAC con 192.168.2.13
4. No se puede



### Pregunta 12

![](attachments/Pasted%20image%2020260517174534.png)

#### Primero, ¿qué es L/R?

- **L** = largo de la trama en bits
- **R** = tasa de transmisión
- **L/R** = tiempo que tarda en **transmitir** la trama completa

---

#### El escenario:

Dos nodos A y B empiezan a transmitir **al mismo tiempo**:

```
A ────────────────────────────── B
  ───►                    ◄───
```

Va a haber colisión en algún punto del cable. El problema es **¿la detectan?**

---

#### ¿Cómo se detecta una colisión?

CSMA/CD detecta colisiones porque mientras transmitís, **escuchás el cable**. Si lo que escuchás es distinto a lo que mandás, hubo colisión.

Pero para detectarla necesitás que la señal del otro **te llegue mientras todavía estás transmitiendo**.

---

#### El problema cuando `d_prop < L/R`:

```
A empieza a transmitir ──► tarda d_prop en llegar a B
Si d_prop < L/R significa que el primer bit de A 
llega a B antes de que A termine de transmitir
```

Hasta acá bien. Pero la cátedra dice que igual **puede no detectarse**. ¿Por qué?

Porque la señal de colisión también tarda `d_prop` en **volver** a A. Entonces A necesita seguir transmitiendo durante `2 × d_prop` para detectarla.

---

#### La condición real para detectar colisiones:

```
L/R > 2 × d_prop
```

Si la trama es tan corta que A termina de transmitir antes de que le vuelva la señal de colisión, **nunca se entera**.

---

#### Por eso Ethernet fija:

- **Tamaño mínimo de trama** (64 bytes) → para que L/R sea suficientemente grande
- **Longitud máxima de cable** → para que d_prop sea suficientemente pequeño

Garantizando que `L/R > 2 × d_prop` siempre se cumple.




---
Ver [[1_Introduccion#Capas de Red|Capas de Red]] | Ver [[6_Red#Direccionamiento IP|Direccionamiento IP]]
