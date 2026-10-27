---
materia: notas
tipo: apuntes
---

# Correo Electrónico, TLS y SSL

---

El correo electrónico es una de las aplicaciones TCP/IP más utilizadas. Permite el intercambio de mensajes entre usuarios a través de redes distribuidas.

---

## Arquitectura y Componentes

En un sistema Unix/Linux, cada cuenta de usuario tiene asociada una cuenta de mail. Los correos entrantes se almacenan típicamente en `/var/spool/mail/<usuario>` o en el directorio `home` del usuario.

La arquitectura de correo se divide en tres agentes principales:

| Agente | Nombre Completo | Función |
| :--- | :--- | :--- |
| **MUA** | Mail User Agent | Aplicación que permite al usuario leer y enviar mensajes (ej. Outlook, Thunderbird). |
| **MTA** | Mail Transfer Agent | Transfiere el mensaje entre hosts utilizando SMTP (ej. Postfix, Sendmail). |
| **MDA** | Mail Delivery Agent | Coloca el mensaje en la casilla de correo del usuario final (ej. Dovecot). |

![Pasted image 20260319192143.png](attachments/Pasted%20image%2020260319192143.png)

---

## SMTP (Simple Mail Transfer Protocol)

Definido inicialmente en la **RFC 821** (1982) y actualizado en la **RFC 5321** (2008). Es el protocolo estándar para la transferencia de correo a través de Internet.

> [!IMPORTANT]
> **SMTP** utiliza **TCP** sobre el puerto **25** para transferencias directas desde el servidor remitente al servidor receptor.

### Características Principales
- **Interacción Comando/Respuesta:** Los comandos son texto ASCII y las respuestas son códigos de estado numéricos seguidos de un comentario.
- **Limitación de Datos:** Los mensajes originales deben ser **ASCII de 7 bits**.
- **Tres Fases:**
	1. **Handshaking** (Saludado).
	2. **Transferencia de mensajes**.
	3. **Cierre**.

### Pasos de una Transacción SMTP
1. `HELO` / `EHLO`: Identificación del cliente.
2. `MAIL FROM`: Especifica el remitente.
3. `RCPT TO`: Especifica el destinatario.
4. `DATA`: Inicia el cuerpo del mensaje (finaliza con un punto `.` en una línea sola).
5. `QUIT`: Cierra la conexión.

En la data usa Internet Message

### Ejemplo

[SMTP: ejemplo](https://docs.google.com/document/d/1ZqTQHk5ccXPu_PK2T08OaJJQBZG6UVeK6rve5oOQ274/edit?tab=t.0)

---

## Acceso Remoto: POP3 e IMAP

Para leer el correo desde un host distinto al servidor de correo, se utilizan protocolos de entrega final.

### POP3 (Post Office Protocol v3)
- **Puerto:** 110.
- **Filosofía:** "Descargar y borrar" (aunque permite dejar copias). El objetivo es obtener los mensajes y almacenarlos localmente.
- **Fases:** Autorización (USER/PASS) y Transacción (LIST, RETR, DELE, QUIT).

### IMAP (Interactive Mail Access Protocol)
- **Puerto:** 143.
- **Filosofía:** Mantiene el almacenamiento centralizado en el servidor.
- **Ventajas:**
	- Permite consultar desde múltiples hosts.
	- Distingue mensajes leídos de no leídos.
	- Permite crear y gestionar carpetas en el servidor.
	- El servidor realiza los backups.

---

## Formato y Codificación (MIME)

### RFC 822
Define el formato del mensaje:
- **Encabezados:** (From, To, Subject, etc.).
- **Línea en blanco**.
- **Cuerpo del mensaje**.

### MIME (Multipurpose Internet Mail Extensions)
Permite enviar contenido que no sea ASCII de 7 bits (imágenes, audio, video, documentos).

> [!NOTE]
> **Base64** es un método de codificación simple usado por MIME que convierte cada grupo de 3 bytes (24 bits) en 4 caracteres ASCII (6 bits cada uno), permitiendo el transporte de datos binarios sobre protocolos de texto.

**Encabezados MIME comunes:**
- `MIME-Version: 1.0`
- `Content-Type`: Define el tipo y subtipo de datos (ej. `image/jpeg`, `text/html`, `multipart/mixed`).
- `Content-Transfer-Encoding`: Indica la codificación (ej. `base64`, `7bit`, `8bit`).

---

## Seguridad y Autenticación

### SPAM y Defensa
- **Listas Negras/Blancas (Deny/Allow list)**.
- **Greylisting**: Rechazo temporal del primer intento de entrega (los spammers rara vez reintentan).
- **Filtros Bayesianos**: Clasificación estadística basada en contenido.

### Motivos de spam
- verificar si un correo existe
- troyanos
- publicidad

### Autenticación de Mails
Para combatir el *phishing* y la suplantación, se utilizan:

1. **SPF (Sender Policy Framework)**: Registro DNS que lista las IP autorizadas para enviar correos en nombre de un dominio.
2. **DKIM (DomainKeys Identified Mail)**: Firma digital del mensaje mediante clave privada, verificable por el receptor mediante la clave pública publicada en el DNS.

> [!NOTE]
> Filtros bayesianos: se fija si dice cosas como "Soy un principe nigeriano" listo esto es spam

---

## SSL / TLS (Secure Sockets Layer / Transport Layer Security)

**SSL** fue desarrollado por Netscape en 1994 para encriptar datos entre un servidor web y un navegador. Su sucesor moderno es **TLS**.

### Nociones de Criptografía
- **Clave Simétrica:** Se utiliza la misma clave para encriptar y desencriptar el mensaje. Es rápida pero requiere un canal seguro para compartir la clave.
- **Clave Asimétrica (Pública/Privada):**
    - Un mensaje cifrado con la **clave pública** de X solo puede desencriptarse con la **clave privada** de X.
    - Un mensaje cifrado con la **clave privada** de X solo puede desencriptarse con la **clave pública** de X (usado para firmas digitales/autenticidad).

![Pasted image 20260319205128.png](attachments/Pasted%20image%2020260319205128.png)

![Pasted image 20260319205142.png](attachments/Pasted%20image%2020260319205142.png)

### Certificados Digitales
Para asegurar que una clave pública pertenece a quien dice ser, se utilizan **Certificados X.509**.
- Son firmados por una **CA (Entidad Certificante)** reconocida.
- Incluyen: clave pública del servidor, datos del propietario, período de vigencia y firma digital del emisor.

> [!IMPORTANT]
> **SSL Handshake:** Es el proceso donde el cliente y el servidor se ponen de acuerdo en los algoritmos a usar, verifican el certificado y generan una **clave simétrica temporal** para la sesión actual.

### TLS en Protocolos de Red
- **HTTPS:** Puerto 443.
- **IMAPS:** Puerto 993.
- **POP3S:** Puerto 995.
- **STARTTLS:** Comando SMTP que permite "subir" una conexión de texto plano a una conexión segura TLS.

> [!NOTE]
> La idea de TLS es hacer lo msimo que ssl pero en la capa de transporte y sin necesidad de cerrar la conexion y abrirla en otro puerto

### DNS sobre TLS y HTTPS
- **DoT (DNS over TLS):** Puerto 853. Incorporado nativamente en algunos sistemas Linux.
- **DoH (DNS over HTTPS):** RFC 8484. El cliente envía queries DNS codificadas vía GET o POST.

### Intercepción y Proxies (MITM)
Los proxies pueden inspeccionar tráfico HTTPS mediante técnicas de **Man-in-the-Middle (MITM)**:
1. El proxy intercepta la conexión.
2. Genera un **certificado falso** para el sitio.
3. Si el cliente confía en el certificado del proxy, la conexión es aceptada y el proxy puede leer/modificar el contenido.

> [!TIP]
> **SNI (Server Name Indication):** Permite a un proxy o firewall bloquear o filtrar sitios web analizando el nombre del servidor en el handshake de TLS, sin necesidad de romper el cifrado.

---
Ver también: [Webmail](2_HTTP.md#webmail) (MUA con interfaz web).

---

## Preguntas

### Pregunta 4

![Pasted image 20260322134848.png](attachments/Pasted%20image%2020260322134848.png)

al servidor que tiene que conectarse es el servidor que viene despues del @ en el mail de destino, cuando hace la consulta al dns la respuesta esta en el registro MX

dns solo responde la ip, una posible causa para que falle la conexion es que no este escuchando en el puerto estandar (25)

### Pregunta 5

![Pasted image 20260322135427.png](attachments/Pasted%20image%2020260322135427.png)

Puede pasar poque este fijada en `/etc/hosts` y se corrige editando el archivo

O tambien puede ser en la cache DNS de mi computadora y hayan manejado mal el tema de cuando expiraba la ip (a nivel servidor dns) y se corrige limpiando la cache

### Pregunta 6

![Pasted image 20260322140044.png](attachments/Pasted%20image%2020260322140044.png)

a. A veces porque la ip va a ir como host en el header
b. agregandolo en `/etc/hosts`
c. consultar otro dns, como por ejemplo el autorizado para el dominio del servidor http al que quiero acceder (1.1.1.1 y 1.0.0.1 son de cloudflare, 8.8.8.8 es de google, probar esos es lo mas normal)

### Pregunta 7

![Pasted image 20260322140350.png](attachments/Pasted%20image%2020260322140350.png)
a. dig .  : intentamos obtener direcciones IP de hosts conocidas por los root name servers. Sólo nos mostrará el nombre de uno de los root name servers
  
b. dig . NS : todos los servidores DNS de los root name servers, con sus nombres e IPs    

c. dig ar : ídem a) pero para el responsable de .ar

d. dig ar NS: todos los servidores DNS responsables del nivel .ar    

e. dig ar MX: una respuesta vacía, o lo mismo que en el punto c

### Pregunta 8

![Pasted image 20260322140952.png](attachments/Pasted%20image%2020260322140952.png)


| Protocolo | Orientado a conexion | Confiable |
| :--- | :--- | :--- |
| SMTP      | si                   | si        |
| POP3      | si                   | si        |
| DNS       | no                   | no        |

### Pregunta 9

![Pasted image 20260322141300.png](attachments/Pasted%20image%2020260322141300.png)

a. **FALSO** que sea orientado a conexion no asegura que llega, lo que dice es que si no llega, vamos a saber que no llego

b. **FALSO** entre servidores de mail se hablan por SMTP, por mas que yo hable con gmail por HTTP

c. **VERDADERO**

### Pregunta 10

![Pasted image 20260322141506.png](attachments/Pasted%20image%2020260322141506.png)

Una ventaja es que el host que esté dentro de la red local podrá enviar paquetes IP directamente al host destino, sin necesidad de la intervención de un router/firewall. Además, si se usa el mismo dominio en forma privada que en forma pública, permite establecer que algunos nombres de hosts (y su IP privada)
