---
materia: protos
tipo: apuntes
---

# Networking

---

## IP ADDRESSES

![Pasted image 20260119110058.png](attachments/Pasted%20image%2020260119110058.png)

### IPV4

$192.168.57.139 \rightarrow$ son octetos cada punto, son en total 32 bits

hay ip privada dentro de la subnet y una ip publica

### IPV6

se hizo para resolver el problema de address space limitado pero no se usa muhco, se llego a una mejor solucion llamada **NAT**

### NAT

**Network Address Translation** permite a varios dispositivos de una red privada que le damos la misma ip publica. Hay algunas ip reservadas para ser privadas

![Pasted image 20260119111341.png](attachments/Pasted%20image%2020260119111341.png)

entonces ahi resolvemos el problema de las colisiones

---

## Mac Addresses

cada dispositivo tiene la suya propia (idealmente)

> [!TIP]
> tenemos colisiones (ppio del palomar) pero no pasa nada mientras esas colisiones no esten en la misma subred bro

los primeros 3 bytes son para el device name

---

## Protocolos

![Pasted image 20260119112409.png](attachments/Pasted%20image%2020260119112409.png)

### TCP

**Transmission Control Protocol** $\rightarrow$ connection oriented protocol (ver [características](1_Introduccion.md#características-de-protocolos))

es mas confiable, no se pierde info, tiene el **3 way handshake** 

### UDP

**User Datagram Protocol** (ver [características](1_Introduccion.md#características-de-protocolos))

mas orientado tipo streaming, no me importa si se pierden paquetes/info quiero mandarte todo en tiempo real

---

## Common ports and protocols

![Pasted image 20260119112631.png](attachments/Pasted%20image%2020260119112631.png)

### DNS

**Domain name server** $\rightarrow$ traduce de nombres tipo "google.com" a su ip. Ver mas en [3_dns](3_dns.md).

### SSH

**Secure Shell** $\rightarrow$ te da una shell, la comunicacion esta encriptada, a diferencia de telnet que te da una shell pero los datos no viajan encriptados

---

## OSI MODEL

Ver comparativa con TCP/IP en [1_Introduccion#Modelo OSI y TCP/IP](1_Introduccion.md#modelo-osi-y-tcp/ip).

![Pasted image 20260119113320.png](attachments/Pasted%20image%2020260119113320.png)

1. Physical $\rightarrow$ data cables
2. Data $\rightarrow$ Switching, Mac addresses
3. Network $\rightarrow$ IP adresses, routing
4. Transport $\rightarrow$ TPC/UDP
5. Session $\rightarrow$ session management
6. Presentation $\rightarrow$ WMV, JPEG, MOV
7. Application $\rightarrow$ [http](2_HTTP.md), https, smtp

---

## Subnetting

La mascara indica que IPs estan en la subred

un dispositivo puede hablarle directamente a otro siempre y cuando esten en la misma subred

### Mask

todas las ip que den lo mismo cuando les hago and con la mascara, estan en la misma subred

Por ejemplo una subred $/24$ tiene una mascara $255.255.255.0$ 

### Hosts

con $/24$ podes tener hasta 256 hosts pero la primer y la ultima direccion estan reservadas, osea con una red $/x$ puedo tener hasta $2^{32-x}-2$ hosts

> [!IMPORTANT]
> La primer direccion es la id de la subred y la ultima direccion es la del broadcast (le hablo a todos dispositivos de la subred) 

por ejemplo en una red $192.168.1.0/24$ 
- $192.168.1.0 \rightarrow$ red id
- $192.168.1.255 \rightarrow$ broadcast

### Ejemplos

$192.168.0.0/22$

![Imagen JPEG-4E4C-8E5B-F2-0.jpeg](attachments/Imagen%20JPEG-4E4C-8E5B-F2-0.jpeg)

![Pasted image 20260120095756.png](attachments/Pasted%20image%2020260120095756.png)

## Tunel

Un tunel se da cuando el payload de un protocolo, en lugar de ser del protocolo de arriba, es de una capa igual o inferior. Es lo que usan las vpn