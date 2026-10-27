---
materia: protos
tipo: apuntes
---

# Resolución de Nombres (DNS)

---

## ¿Qué es la Resolución de Nombres?
Es el proceso de traducir un **nombre de dominio** (ej. `www.ejemplo.com`) a una **[dirección IP](0_Network.md#ip-addresses)** (ej. `192.0.2.1`).
- **Importancia:** Facilita el acceso a los hosts mediante nombres fáciles de recordar y es esencial para la comunicación en red.

---

## Estructura de Nombres
- **Dominio:** Colección de computadoras accedidas bajo un nombre común (ej. `itba.edu.ar`).
- **Hostname:** Nombre propio de cada host dentro de un dominio (ej. `www`, `smtp`).
- **FQDN (Fully Qualified Domain Name):** La unión del hostname y el dominio (ej. `smtp.it.itba.edu.ar`).
- **Jerarquía:** Los dominios tienen niveles. El nivel superior es el **TLD** (Top-Level Domain) como `.com`, `.edu`, `.ar`.

---

## Métodos de Resolución en el Host
Existen dos vías principales para que una aplicación obtenga la IP:

### Archivo `/etc/hosts`
- Tabla estática local que asocia IPs con nombres.
- Se consulta primero por defecto.
- Configuración de orden en `/etc/host.conf` o `/etc/nsswitch.conf` (ej. `order hosts, bind`).

### DNS Resolver
Utiliza el archivo de configuración `/etc/resolv.conf`:
- `nameserver`: IPs de los servidores DNS a consultar (hasta 3).
- `domain`: Dominio local por defecto (se agrega a nombres sin punto).
- `search`: Lista de dominios para búsqueda de nombres cortos.
- `options`: Parámetros como `debug`, `timeout`, `attempts`, `rotate`, etc.

Una vez me manda la ip me lo guardo en una cache, cuanto tiempo me lo guardo funciona parecido al [max-age de http](2_HTTP.md#con-`max-age`) (*ttl*). Ver también el modelo de capas en [Introducción - OSI](1_Introduccion.md#modelo-osi-y-tcp/ip).

---

## El Sistema DNS
Es un sistema **jerárquico y distribuido**. No existe una única base de datos centralizada.

### Tipos de Servidores
- **Recursivos:** Realizan la consulta completa en nombre del cliente.
- **Autorizados:** Tienen la información definitiva sobre un dominio específico.
- **Raíz (Root Servers):** El nivel más alto. Hay 13 root servers nombrados de la `a` a la `m`, operados por distintas organizaciones (ICANN, NASA, etc.).
- **TLD Servers:** Responsables de dominios como `.com`, `.org` o códigos de país.
- **DNS Local (Default Name Server):** Generalmente provisto por el ISP. Actúa como proxy y mantiene una **caché** con un tiempo de vida (**TTL**).

### DNS Reverse (Inverso)
Mapea una dirección IP a un nombre de dominio utilizando el árbol especial bajo el dominio `in-addr.arpa`.

---

## Registros DNS (Resource Records - RR)
Formato: `(name, value, type, ttl)`

| Tipo | Nombre | Valor |
| :--- | :--- | :--- |
| **A** | Hostname | Dirección IPv4 |
| **AAAA** | Hostname | Dirección IPv6 |
| **NS** | Dominio | Hostname del servidor autorizado |
| **CNAME** | Alias | Nombre canónico (real) |
| **MX** | Dominio | Servidor de correo del dominio |
| **PTR** | IP invertida | Nombre de dominio (resolución inversa) |
| **TXT** | Variable | Texto libre (usado para SPF, verificación, etc.) |
| **SOA** | Dominio | Inicio de autoridad (info técnica de la zona) |
| **SRV** | Servicio | Ubicación de servicios específicos (puerto/host) |

---

## Consultas y Funcionamiento
Las consultas suelen utilizar el protocolo **[UDP](0_Network.md#udp)** (o [TCP](0_Network.md#tcp) para transferencias de zona) en el puerto **53**. Ver tabla de puertos en [Introducción - Puertos Comunes](1_Introduccion.md#capa-de-transporte:-puertos-comunes).
1. El cliente pregunta al **DNS Local**.
2. Si no está en caché, el DNS local pregunta a un **Root Server**.
3. El Root deriva al servidor de **TLD** correspondiente.
4. El TLD deriva al servidor **Autorizado** del dominio.
5. El servidor autorizado devuelve la IP final.

![Pasted image 20260312201555.png](attachments/Pasted%20image%2020260312201555.png)

---

## Configuraciones Especiales
- **Split-Horizon:** Un nombre resuelve a distintas IPs según el origen de la consulta (ej. IP interna para la LAN, IP pública para Internet).
- **DNS Dinámico (DDNS):** Permite actualizar registros en tiempo real (RFC 2136), ideal para hosts con IP dinámica.

---

## Utilidades de Consola
- `host`: Resolución rápida (directa e inversa).
- `nslookup`: Modo interactivo para consultar servidores y tipos de registros específicos.
- `dig`: Herramienta detallada para ver registros completos y trazas.
- `whois`: Información sobre el registrante/responsable de un dominio.

---

## Seguridad: DNS Spoofing
Técnica para lograr que un registro DNS apunte a una IP falsa.
- **Métodos:**
    - Enviar respuesta antes que el servidor real (requiere conocer o adivinar el ID de consulta).
    - **DNS Sniffer:** Capturar el ID real mediante sniffing para enviar la respuesta falsa con el ID correcto.
    - **Cache Poisoning:** Inyectar registros falsos en la caché de un servidor DNS víctima para que este distribuya la información falsa.

---

## Preguntas

### Pregunta 1

![Pasted image 20260314121321.png](attachments/Pasted%20image%2020260314121321.png)

#### yo

Falla porque desde fuera del itba recibe la conexion desde fuera y esta todo ok. Pero cuando desde dentro del itba quiero hacer lo mismo, al tener configurado los servidores de google, el nombre se resuelve a la ip publica, entonces pasa que un host de la red local se quiere conectar desde fuera (a traves de la ip publica), entonces rechaza la conexion.

#### catedra

falla porque el servidor DNS, para Pampero, usa “Split horizon”. Si la consulta para resolver el nombre proviene dentro del ITBA, responde un IP privado (10….), y si la consulta proviene de un cliente DNS externo responde con el IP público. Como mi servidor DNS es 4.4.4.4, para el servidor DNS del ITBA la consulta “vino desde afuera”. A esto se le suma que no se permiten conexiones a Pampero a la IP pública si el IP origen es interno del ITBA (se verá más adelante cuando veamos firewalls).

### Pregunta 2

![Pasted image 20260314121732.png](attachments/Pasted%20image%2020260314121732.png)

#### yo

Hasta donde yo se usaban udp, ahora me estas matando

#### catedra

conviene UDP si la rta es corta y entra en un datagrama (el encabezado TCP ocupa más bytes que UDP y con UDP no es necesario intercambiar paquetes para iniciar y luego cerrar la conexión). Si supiéramos que la rta es extensa y necesita varios datagramas, sería más sencillo iniciar el pedido usando TCP

### Pregunta 3

![Pasted image 20260314122004.png](attachments/Pasted%20image%2020260314122004.png)

Es responsabilidad de la aplicación. La aplicación le debe indicar a UDP la información a enviar en un datagrama, si le pide que envíe más bytes de la capacidad de un datagrama entonces será rechazado por UDP. En líneas generales, si una aplicación tiene que enviar más información, la aplicación debe “partir” la información y enviar tantos datagramas como sea necesario. El cliente debe recibir los datagramas y procesarlos en orden, hasta que haya llegado el último. Si un datagrama no llega, tendrá que realizar nuevamente la consulta.
