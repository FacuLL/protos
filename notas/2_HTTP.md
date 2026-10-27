---
materia: protos
tipo: apuntes
---

# Protocolo HTTP (HyperText Transfer Protocol)

---

HTTP es de transmisión de texto (ascii) y se basa en el modelo **request-response**.
- **Marca de fin:** Casi todos los protocolos usan `\r\n`.
- **Endianness:** [TCP](0_Network.md#tcp) y la mayoría de las transmisiones binarias son **Big Endian**.

---

## Previo a HTTP

Antes de HTTP, se usaba **FTP** para obtener documentos. En base a las referencias dentro de un texto, se debía acceder manualmente a otro sitio FTP y descargar los textos deseados. Esto motivó la necesidad de aplicaciones basadas en **hipertextos** que permitieran navegar entre documentos enlazados.

---

## Evolución de las Versiones

### HTTP 0.9 (1991)
- Estático, solo texto.
- No mantiene estado (stateless).
- Orientado a línea de comando.

![Pasted image 20260305200002.png](attachments/Pasted%20image%2020260305200002.png)

### HTTP 1.0 (1996)
- "Browser friendly".
- Comandos: `GET`, `POST`, `HEAD`.
- Introduce códigos de estado.
- Un request por recurso.

![Pasted image 20260305200151.png](attachments/Pasted%20image%2020260305200151.png)

### HTTP 1.1 (1999)
- Cabeceras y métodos adicionales (`PUT`, `DELETE`, `TRACE`, `OPTIONS`).
- Negociación de contenido.
- Soporte de **caché**.
- **Conexiones persistentes** (Keep-Alive). Ver [características de protocolos](1_Introduccion.md#características-de-protocolos) para orientado a conexión.

![Pasted image 20260305200305.png](attachments/Pasted%20image%2020260305200305.png)

### HTTP/2 (2015)
- Protocolo **binario**.
- Compresión de headers.
- **Multiplexación** de recursos (múltiples streams por conexión).
- **Server Push:** Manda recursos antes de que sean pedidos.

### HTTP/3
Basado en **QUIC** (corre sobre [UDP](0_Network.md#udp)).
- Menor latencia y multiplexación mejorada. Ver evolución del protocolo en [Historia de Internet](1_Introduccion.md#historia-de-internet).

---

## Mensajes y Métodos

### Estructura del Mensaje

Un mensaje HTTP tiene tres partes:
1. **Start line:** Método + URI + versión (request) o versión + código + mensaje (response).
2. **Headers:** Pares `<nombre>: <valor>`, finalizan con línea en blanco. Solo US-ASCII.
3. **Body:** Contenido del mensaje (opcional).

### Métodos Principales
- **GET:** Solicita un recurso al servidor (es idempotente).
- **HEAD:** Solicita solo los headers del recurso (sin body).
- **POST:** Envía información al servidor para ser procesada.

### Métodos Adicionales
- **PUT:** Envía un recurso al servidor (crear/reemplazar, es idempotente).
- **DELETE:** Elimina un recurso del servidor (es idempotente).
- **TRACE:** Analiza el recorrido de la solicitud (diagnóstico). Puede ser un riesgo de seguridad ya que expone headers.
- **OPTIONS:** Consulta los métodos disponibles en el servidor.

### GET vs POST
| Característica | GET | POST |
| :--- | :--- | :--- |
| Propósito      | Pedir datos | Enviar datos para procesar |
| Parámetros     | En la URL (Query string) | En el cuerpo (Body) |
| Caché          | Sí | No |
| Historial      | Sí | No |
| Bookmark       | Sí | No |
| Longitud       | Acotada | Sin restricción |

### Códigos de Estado
- **1XX:** Información.
- **2XX:** Éxito (ej. **200 OK**).
- **3XX:** Redirección (ej. **304 Not Modified**).
- **4XX:** Error en cliente (ej. **404 Not Found**).
- **5XX:** Error en servidor (ej. **500 Internal Server Error**).

---

## Recursos e Identificadores (URI)

![Pasted image 20260305202301.png](attachments/Pasted%20image%2020260305202301.png)

> [!NOTE]
> URI es el concepto genérico, mientras que URL (ubicación) y URN (nombre) son las implementaciones concretas.

- **Sintaxis URL:** `<scheme>://[<user>:<password>@]<host>[:<port>]/<path>?<query>[#fragment]`
- **Sintaxis URI:** `<scheme>://<authority><path>?<query>` — el path termina con el primer `?` o `#` o si no hay más caracteres. Puede ser relativo o absoluto.
- **URN:** Identifica un recurso por su **nombre**, no implica que exista ni cómo acceder a él. Ej: `urn:isbn:0132856204`

---

## Headers HTTP

Estructura: `<nombre>: <valor>`. Finalizan con una línea en blanco. Se envían en este orden:

### Headers Generales
- **Cache-Control:** Directivas para cache (`max-age`, `no-cache`, `private`, `public`).
- **Connection:** Opciones de conexión (`keep-alive`, `close`).
- **Date:** Fecha de creación del mensaje.
- **Transfer-Encoding:** Encoding de transferencia.
- **Via:** Lista de intermediarios por los que pasó el mensaje.

### Headers de Solicitud
- **Accept:** Tipo de contenido aceptado por el cliente.
- **Accept-Charset:** Charset aceptado (ISO-xxxx, UTF-8).
- **Accept-Encoding:** Encoding aceptado (gzip, deflate).
- **Accept-Language:** Idioma preferido.
- **Host:** Servidor y puerto destino del request.
- **If-Modified-Since:** Condiciona el request a la fecha indicada.
- **Referer:** URL del documento que generó el request.
- **User-Agent:** Aplicación que generó el request.
- **Range:** Solicita un rango (en bytes) del recurso.

### Headers de Respuesta
- **Age:** Estimación en segundos desde que se generó la respuesta en el server.
- **Location:** URI a redireccionar.
- **Retry-After:** Tiempo de delay para reintento.
- **Server:** Descripción del software del server.
- **Authorization:** Indica que el recurso necesita autorización.

### Headers de Contenido
- **Allow:** Métodos aplicables al recurso.
- **Content-Encoding / Content-Length / Content-Type / Content-Location / Content-MD5**
- **Expires:** Fecha de expiración del recurso.
- **Last-Modified:** Fecha de modificación del recurso.

### Tipos de contenido (MIME)

HTTP usa **MIME** para describir contenido multimedia. Cada recurso es etiquetado por el web server:
- `text/html`, `text/plain`
- `image/jpeg`, `image/png`
- `video/mp4`
- `application/pdf`, `application/json`

### Ejemplo

![Pasted image 20260310171718.png](attachments/Pasted%20image%2020260310171718.png)

---

## Conexiones HTTP

- **No persistente:** Se abre y cierra una conexión TCP por cada recurso solicitado.
- **Persistente (Keep-Alive):** Se reutiliza la misma conexión TCP para múltiples recursos, evitando el overhead de establecer nuevas conexiones.

---

## Negociación de Contenido

El cliente indica sus preferencias mediante headers `Accept`, `Accept-Language`, etc. El servidor puede:
- Responder con `200 OK` y los headers `Content-Type`, `Content-Language`, `Content-Location` adecuados.
- Responder con `302 Found` y un `Location` hacia la versión apropiada del recurso.

---

## Caché (detalle)

Tres escenarios principales (ver comparación con [cache de DNS](3_dns.md#2.-dns-resolver)):

### Sin directivas
El proxy reenvía cada request al servidor, sin cachear nada.

### Con `max-age`
El servidor indica `Cache-Control: max-age=600`. Dentro de ese tiempo, el proxy sirve la copia cacheada sin contactar al servidor. Incluye el header `Age` para indicar cuánto tiempo lleva en cache.

### Con `Last-Modified` / `ETag`
El servidor envía `Last-Modified` y/o `ETag`. Cuando el proxy necesita revalidar, envía `If-Modified-Since` y/o `If-None-Match`. Si el recurso no cambió, el servidor responde **304 Not Modified** (sin body, ahorrando ancho de banda).

Se pueden combinar ambos mecanismos: `max-age` para evitar consultas innecesarias, y `Last-Modified`/`ETag` para revalidar cuando el `max-age` expira.

---

## Cookies (detalle)

Pequeño texto de información enviado por el servidor y almacenado por el browser.

**Flujo:**
1. Cliente envía POST con credenciales.
2. Servidor valida y responde con `Set-Cookie: sessionId=123xyz; Expires=...`
3. Cliente incluye `Cookie: sessionId=123xyz` en requests subsiguientes.
4. Servidor verifica la sesión.

**Tipos:**
- **Session cookie:** Se elimina al cerrar el browser.
- **Persistent cookie:** Tiene fecha de expiración, persiste entre sesiones.
- **Third-party cookie:** Pertenece a un dominio distinto al visitado.
- **Secure cookie:** Solo se envía por HTTPS.

---

## Proxies (detalle)

Un proxy actúa como intermediario entre cliente y servidor.

- **Proxy directo (Forward proxy):** Está del lado del cliente. Permite controlar acceso a sitios, cachear consultas.
- **Proxy transparente:** El cliente no sabe que está pasando por un proxy.
- **Proxy reverso (Reverse proxy):** Está del lado del servidor. Recibe requests del exterior y los reenvía internamente a distintos servidores según el recurso solicitado. Útil para balanceo de carga, SSL termination, etc.

---

## Herramientas de Consola
- **cURL:** Transferencia de recursos con soporte HTTP(s), FTP, etc.
- **wget:** Descarga archivos (permite recursividad).
- **netcat (nc):** Para armar datos manualmente y conectar a puertos.

---

## Preguntas

### Pregunta 1

![Pasted image 20260307170329.png](attachments/Pasted%20image%2020260307170329.png)

Para ello utiliza dos cosas. Por un lado el max age, que le indica por cuanto tiempo el recurso es valido, y por otro, puede utilizar el last modified junto con el etag para preguntarle al servidor si el recurso aun es valido.

### Pregunta 2

![Pasted image 20260307165017.png](attachments/Pasted%20image%2020260307165017.png)

Lo hace mediante el uso de *cookies*, osea ids de sesion. Uno cuando hace una request incluye la *cookie* y luego el servidor sabe a que sesion se refiere (dando una ilusion de stateful cuando es stateless)

### Pregunta 3

![Pasted image 20260307165724.png](attachments/Pasted%20image%2020260307165724.png)

No. Pues el browser mismo puede tener una copia del mismo, usando el mismo mecanismo de maxage que usa el proxy

### Pregunta 4

![Pasted image 20260307170318.png](attachments/Pasted%20image%2020260307170318.png)

TRACE lo que hace es que le devuelve al cliente como llego la petision, de esta manera si alguien usa TRACE estaria exponiendo el header y podria otra persona, que no sea el proxy, añadir eso al header y conectarse, sin pasar por el proxy.

### Pregunta 5

![Pasted image 20260307170420.png](attachments/Pasted%20image%2020260307170420.png)

a.  Depende la version, la version 2 es binaria, las demas son de texto
b. Es correcto
c. No es valida. Las cookies de un recurso si o si estan relacionadas con el servidor en el cual el recurso esta alojado

### Pregunta 6

![Pasted image 20260307170811.png](attachments/Pasted%20image%2020260307170811.png)

La razon es que las que fueron solicitadas con GET se cachean pero los recursos que fueron solicitados con POST no

### Pregunta 7

![Pasted image 20260307171600.png](attachments/Pasted%20image%2020260307171600.png)

[el coso de stackoverflow](https://stackoverflow.com/questions/3492319/private-vs-public-in-cache-control)

La directiva Cache-Control puede contener además el valor private o public (valor por defecto). Si es private está indicando que sólo tiene sentido para el cliente que lo solicitó, y que no tiene sentido que los proxies intermedios (de la empresa, ISP, etc.) lo guarden en la caché, ya que no será de utilidad para otros usuarios.
