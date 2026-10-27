---
materia: protos
tipo: apuntes
---

# SSH

El **SSH** (**Secure Shell**) es un protocolo de red, una aplicación cliente/servidor y una interfaz de comandos diseñada para establecer conexiones seguras sobre redes inseguras. Se utiliza principalmente como un reemplazo seguro para **Telnet**, ya que garantiza que tanto los comandos como los datos viajen encriptados.

---

## Servicios y Funcionalidades

SSH ofrece tres pilares fundamentales de seguridad:
1. **Autenticación**: Verifica la identidad del cliente y del servidor.
2. **Encriptación**: Protege la confidencialidad de los datos.
3. **Integridad**: Asegura que los datos no hayan sido alterados durante el tránsito.

| Herramienta Segura | Herramienta que Reemplaza            |
| :----------------- | :----------------------------------- |
| **SSH**            | Telnet, rlogin, rsh                  |
| **SCP**            | rcp                                  |
| **SFTP**           | ftp                                  |
| **SSHD**           | Demonios de telnet, rlogin, rsh, ftp |

---

## Arquitectura y Componentes
En entornos Linux, la implementación estándar es **OpenSSH**.
- **sshd**: El demonio que corre en el servidor (puerto 22 por defecto). No debe ser gestionado por `inetd` o `xinetd`.
- **ssh**: El cliente para loguearse o ejecutar comandos de forma remota.
- **ssh-keygen**: Herramienta para generar pares de claves (pública/privada).
- **Configuración**: El archivo principal es `/etc/sshd_config`.

### Opciones comunes del comando `ssh`:
- `-p port`: Especificar un puerto distinto al 22.
- `-i file`: Especificar el archivo de clave privada.
- `-v`: Modo *verbose* para depuración.
- `-C`: Comprime los datos para mejorar la velocidad en conexiones lentas.
- `-L` / `-R` / `-D`: Utilizados para **Port Forwarding**.

---

## Port Forwarding (Túneles SSH)
Permite proteger conexiones TCP redirigiéndolas a través de un túnel SSH cifrado. No funciona con UDP.

### Local Port Forwarding (`-L`)

Redirige un puerto local hacia un destino accesible desde el servidor SSH.

> [!IMPORTANT]
> **Sintaxis**: `ssh -L [puerto_local]:[host_destino]:[puerto_destino] [usuario]@[servidor_ssh]`
> - **Caso de uso**: Acceder a un servidor web (puerto 80) en una red interna privada a través de un servidor SSH que sí tiene IP pública.



![](attachments/Pasted%20image%2020260512185530.png)

Entonces ahora puedo acceder al servidor web haciendo:

```sh
curl localhost:2001
```

![](attachments/Pasted%20image%2020260507204123.png)

### Remote Port Forwarding (`-R`)

Permite que el servidor SSH redirija conexiones hacia el cliente local. 

>[!note]
>Le digo al servidor ssh "expone este puerto en vos"

> [!IMPORTANT]
> **Sintaxis**: `ssh -R [puerto_remoto]:[host_local]:[puerto_local] [usuario]@[servidor_ssh]`
> - **Caso de uso**: Exponer un servicio local (ej. base de datos) a un servidor remoto.


![](attachments/Pasted%20image%2020260507204143.png)

ahora podemos acceder a la base de dato de postgres como si estuviese corriendo en pampero en el puerto 2001 haciendo:

```sh
ana@pampero:~$ psql –p 2001
```


### Dynamic Port Forwarding (`-D`)

Convierte al cliente SSH en un servidor **SOCKS proxy**.

> [!TIP]
> Útil para navegar por internet usando la IP del servidor remoto y saltar restricciones locales.
> `ssh -D 9090 user@server`


![](attachments/Pasted%20image%2020260507204652.png)



---

## Autenticación por Clave Pública
Es el método más seguro y recomendado. Utiliza criptografía asimétrica.

1. **Generación**: El cliente genera un par de claves con `ssh-keygen`.
   - `id_rsa`: Clave privada (DEBE mantenerse secreta).
   - `id_rsa.pub`: Clave pública (se comparte con los servidores).
2. **Distribución**: Se debe copiar la clave pública al servidor, dentro del archivo `~/.ssh/authorized_keys`.
3. **Verificación**: El servidor desafía al cliente pidiéndole que firme un mensaje con su clave privada; el servidor verifica la firma con la clave pública almacenada.

> [!NOTE]
> Para deshabilitar la autenticación por contraseña tradicional y forzar el uso de llaves, se debe configurar `PasswordAuthentication no` en el servidor.

---

## Modelo de Capas
El protocolo se divide en tres capas principales:
1. **Transport Layer Protocol (SSH-TLP)**: Provee autenticación del servidor, confidencialidad e integridad. Se monta sobre TCP.
2. **User Authentication Protocol**: Gestiona la autenticación del cliente ante el servidor.
3. **Connection Protocol**: Multiplexa el túnel en canales lógicos (sesiones de shell, port forwarding, X11).

---
Ver [[1_Introduccion|Introducción a Redes]] | [[4_mail-tls-ssl|TLS/SSL]]
