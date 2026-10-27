---
materia: Protocolos de Comunicación
tipo: apuntes
---

# Capa de transporte

---

## Introducción a la Capa de Transporte
La capa de transporte provee **comunicación lógica** entre procesos que corren en distintos hosts. A diferencia de la capa de red (host-to-host), esta actúa en las "puntas finales" (end-to-end).

- **Emisor:** Divide los mensajes de la aplicación en **segmentos** y los entrega a la capa de red.
- **Receptor:** Reensambla los segmentos en mensajes y los pasa a la capa de aplicación.

---

## Multiplexación y Demultiplexación
Permite que múltiples procesos en un mismo host utilicen los servicios de red simultáneamente.

- **Demultiplexación:** Entrega de los datos del segmento de transporte al socket correcto.
- **Multiplexación:** Recopilación de datos de distintos sockets, añadiendo el encabezado de transporte para crear segmentos.

### Puertos (RFC 1700)
Los sockets se identifican mediante números de puerto:

| Rango | Uso |
| :--- | :--- |
| $< 255$ | Aplicaciones públicas (*Well-known*) |
| $[255, 1023]$ | Aplicaciones comerciales |
| $> 1023$ | Puertos efímeros / no regulados |

> [!NOTE]
> **Demultiplexación**
> - **Sin conexión (UDP):** utiliza el par `(IP destino, Puerto destino)`.
> - **Orientada a conexión (TCP):** utiliza la quíntupla `(IP origen, Puerto origen, IP destino, Puerto destino, Protocolo)`.



---

## UDP: User Datagram Protocol
Es un protocolo "mínimo" que ofrece un servicio de **mejor esfuerzo** (best effort).

- **Características:** No orientado a conexión, no confiable, no ofrece control de flujo ni de congestión.
- **Ventajas:** Menor demora (sin handshake), encabezado pequeño (8 bytes), control total sobre qué y cuándo se envía.
- **Uso:** DNS, Streaming, VoIP, SNMP.

### Formato de un mensaje

![Pasted image 20260330172918.png](attachments/Pasted%20image%2020260330172918.png)

---

## Transferencia de Datos Confiable (rdt)
Para lograr confiabilidad sobre canales propensos a errores, se utilizan mecanismos de **rdt**:

1. **Checksum:** Para detectar errores de bits.
2. **ACK/NAK:** Acuses de recibo (positivos/negativos).
3. **Números de secuencia:** Para detectar paquetes duplicados.
4. **Timeouts:** Para recuperar paquetes perdidos.

> [!TIP]
> El mecanismo **Stop & Wait** es ineficiente. Se prefiere el uso de **Pipelining** (ventana deslizante) para permitir múltiples paquetes en vuelo.

---

## TCP: Transmission Control Protocol
Protocolo orientado a conexión que ofrece un **circuito virtual** confiable.

### Establecimiento y Cierre de Conexión
- **3-way Handshake:** 
    1. Cliente $\to$ Servidor: `SYN=1, Seq=x`
    2. Servidor $\to$ Cliente: `SYN=1, ACK=1, Ackn=x+1, Seq=y`
    3. Cliente $\to$ Servidor: `ACK=1, Ackn=y+1`
- **Cierre:** 4-way handshake utilizando flags `FIN`.

### Control de Flujo
El receptor controla al emisor para no saturar su buffer de recepción.
- Se utiliza el campo **Window** en el segmento TCP para informar el espacio disponible.

### Control de Congestión
Evita saturar la red (routers intermedios). TCP utiliza dos mecanismos principales:
- **Slow Start:** Inicia con `cwnd = 1 MSS` y se duplica en cada RTT hasta alcanzar un umbral (`ssthresh`).
- **AIMD (Additive Increase Multiplicative Decrease):** Incremento lineal de la ventana y reducción a la mitad ante pérdida detectada por triple ACK duplicado.

### Formato de un mensaje tcp

![Pasted image 20260330174841.png](attachments/Pasted%20image%2020260330174841.png)

**Flags:**
- `URG` de si es urgente, permitiendole a la app si quiere leer estos primero
- `ACK` salvo cuando establecemos la conexion, este va en 1 (osea si estoy enviando un ack o no)
- `PSH` deberias pushear estos datos directo a la aplicacion
- `RST` para cortar la conexion de manera abrupta
- `SYN` se usa cuando se quiere establecer una conexion
- `FIN` para cortar la conexion pero de forma polite

---

## SCTP: Stream Control Transmission Protocol
Protocolo moderno diseñado originalmente para telefonía sobre IP (SIGTRAN).

### Características Principales
- **Orientado a mensaje:** A diferencia de TCP (orientado a stream de bytes), SCTP preserva los límites de los mensajes.
- **Multihoming:** Permite que una asociación utilice múltiples direcciones IP por host, mejorando la tolerancia a fallos.
- **Multistreaming:** Permite múltiples flujos independientes dentro de una asociación. Esto soluciona el problema de **Head-of-Line (HOL) Blocking** de TCP.

>[!tip]
>En sctp: cada write de una punta, es un read en la otra.
>Mucho mas sencillo para programar la capa de aplicacion

### Seguridad y Conexión
Utiliza un **4-way handshake** con intercambio de **cookies** para protegerse contra ataques de denegación de servicio (SYN Flood).

> [!IMPORTANT]
> **Comparativa Rápida:**
> - **TCP:** Confiable, Stream de bytes, 1 flujo.
> - **UDP:** No confiable, Mensajes, Sin flujos.
> - **SCTP:** Confiable, Mensajes, Multi-flujo + Multi-homing.


## Comparacion

![](attachments/Pasted%20image%2020260507193511.png)


Pero SCTP tiene algunos problemas

![](attachments/Pasted%20image%2020260507193550.png)

QUIC medio que lo mato

---
**Ver también:**
- [Modelo OSI](1_Introduccion.md#capas-de-red)
- [Interacción con HTTP](2_HTTP.md#tcp-en-la-web)

---

## Preguntas

### Pregunta 1

![Pasted image 20260403183146.png](attachments/Pasted%20image%2020260403183146.png)

Es analogo a UDP

### Pregunta 2

![Pasted image 20260403183215.png](attachments/Pasted%20image%2020260403183215.png)

UDP

### Pregunta 3

![Pasted image 20260403183237.png](attachments/Pasted%20image%2020260403183237.png)

UDP: (ip destino, puerto destino)

TCP: (ip origen, puesto origen, ip destino, puerto destino)

### Pregunta 4

![Pasted image 20260403183921.png](attachments/Pasted%20image%2020260403183921.png)

c. se tretransmite el paquete 

### Pregunta 5

![Pasted image 20260403183949.png](attachments/Pasted%20image%2020260403183949.png)

c. Un protocolo que intercambia datagramas sin acuse de recibo ni garantia de entrega

### Pregunta 6

![Pasted image 20260403184238.png](attachments/Pasted%20image%2020260403184238.png)

### Pregunta 7

![Pasted image 20260403185023.png](attachments/Pasted%20image%2020260403185023.png)

Van a ser enviados al mismo socket y se va a dar cuenta de cual es por el par ip y puerto de origen

### Pregunta 8

![Pasted image 20260403185147.png](attachments/Pasted%20image%2020260403185147.png)

Son enviados originalmente al mismo socket (pasivo) y este despues hace un fork() creando un socket activo una vez establecida la conexion (*3 way handshake*). El primer paquete es al mismo socket pero despues a distintos, ambos al puerto 80 y se diferencian por la ip de origen

### Pregunta 9

![Pasted image 20260403185354.png](attachments/Pasted%20image%2020260403185354.png)

Se utilizan para saber que paquete estoy recibiendo, si se perdio alguno en el medio y poder mandarselos a la capa de aplicacion en orden. 

### Pregunta 10

![Pasted image 20260403185459.png](attachments/Pasted%20image%2020260403185459.png)

Se utilizan para decir: bueno si en este tiempo no recibi el ack, probablemente es que el paquete no llego y debo volverlo a mandar

### Pregunta 11

![Pasted image 20260403185541.png](attachments/Pasted%20image%2020260403185541.png)

a. 20 (del 90 al 109)
b. Sera 90 (es el que esta esperando leer)
c. Imposible de saber

### Pregunta 12

![Pasted image 20260403185754.png](attachments/Pasted%20image%2020260403185754.png)

Usar sctp, o una conexion tcp por cada recurso

### Pregunta 13

![Pasted image 20260403190039.png](attachments/Pasted%20image%2020260403190039.png)

La dividimos en varios datagramas bro

### Pregunta 14

![Pasted image 20260403190122.png](attachments/Pasted%20image%2020260403190122.png)

Un socket pasivo solo establece una nueva conexion, un socket activo se encarga de la intercambiar datos

### Pregunta 15

![Pasted image 20260403191249.png](attachments/Pasted%20image%2020260403191249.png)

Un campo de 16 bits llamado window, que indica cuantos octetos (bytes) tiene libre el host en el buffer de recepcion para la sesion. Onda para que no me mande mas de esos bytes porque no los voy a poder leer

### Pregunta 16

![Pasted image 20260403191641.png](attachments/Pasted%20image%2020260403191641.png)

No hay un campo para eso, solamente se dan cuenta de que hay congestion si no reciben los ack o si tardan mucho. Lo que si se puede hacer es llenar el coampo options para ir ajustando de forma dinamica el RTT como se detalla en https://datatracker.ietf.org/doc/html/rfc1323#page-11

### Pregunta 17

![Pasted image 20260403192047.png](attachments/Pasted%20image%2020260403192047.png)

a. Lo que puede pasar es que sea tipo un bottle neck y no podamos aprovechar todo el ancho de banda
b. La forma es que se agrega en las options un window scale (ws) que indica cuantos bits hay que shiftear el campo window. onda seria equivalente a multiplicar el window por $2^{ws}$ 
