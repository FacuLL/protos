---
materia: protos
tipo: apuntes
---

# Introducción a los Protocolos de Comunicación

---

## Material
- [Presentación Teórica](https://docs.google.com/presentation/d/1MLU3mTeN4sOjkH6RTErD5sKrVMkdShyTzxBRitnvpXw/edit?slide=id.p5#slide=id.p5)
- **Lectura:** Capítulos 1.1 a 1.5 de Kurose & Ross.

---

## Red de Computadoras
Un conjunto interconectado de **hosts** autónomos.
- **Envío de paquetes:** Los datos se dividen en paquetes de longitud $L$ bits y se transmiten a una tasa $R$ (bandwidth).
- **Packet-Switching:** 
    - **Demora:** $L/R$.
    - **Store and Forward:** El paquete debe llegar completo antes de ser retransmitido.
    - **Pérdida:** Si la tasa de entrada > salida, los paquetes se encolan o se pierden si el buffer está lleno.

---

## Modelo OSI y TCP/IP

![Pasted image 20260303161540.png](attachments/Pasted%20image%2020260303161540.png)

![Pasted image 20260303163510.png](attachments/Pasted%20image%2020260303163510.png)

### Comparativa de Modelos
| Modelo OSI (1984) | Modelo TCP/IP (1981) | Unidad de Datos | Espacio |
| :--- | :--- | :--- | :--- |
| Aplicación        | Aplicación           | Datos           | Usuario |
| Presentación      | Aplicación           | Datos           | Usuario |
| Sesión            | Aplicación           | Datos           | Usuario |
| Transporte        | Transporte           | Segmento/Datagrama | Kernel  |
| Red               | Red                  | Paquete         | Kernel  |
| Enlace            | Acceso               | Tramas          | Hardware/Kernel |
| Física            | Acceso               | Bits            | Hardware |

Ver mas detalle del modelo OSI en [0_Network#OSI MODEL](0_Network.md#osi-model) y la comparativa con [protocolos TCP/UDP](0_Network.md#protocolos).

---

## Características de Protocolos

Los protocolos pueden ser:
- **Orientado a conexión:** Se debe establecer primero una conexión (ej. [TCP](0_Network.md#tcp)).
- **Confiable:** El emisor sabe si la información llegó correctamente (acuse de recibo).
  - Reenvía información de ser necesario.
  - Informa al nivel superior si no se pudo enviar.
- **No orientado a conexión:** Se envía la información directamente al destinatario sin establecer conexión previa (ej. [UDP](0_Network.md#udp)).
- **No confiable:** No puede asegurar si el destinatario recibió o no la información.

---

> [!TIP]
> **Herramientas:** Se recomienda el uso de **Wireshark** para el análisis de tráfico.

| Orientado a conexión | Confiable | Ejemplos |
| :--- | :--- | :--- |
| SI                   | SI        | TCP      |
| SI                   | NO        |          |
| NO                   | SI        |          |
| NO                   | NO        | UDP, IP  |

---

## Sistemas Propietarios y Estándares

A principios de los '80, para conectar dos computadoras debían ser del mismo fabricante (misma placa de red, programa cliente compatible con servidor, misma codificación, etc.). Esto motivó la creación de **estándares de comunicación** y el **modelo de capas**.

**Principios clave del modelo de capas:**
- El intercambio de información es entre las dos puntas de una misma capa.
- Cada capa le brinda un servicio a la capa superior.

---

## Encapsulamiento

Cada capa agrega su propio encabezado (y a veces trailer) al mensaje:

1. **Aplicación** $\rightarrow$ Datos
2. **Transporte** $\rightarrow$ **Segmento** (header de transporte + datos)
3. **Red** $\rightarrow$ **Paquete** (header de red + segmento)
4. **Enlace** $\rightarrow$ **Trama** (header de trama + paquete + info final de trama)
5. **Física** $\rightarrow$ Bits (stream de datos en el medio físico)

---

## Capa de Enlace

**Objetivos:**
- Vincular hosts *contiguos* (mismo segmento de red).
- Controlar el acceso al medio físico.
- Detectar y/o corregir errores básicos.
- Encapsular los paquetes en tramas.

### Topologías y Dispositivos

- **Topología Bus:** Todos los hosts comparten el mismo medio. Red broadcast.
- **Topología Estrella:** Los hosts se conectan a un dispositivo central (hub o switch).

> [!IMPORTANT]
> **Hub vs Switch:**
> - **Hub:** Recibe señal por una interfaz y la reenvía por todas las demás (inunda). Opera en capa 1. Red broadcast.
> - **Switch:** Aprende en qué interfaz está cada MAC y reenvía solo al destino correspondiente. Opera en capa 2. Reduce colisiones y permite comunicación simultánea entre pares de hosts.

---

## Capa de Red: Tablas de Ruteo

Los routers usan **tablas de ruteo** para decidir por qué interfaz reenviar un paquete. Cada entrada tiene:
- **Destination:** Red destino
- **Mask:** Máscara de la red
- **Gateway:** Siguiente salto ($0.0.0.0$ si está directamente conectada)
- **Interface:** Interfaz de salida

Cuando un router recibe un paquete, hace AND entre la IP destino y la máscara de cada entrada. Si coincide con el Destination, reenvía por esa interfaz al gateway indicado.

Los **registros regionales de Internet** (ARIN, RIPE NCC, LACNIC, AFRINIC, APNIC) asignan bloques de IPs bajo coordinación de la **IANA** (https://www.iana.org/numbers).

---

## Capa de Transporte: Puertos Comunes

- **DNS:** UDP/TCP 53 (ver [3_dns](3_dns.md))
- **HTTP:** TCP 80 (ver [2_HTTP](2_HTTP.md))
- **HTTPS:** TCP 443
- **SMTP:** TCP 25
- **POP:** TCP 109, 110
- **FTP:** TCP 20, 21
- **SSH:** TCP 22 (ver [0_Network - SSH](0_Network.md#ssh))
- **TELNET:** TCP 23
- **SNMP:** TCP/UDP 161, 162

---

## Historia de Internet

- **1957:** Lanzamiento del Sputnik.
- **1958:** Se crea ARPA (Agencia de Proyectos de Investigación Avanzados).
- **1961/62:** Leonard Kleinrock escribe los primeros papers sobre redes.
- **1964:** Paul Baran (RAND) describe enrutamiento redundante y bloques de mensajes en topología descentralizada.
- **1965:** Roberts y Marill conectan TX-2 (MIT) con Q-32 (SDC), primer estudio de time-sharing interinstitucional.
- **1969:** Nace **ARPANET** con 4 nodos (UCLA, SRI, UC Santa Barbara, U. de Utah). Primera transmisión host-a-host (intento de enviar "LOGIN"). Se publica el **RFC 1** (*Host Software*, Steve Crocker). Comienza desarrollo experimental de Telnet.
- **1970:** ARPANET conecta 10 nodos. Se consolidan los IMPs como routers. Jon Postel inicia tareas que luego realizará la IANA.
- **1971:** Se desarrolla **UNIX** (Thompson y Ritchie). Aparece **NCP** (Network Control Protocol). Se lanza el primer TIP. Se pone en funcionamiento **ALOHAnet** (primera red inalámbrica de paquetes).
- **1972:** ARPANET se presenta en público. Primer correo electrónico sobre NCP. ALOHAnet se conecta a ARPANET vía enlace satelital.
- **1973:** Se estandariza NCP (RFC 542). Cerf y Kahn comienzan el diseño de **TCP** (Transmission Control Program).

---

## Preguntas

### Pregunta 1

![Pasted image 20260307171940.png](attachments/Pasted%20image%2020260307171940.png)

No podría calcular la velocidad exacta ya que tendría que conocer además la latencia, y habría que sumarle también el tiempo de procesamiento del router, y el tiempo que los mensajes estarán encolados.

### Pregunta 2

![Pasted image 20260307172012.png](attachments/Pasted%20image%2020260307172012.png)

a. **Falso**. Que un protocolo sea orientado a conexión implica que antes de enviar información se debe establecer una conexión o sesión.

Por ejemplo HTTP utiliza TCP y es un protocolo de aplicación que no requiere establecer una sesión, a diferencia de otros como FTP, SMTP, etc.

b. **Verdadero**

c. **Falso**. Si fuera verdadero todos los protocolos de transporte y por extensión los de aplicación deberían ser sin conexión y no confiables, ya que IP lo es. Si la capa inferior no ofrece un servicio confiable o con conexión entonces la capa superior puede implementarlo (por ejemplo TCP)

d. **Falso**. Nunca puede asegurar que lleguen, un protocolo confiable confirma que los datos han sido recibidos o no.

e. **Verdadero**

f. **Falso**. Un protocolo de enlace sólo ofrece confiabilidad entre hosts adjuntos, que pertenezcan al mismo segmento, por ejemplo puede confirmar que los datos llegaron de A hasta M, pero si luego de ser recibidos por M ocurre un error - por ejemplo se apaga el host M, o el mensaje se descarta (algún dato es incorrecto, debe ser forwardeado por una interfaz y no hay espacio en el buffer asociado, etc-, los datos no llegarán a destino.

g. **Falso**. Cada interfaz del router sirve para conectarse a una red. Si en la red hay 4 computadoras, tendrán que conectarse a un switch o hub con al menos 5 interfaces (una para cada computadora y otra para el router)

### Pregunta 3

![Pasted image 20260307172134.png](attachments/Pasted%20image%2020260307172134.png)

No. En el medio de comunicación broadcast, toda la información que se coloca en el medio puede ser recibida por todos los conectados a ese medio, pero tal vez estar dirigida a un único destinatario, por ejemplo en un supermercado se escucha por los parlantes “El dueño de automóvil con patente ….” será oído por todas las personas pero será ignorado por todos excepto por quien tenga ese auto. Una comunicación broadcast está dirigida a todos los posibles destinatarios, pero puede ser hecha por un medio unicast, por ejemplo volantes dejados en casa, llamadas automáticas por teléfono de algún político que dice querer conocernos, etc.

### Pregunta 4

![Pasted image 20260307172203.png](attachments/Pasted%20image%2020260307172203.png)

a. **Verdadero**
El hub recibe señal de una interface y la envía por el resto de las unidades (inunda), por lo tanto es Verdadero

b. **Falso**
También podría ver los mensajes broadcast y aquellos cuya MAC de destino el switch aún no aprendió en qué interfaz está conectado.

c. **Puede ser**
switch permite reducir la probabilidad de colisiones, por lo tanto, si en la red -usando un hub- había muchas colisiones entonces al cambiar por un switch se notará una mejora. También algunos switches permiten intercambios en forma simultánea entre distintos pares de hosts (mientras el host A envía bits al host B, el host C podría hacer lo propio con D). Ahora bien, si la red es muy pequeña y no hay un uso intensivo del cable de red, y por lo tanto la cantidad de colisiones es baja, entonces al cambiar por un switch no se notará diferencia; o si hay muchos mensajes broadcast. Por lo tanto podríamos afirmar que sí, que es muy probable, pero no 100% seguro.
