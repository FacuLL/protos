---
materia: practica
tipo: apuntes
tags:
  - redes
  - dns
  - smtp
  - http
---

# Práctica de Laboratorio: Protocolos y Servicios

---

## Serialización y Protocolos de Aplicación

### Conceptos Fundamentales de Serialización
La **serialización** consiste en poner los datos de las estructuras en serie para su transmisión o almacenamiento. Este proceso es fundamental en el [encapsulamiento](../notas/1_Introduccion.md#encapsulamiento) de capas en la red, donde cada capa añade su propia información de control.

#### Codificación Unicode (UTF-8)
Unicode tiene la propiedad de que los bits de inicio de cada octeto indican su posición y función en la secuencia, lo que permite detectar el inicio de un carácter y recuperarse ante pérdidas de sincronía.

- **Un byte (`0xxxxxxx`):** Caracteres ASCII estándar (0-127). Ejemplo: `0x65` (0110 0101) es la 'e'.
- **Dos bytes (`110xxxxx 10xxxxxx`):** Los bits `110` indican el inicio de una secuencia de 2 bytes; los bits `10` indican un byte de continuación.
- **Tres bytes (`1110xxxx 10xxxxxx 10xxxxxx`):** El prefijo `1110` indica 3 bytes.
- **Cuatro bytes (`11110xxx 10xxxxxx 10xxxxxx 10xxxxxx`):** El prefijo `11110` indica 4 bytes.

> [!TIP]
> Esta estructura permite que si empezamos a leer en el medio de una transmisión, sepamos inmediatamente si estamos ante el inicio de un carácter o un byte de continuación (que siempre empieza con `10`).

---

### Idempotencia en HTTP
Un método es **idempotente** cuando realizar la operación una vez o $n$ veces tiene el mismo efecto en el estado del servidor.

Ejemplos de [métodos HTTP](2_HTTP.md#métodos-principales) idempotentes:
- **GET:** Solo recupera información, no cambia el estado.
- **PUT:** Reemplaza un recurso; si se envía lo mismo varias veces, el resultado final es el mismo.
- **DELETE:** Elimina un recurso; una vez eliminado, sucesivas llamadas no cambian que el recurso ya no esté.

---

## Administración de Servidores Web (Nginx)

Para gestionar configuraciones sin afectar la disponibilidad:

```sh
# Recarga la configuración sin downtime
systemctl reload nginx

# Verifica la sintaxis del archivo de configuración
nginx -t

# Prueba de conectividad con header de Host específico
curl -v http://localhost -H "host:foo"
```

---

## Sistema de Nombres de Dominio (DNS)

### Arquitectura y Funcionamiento
Los **root-servers** (13 en total) vienen hardcodeados en los sistemas operativos y resolutores.

> [!NOTE]
> En registros MX, el número antes del dominio indica la **prioridad** (menor número = mayor prioridad).
> Ejemplo: `10 aspmx.l.google.com` se intentará antes que uno con prioridad 20.


![Dominios](./drawings/Dominios.md)

> [!QUESTION] Investigación
> Investigar el ataque de **envenenamiento de DNS de Kaminsky**, que explota la predictibilidad de los IDs de consulta para inyectar entradas falsas en el caché.

---

### Configuración Práctica (BIND9)

#### Instalación y Acceso
```sh
sudo apt install bind9
sudo -i # Acceso como root para configuración
```

#### Definición de Zona (`/etc/bind/named.conf.local`)
```bind
zone "foo.pdc.lab" {
	type master;
	file "/etc/bind/foo.pdc.lab.local";
};
```



#### Archivo de Zona (`/etc/bind/foo.pdc.lab.local`)
```bind
$ORIGIN foo.pdc.lab.
$TTL 1m

@ IN SOA ns.foo.pdc.lab. rohernandez.itba.edu.ar. (
					20260331   ; Serial (YYYYMMDD o incremental)
					7d         ; Refresh (tiempo para que el slave pregunte al master)
					1d         ; Retry (si falla el refresh, reintentar cada tanto)
					10d        ; Expire (tiempo tras el cual el slave deja de responder si no contacta al master)
					1m         ; Negative TTL (tiempo de caché para respuestas NXDOMAIN)
)

@    1m    IN NS ns1
@    2m    IN NS ns2

ns  30 IN A 1.2.3.4
ns1    IN A 1.2.3.5
ns2    IN A 1.2.3.6

@   2h IN MX 1 nsmail
@   2h IN MX 2 ns2mail
@   2h IN MX 3 ns3mail

nsmail   IN A 2.2.2.2
ns2mail  IN A 2.2.2.3
ns3mail  IN A 2.2.2.4

www      IN A 6.7.8.9
@        IN A 6.7.8.10
w3       CNAME www

@        TXT "hola manola"
```

> [!IMPORTANT]
> **Regla de Tiempos**
> Se debe cumplir siempre que $Expire > Refresh + Retry$ para asegurar la consistencia antes de dar por muerta la zona en un secundario.

#### Mantenimiento y Debugging
```sh
# Reiniciar el servicio
systemctl restart bind9

# Ver logs en tiempo real para debugging
tail -f /var/log/syslog

# Pruebas con dig
dig soa foo.pdc.lab @localhost
dig A ns1.foo.pdc.lab @localhost
```

---

## Protocolo SMTP y Formatos de Correo

### Estructura MIME
**MIME** (Multipurpose Internet Mail Extensions) permite identificar el tipo de contenido en el cuerpo del mensaje.

- **Headers:** Se pueden ver descargando el "original" en clientes como Gmail.
- **Content-Type:** Define la naturaleza del dato (ej: `text/plain`, `image/jpeg`).
- **Boundary:** Cadena de texto utilizada para separar las distintas partes en mensajes multipart.

#### Tipos de Multipart
- `multipart/mixed`: Utilizado cuando el mensaje contiene partes de distinta naturaleza (ej: texto y archivos adjuntos).
- `multipart/related`: Utilizado para partes que dependen entre sí (ej: un HTML que referencia una imagen adjunta mediante un `Content-ID`).
- `multipart/alternative`: Utilizado para dar alternativas de lo mismo (ej: una en texto plano y otra en html).

#### Codificación Quoted-Printable
Utiliza la sintaxis `=<HEX_ASCII>` para representar caracteres no ASCII o caracteres especiales.
Ejemplo: `=3D` representa el signo `=`.

![Pasted image 20260407164322.png](attachments/Pasted%20image%2020260407164322.png)

> [!TIP]
> **Pruebas con Netcat**
> Al usar `netcat` para probar protocolos de texto, el flag `-C` es fundamental para enviar fines de línea tipo **CRLF** (\r\n), que es el estándar requerido por protocolos como SMTP y HTTP.
> Para pruebas reales, se puede utilizar el servidor **pampero**.

---

### Servidor smtp

```sh
sudo apt install postfix
```

despues ponemos `internet site` y luego el nombre del dominio, por ejemplo `pdc.lab`

ahora vemos con `netstat -tulpn` podemos ver que esta corriendo en que puerto

luego con nos conectamos con

```sh
nc -C localhost 25
```

![Pasted image 20260409193740.png](attachments/Pasted%20image%2020260409193740.png)

Luego podemos ver ese mail en el directorio `/var/spool/mail`

![Pasted image 20260409194029.png](attachments/Pasted%20image%2020260409194029.png)

despues podemos tambien hacer uno tipo `email.txt`

y luego 

```sh
cat email.txt | nc -C localhost 25
```

si mandamos varios, los mensajes se van a ir concatenando en el archivo


Para que cada mail quede en un archivo separado (más fácil de leer con dovecot), agregar al principio de `/etc/postfix/main.cf`

```sh
home_mailbox=Maildir/
```

y reiniciar:

```sh
systemctl restart postfix
```

ahora los mails llegan al directorio `~/Maildir`

![Pasted image 20260409202428.png](attachments/Pasted%20image%2020260409202428.png)

---

### Servidor para leer mails pop3

```sh
sudo apt install dovecot-pop3d
```

Si postfix está configurado con `home_mailbox=Maildir/`, dovecot también necesita saber que los mails están ahí. Por defecto busca en `/var/spool/mail/` y no encontraría nada. Editar `/etc/dovecot/conf.d/10-mail.conf` y cambiar la línea `mail_location`:

```
mail_driver = maildir
mail_path = ~/Maildir
```

y reiniciar:

```sh
systemctl restart dovecot
```

nos conectamos con 

```sh
nc -C localhost pop3
```

luego ahi podes decirle cosas como 
```sh
USER rodri
PASS <contrasenia en texto plano>
LIST    ; te lista los mails
RETR 1  ; es un retrieve para leer el mail
DELE 1  ; marca un mail para borrar
RSET    ; deshace los cambios
UIDL    ; te lista los id que son unicos 
QUIT    ; se impactan los cambios

```

Podes estar en 3 estados

AUTH -> TX -> UPDATE

si estas en auth solamente podes usar comandos USER y PASS

luego en transaction (TX) tenes los demas para leer mails y demas.
Podes hacer cambios en el servidor pero todavia no se ven reflejados
tipo si haces un dele y despues ctrl+c, no se borra

En update ahi si se ven los cambios, como borrar el mensaje

---

### Ej tipo parcial

Si quiero mandar un mail con ñ agarramos y lo hacemos con gmail y luego nos descargamos el original y le agregamos las cosas que le tenemos que agregar

```sh
EHLO localhost
MAIL FROM: <hola@example.com>
RCPT TO: <rodri@pdc.lab>
DATA
MIME-Version: 1.0
Date: Thu, 9 Apr 2026 21:44:07 -0300
Message-ID: <CA+rx+vrsorZtTTPp1uxbUHXHC00BhKrv60iNduGY0u6s6F94hQ@mail.gmail.com>
Subject: ñññññ
From: Rodrigo Alejandro Hernandez <rohernandez@itba.edu.ar>
To: Rodrigo Alejandro Hernandez <rohernandez@itba.edu.ar>
Content-Type: multipart/alternative; boundary="00000000000039027e064f106e3f"

--00000000000039027e064f106e3f
Content-Type: text/plain; charset="UTF-8"
Content-Transfer-Encoding: base64

w7HDscOxw6HDoQ0K
--00000000000039027e064f106e3f
Content-Type: text/html; charset="UTF-8"
Content-Transfer-Encoding: base64

PGRpdiBkaXI9Imx0ciI+w7HDscOxw6HDoTwvZGl2Pg0K
--00000000000039027e064f106e3f--
.
QUIT

```

---

## Capa de transporte

netcat labura sobre tcp, cuando le pongo crtl+d hago un shutdown (es una syscall). La comunicacion es full duplex pero con un ctrl+d cierro una parte, es decir yo ya no voy a mandar nada mas, es un EOF.

### header format

![Pasted image 20260417103406.png](attachments/Pasted%20image%2020260417103406.png)


Se van intercambiando el tamaño de ventana de cada uno, para que el que manda sepa no mandar mas que lo que el otro puede recibir. 

Si la ventana se queda en 0 no manda mas nada, salvo un paquetito para preguntarle "che seguis en 0?" cada cierto tiempo. 

---

## Opciones de red vm

- **NAT**: La VM usa la IP del host para salir a Internet, como si estuviera detrás de un router. No es accesible desde el exterior.
- **Bridge**: La VM se conecta directamente a la red física del host, obteniendo su propia IP (como un dispositivo más en tu red).
- **Internal**: Red privada y aislada solo para que las VMs se comuniquen entre sí. Sin acceso al host ni a Internet.
- **Host only**: Crea una red privada entre la máquina host y las VMs. Las VMs no tienen acceso a Internet.
- **Controlador genérico**: Permite usar controladores de red especiales definidos por el usuario (como túneles UDP o VDE).
- **Red NAT**: Similar a NAT, pero permite que múltiples VMs compartan la misma red interna y se comuniquen entre sí, además de tener salida a Internet.
- **Red en la nube [EXPERIMENTAL]**: Permite conectar la VM a una red virtual alojada en servicios en la nube.
- **No conectado**: La tarjeta de red está configurada en la VM, pero simula que el cable de red está desconectado.

---

## Xinetd

```sh
sudo apt install xinetd
```

Para activar algun servicio como por ejemplo echo hay que ir a `/etc/xinetd.d/echo` y cambiarle `disable = yes` por `disable = no`

los servicios los podemos ver haciendo `ls` en `/etc/xinetd.d`

Sirven para boludear o debuggear

Para crear un sevicio nosotros podemos hacer uno de telnet con 

```sh
sudo apt install telnetd
```

esto nos crea un binario en `usr/sbin/telnetd`

ahora en `/etc/xinetd.d` podemos crear un archivo `telnet` y ponerle la siguiente configuracion

```sh
service telnet {
	disable = no
	id = telnet
	socket_type = stream
	protocol = tcp
	wait = no
	user = root
	server = /usr/sbin/telnetd
}
```


## Capa de transporte

Lo bueno de ip es que podemos switchear paquetes, entonces no necesitamos 1 cable por cada conexion. Esto se llama *packet switching*.

En *circuit switching* necesito un cable por cada conexion. Aparte si se corta un cable, cago ese circuito

### ICMP

es otro protocolo de transporte que no transmite payload. Hay algunos que dicen que es de red

Es para dar info, como che *Time exceeded*, se termino el ttl o un *Destination unreachable*

ICMP tambien te pasa bytes del paquete o el paquete entero para que yo identifique que paquete es el que me 

el programa traceroute usa ICMP mandando paquetes con distintos TTL (de 1 hasta que llegue a destino) y printeando que ips le contestan, asi sabemos que routeres atraviesa

## IP

Ahora vamos a ver como configurar 2 maquinas virtuales como si estuviesen conectadas por un cable. Una que funcione como *host* y otra que funcione como *router*.

>[!note]
>Igual esta la [Cheatsheet_lab_ip](Cheatsheet_lab_ip.pdf) de la catedra para esta configuracion


para que la vm tenga una ip propia en la red debemos configurarla en modo: **Bridge**

luego vamos a hacer una conexion asi, para que ambas esten a la misma red interna hay que ponerle el mismo nombre

![Conexion_2_VM](drawings/Conexion_2_VM.md)

Si tuviesemos 2 compus conectadas por una interfaz fisica real y una vm en cada una, en lugar de configurar el adaptador como internal network, lo configuramos como bridge a la interfaz fisica real

Tambien vamos a habilitar el **modo promiscuo**

![](attachments/Pasted%20image%2020260505154705.png)


En ambas maquinas tenemos que matar al Network manager porque nos va a cagar toda la config que hagamos

```sh
sudo systemctl stop NetworkManager.service
```

Igual toda la config de red que hagamos, cuando apagamos la maquina se va

En el R para saber que interfaz es cual -> la que tiene ip es la que va al mundo exterior (osea que tiene inet)

luego para darle una ip a ambas hacemos hacemos:


```sh
# con ifconfig

ifconfig <interfaz> <ip>/<bits_mascara>

# con ip addr

ip addr add <ip>/<bits_mascara> dev <interfaz>

```


>[!note]
>Tienen que ser ips que esten en la misma red



>[!tip]
>para el parcial cuando querramos ver la tabla de routeo usemos el comando `route -n` o `ip route`



para que R funcione como router, osea que haga forwarding hay que tirar el comando

```sh
sysctl net.ipv4.ip_forward=1
```

para agregar cosas a la tabla de routeo

```sh
route add -net <ip>/<bits_mascara> [gw <gw>] [dev <dev>]
```

gw y dev podemos no ponerlos, x es tipo la mascara onda /24, /8, etc

![](attachments/Pasted%20image%2020260505164113.png)

Ahora mismo el router 


## DHCP

### En la maquina R

Antes de hacer nada de esto hay que apagar el network manager con `sudo systemctl stop NetworkManager.service`

luego

```sh
sudo apt install isc-dhcp-server
```

luego en `/etc/dhcp/dhcpd.conf`

```sh
subnet <ip> netmask 255.255.255.0 {
	range <ip> <ip>;
	option domain-name-servers 1.1.1.1;
	option subnet-mask 255.255.255.0;
	option routers <ip>;
	option broadcast-address <ip>;
	default-lease-time 20;
	max-lease-time 600;
	
	host maquina_h {
		hardware ethernet <mac>;
		fixed-address <ip>;
		option host-name "maquina-H";
	}
}
```

ahi configuramos un dipositivo con una ip fija, donde el nombre pablo es para que lo resuelva un mdns que busca dispositivos en la red local

y en `/etc/defaults/isc-dchp-server` configurar las interfaces de la que mira al H, ej: enp0s8

>[!important]
>Tenemos que darnos una ip en esta interfaz

para ello hacemos

```sh
# ponerle IP fija a la interfaz que mira a H
sudo ip addr add 192.168.100.1/24 dev enp0s8
sudo ip link set enp0s8 up # este no se si hace falta
```

ahora 

```sh
systemctl restart isc-dhcp-server
```

para ver si esta andando

```sh
systemctl status isc-dhcp-server
```

para ver logs en caso de error

```sh
journalctl -xeu isc-dhcp-server
```


#### Salir a internet

Para que pueda salir a internet y pegarle al router del lab y devolver los paquetes no alcanza con forwarding. Pues luego cuando vuelve el paquete con ip destino maquina H, el router del lab no la conoce, el que le dio la ip fuimos nosotros

Asi que hay que agregar NAT

hay un programa muy bueno que es `iptables`, para ver la tabla de NAT

```sh
iptables -t nat -L
```

para borrar una entrada primero vemos que numero de entrada es la que queremos borrar con 

```sh
iptables -t nat -L --line-numbers
```

y luego

```sh
iptables -t nat -D <nro>
```

Para hacer que haga SNAT


```sh
iptables -t nat -A POSTROUTING -o <interfaz_salida> -j MASQUERADE
```

con eso ya esta andando como router y puedo hacer curl a google si quiero desde la maquina H

Para configurar DNAT

```sh
iptabls -t nat -A PREROUTING -p tcp --dport <portR> -i <interfaz_interna> -j DNAT --to <ipH>:<portH>
```
### En la maquina H

La tenemos conectada internamente a la R

Le desconectamos el "cable virtual" hasta que terminemos de configurar el servidor dhcp en la maquina R, luego volvemos a conectar y si todo va bien, el R me dio una ip (o apagarla y volverla a prender)

Para verlo piola, abrir primero wireshark y luego darle a connect

## Enlace

![](attachments/Pasted%20image%2020260510150838.png)

para ver la tabla de arp

```sh
arp -n
```

para poner una entrada a mano

```sh
$ arp -s <ip> <mac> [-i <interfaz>] [temp]
```

Para borrar una

```sh
sudo arp -d <ip>
```

### arping

Para instalar `arping` que es com oun ping de arp corremos

```sh
sudo apt install arping
```

hay que correrlo con sudo y no afecta nuestra tabla arp

Permite pasarle 4 argumentos
- `-t`:  target mac
- `-T`: target ip
- `-s`: source mac
- `-S`: source ip


## SSH

### Protocolo SSH

Al conectarse por SSH al querer conectarme la pido la clave publica
al principio tenes que confiar que la clave que recibis es la del deseado

>[!important] importante
>Siempre se pide y se comparte la publica


```bash
ssh
usage: ssh [-46AaCfGgKkMNnqsTtVvXxYy] [-B bind_interface] [-b bind_address]
           [-c cipher_spec] [-D [bind_address:]port] [-E log_file]
           [-e escape_char] [-F configfile] [-I pkcs11] [-i identity_file]
           [-J destination] [-L address] [-l login_name] [-m mac_spec]
           [-O ctl_cmd] [-o option] [-P tag] [-p port] [-R address]
           [-S ctl_path] [-W host:port] [-w local_tun[:remote_tun]]
           destination [command [argument ...]]
       ssh [-Q query_option]
```

`ssh-keygen` es para la generacion de claves ssh

```sh
ssh-keygen
Generating public/private ed25519 key pair.
Enter file in which to save the key (/home/bauti/.ssh/id_ed25519): 
Enter passphrase for "/home/bauti/.ssh/id_ed25519" (empty for no passphrase): 
Enter same passphrase again: 
Your identification has been saved in /home/bauti/.ssh/id_ed25519
Your public key has been saved in /home/bauti/.ssh/id_ed25519.pub
The key fingerprint is:
SHA256:EqHsuK5ZWR4dz6aBVOQak3vuvRYZlm+hqwjuDIIir/8 bauti@bauti-vm
The key's randomart image is:
+--[ED25519 256]--+
|     .+          |
|   . = .         |
|    B +  .       |
|   + B =+ .      |
|  . B =.S= .     |
|.  = + =+ o      |
|* = . o  +       |
|+O . o .o        |
|+=B.E ooo.       |
+----[SHA256]-----+

```
la imagen del final permite visualizar la entriopia

```bash
bauti@bauti-vm:~$ cd .ssh
bauti@bauti-vm:~/.ssh$ ls
authorized_keys  id_ed25519  id_ed25519.pub
```

```bash
cat id_ed25519
-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW
QyNTUxOQAAACAh3NAUZmBnwfau8f7iRPuHBSkB3HoYaWkhzjPZ5FAGbQAAAJgnUliqJ1JY
qgAAAAtzc2gtZWQyNTUxOQAAACAh3NAUZmBnwfau8f7iRPuHBSkB3HoYaWkhzjPZ5FAGbQ
AAAEAEsProuNf9JH8+WvJGmnSyBAEqsmVxlYVquOF+lgghJiHc0BRmYGfB9q7x/uJE+4cF
KQHcehhpaSHOM9nkUAZtAAAADmJhdXRpQGJhdXRpLXZtAQIDBAUGBw==
-----END OPENSSH PRIVATE KEY-----
```

```bash
sudo apt install openssh-server

cd /etc/ssh/
ls
moduli      ssh_config.d        ssh_host_ecdsa_key.pub  ssh_host_ed25519_key.pub  ssh_host_rsa_key.pub  sshd_config
ssh_config  ssh_host_ecdsa_key  ssh_host_ed25519_key    ssh_host_rsa_key          ssh_import_id         sshd_config.d

```

```bash
ls -l
total 628
-rw-r--r-- 1 root root 592383 Apr 27 21:24 moduli
-rw-r--r-- 1 root root   1668 Sep 29  2025 ssh_config
drwxr-xr-x 2 root root   4096 Apr 16 10:53 ssh_config.d
-rw------- 1 root root    505 Mar 10 18:52 ssh_host_ecdsa_key
-rw-r--r-- 1 root root    175 Mar 10 18:52 ssh_host_ecdsa_key.pub
-rw------- 1 root root    399 Mar 10 18:52 ssh_host_ed25519_key
-rw-r--r-- 1 root root     95 Mar 10 18:52 ssh_host_ed25519_key.pub
-rw------- 1 root root   2602 Mar 10 18:52 ssh_host_rsa_key
-rw-r--r-- 1 root root    567 Mar 10 18:52 ssh_host_rsa_key.pub
-rw-r--r-- 1 root root    342 Dec  7  2020 ssh_import_id
-rw-r--r-- 1 root root   4307 Apr 27 21:24 sshd_config
drwxr-xr-x 2 root root   4096 Apr 27 21:24 sshd_config.d

```
se puede ver en los permisos que solo los admin puede ver todos los archivos, el resto no puede ver las key privadas

```bash
systemctl start ssh
systemctl status ssh
```

me conecto a ssh
```bash
ssh bauti@localhost
ssh bauti@localhost -v #para ver el debug
```

```bash
cd .ssh
cat known_hosts
```


le damos el ssh_key al servidor para authenticarse con la pub key

```bash
ssh-copy-id localhost #copiamos el ssh key en el servidor en localhost
```

al hacer `ssh -v localhost` nuevamente

esta vez optenemos:
`Authenticated to localhost ([127.0.0.1]:22) using "publickey".`

### SCP

vamos a copiar desde la VM a la macbook
``
en mi mac
```bash
ssh bauti@192.168.0.147

#para poder conectarme con ssh_key
ssh-copy-id bauti@192.168.0.147
ssh bauti@192.168.0.147
```


en un servidor intermedio deberia poder comunicar con el cliente y el servidor ssh para el manejo de keys

>[!note] ssh-agent
>ssh-agent es un proceso en segundo plano que gestiona tus claves privadas de SSH. Su función es mantener las claves desencriptadas en la memoria, permitiéndote autenticarte en servidores sin tener que introducir tu contraseña en cada conexión.


>[!tip] ssh-agent con Balanceador de Carga 
>1.  Origen (Tu PC): Ejecutas ssh usuario@balanceador. El ssh-agent entrega automáticamente la llave privada al cliente SSH para que la conexión comience.
>2.  Tránsito (El Balanceador): El tráfico llega al Balanceador de Carga. El balanceador (en Capa 4) ve una petición en el puerto 22 y dice: "Elegiré al Servidor B para esta conexión". Redirige el tráfico hacia allí.
>3.  Destino (Servidor B): El Servidor B recibe la conexión. Recibe la llave que el ssh-agent envió originalmente desde tu PC. El servidor valida la llave y te da acceso.
En resumen: El ssh-agent se encarga de "quién eres" (identidad) en el origen, y el balanceador se encarga de "a dónde vas" (destino) en la red.

```bash

ssh-agent
#SSH_AUTH_SOCK=/tmp/ssh-4POYFXj0Mc0k/agent.7551; export SSH_AUTH_SOCK;
#SSH_AGENT_PID=7552; export SSH_AGENT_PID;
#echo Agent pid 7552;

eval $(ssh-agent)
#Agent pid 7555

ssh-add
#Identity added: /home/bauti/.ssh/id_ed25519 (bauti@bauti-vm)

ssh-add -l
#256 SHA256:EqHsuK5ZWR4dz6aBVOQak3vuvRYZlm+hqwjuDIIir/8 bauti@bauti-vm (ED25519)

```

### Tunel

cliente-servidor

podemos tener el puerto 5432
el tunel es un encapsulamiento del contenido
redirige a los puertos del cliente

ida y vuelta de los caminos


```bash
# en terminal 1
nc -l 45101

# en terminal 2
ssh -R 9999:localhost:45101 bpessagno@pampero.itba.edu.ar
# puertoServidor:destino:puertoDestino



```


es un duplex. hace que funcione para los dos lados. lo que pongas en el 45101 va a l 9999 y vice versa

```bash
#terminal 1 (pampero)
nc -kl 1414

#terminal 2
 ssh -L 1234:localhost:1414  bpessagno@pampero.itba.edu.ar
#se puede pner cualquier numero al ser local
#puertoLocal:origen:puertoServidor
 
 
 #terminal 3
 ssh bpessagno@pampero.itba.edu.ar
 nc localhost 1234
```



```bash
#terminal 1
ssh -L 8080:google.com:80 bpessagno@pampero.itba.edu.ar
#puertoLocal:destino:puerto
#al hacer esto al acceder a pampero se conecta a google en el puerto 80 (HTTP)

#terminal 2
curl localhost:8080
<!DOCTYPE html>
<html lang=en>
  <meta charset=utf-8>
  <meta name=viewport content="initial-scale=1, minimum-scale=1, width=device-width">
  <title>Error 404 (Not Found)!!1</title>
  <style>
    *{margin:0;padding:0}html,code{font:15px/22px arial,sans-serif}html{background:#fff;color:#222;padding:15px}body{margin:7% auto 0;max-width:390px;min-height:180px;padding:30px 0 15px}* > body{background:url(//www.google.com/images/errors/robot.png) 100% 5px no-repeat;padding-right:205px}p{margin:11px 0 22px;overflow:hidden}ins{color:#777;text-decoration:none}a img{border:0}@media screen and (max-width:772px){body{background:none;margin-top:0;max-width:none;padding-right:0}}#logo{background:url(//www.google.com/images/branding/googlelogo/1x/googlelogo_color_150x54dp.png) no-repeat;margin-left:-5px}@media only screen and (min-resolution:192dpi){#logo{background:url(//www.google.com/images/branding/googlelogo/2x/googlelogo_color_150x54dp.png) no-repeat 0% 0%/100% 100%;-moz-border-image:url(//www.google.com/images/branding/googlelogo/2x/googlelogo_color_150x54dp.png) 0}}@media only screen and (-webkit-min-device-pixel-ratio:2){#logo{background:url(//www.google.com/images/branding/googlelogo/2x/googlelogo_color_150x54dp.png) no-repeat;-webkit-background-size:100% 100%}}#logo{display:inline-block;height:54px;width:150px}
  </style>
  <a href=//www.google.com/><span id=logo aria-label=Google></span></a>
  <p><b>404.</b> <ins>That's an error.</ins>
  <p>The requested URL <code>/</code> was not found on this server.  <ins>That's all we know.</ins>
```

```bash
ssh -D 8080 bpessagno@pampero.itba.edu.ar  #Dinamyc Port Forwarding

#terminal 2
netstat -tlnp
#la ultima entrada dice 8080 ssh

curl -x socks://localhost:8080  google.com -v

curl -x socks://localhost:8080  ifconfig.me
```
la resolucion de DNS se hace de manera local (en mi computadora) 
si queremos que la resolucion pase del otro (en pampero/ servidor ssh) lado se tiene que hacer
```bash
curl -x socks5h://localhost:8080 ifconfig.me
```

>[!importante] sobre la resolucion
>La diferencia radica en quién resuelve el DNS (traduce el nombre de dominio a una dirección IP):
>*   socks://: Tu máquina local resuelve la IP de ifconfig.me y luego le envía al proxy la instrucción de conectarse a esa IP.
>*   socks5h://: El cliente le envía el nombre ifconfig.me al proxy, y es el servidor proxy quien se encarga de resolver el DNS.
>La versión con h es más privada (tu ISP no ve las consultas DNS) y te permite acceder a dominios que solo son visibles desde la red del proxy.


## nmap

```sh
sudo apt install nmap
```

Sirve para escanear puertos, service detection, os detection, ips de la red.

### Tipos de escaneo

| Flag  | Nombre             | Descripción                                                                                            |
| ----- | ------------------ | ------------------------------------------------------------------------------------------------------ |
| `-sS` | SYN scan (stealth) | Manda un SYN, si recibe SYN-ACK el puerto está abierto. **No completa el handshake**. Requiere `sudo`. |
| `-sT` | TCP connect        | Completa el handshake. No requiere `sudo` pero es más detectable.                                      |
| `-sU` | UDP scan           | Escanea puertos UDP. Más lento.                                                                        |
| `-sn` | Ping scan          | Solo descubre qué hosts están up, sin escanear puertos.                                                |
| `-sV` | Version detection  | Detecta servicio y versión en cada puerto.                                                             |
| `-O`  | OS detection       | Adivina el OS por el comportamiento del stack TCP/IP.                                                  |
| `-A`  | Aggressive         | Activa `-sV`, `-O`, scripts y traceroute.                                                              |

### Comandos útiles

```sh
# Hosts activos en la red
sudo nmap -sn 192.168.0.0/24

# Stealth scan de puertos comunes
sudo nmap -sS --top-ports=20 192.168.0.0/24

# Puertos específicos / rangos
nmap -p 22,80,443 192.168.0.1
nmap -p 1-1024 192.168.0.1
nmap -p- 192.168.0.1              # todos los puertos

# OS detection
sudo nmap -O 192.168.0.1

# Escaneo completo
sudo nmap -A 192.168.0.1

# Velocidad: -T<0-5> (0=paranoid, 5=insane, default=3)
sudo nmap -T4 192.168.0.0/24
```

### Estados de un puerto

- **open**: hay algo escuchando
- **closed**: respondió con RST (no hay servicio)
- **filtered**: sin respuesta (probablemente firewall)
- **open|filtered**: indistinguible, típico de UDP

### NSE (scripts)

```sh
nmap -sC 192.168.0.1                        # scripts por defecto
nmap --script ssh-auth-methods 192.168.0.1  # script específico
ls /usr/share/nmap/scripts/                 # ver todos los scripts
```

### Salida

```sh
nmap -oN salida.txt 192.168.0.0/24   # legible
nmap -oX salida.xml 192.168.0.0/24   # XML
nmap -oA salida 192.168.0.0/24       # todos los formatos
```

> [!TIP] Para el parcial: `-sS` es el más usado. Necesita `sudo`. Sin sudo, usar `-sT`.

---

## Tablas de routeo con vpn

Contexto de ejemplo: mi IP local es `192.168.3.2`, red local `192.168.3.0/24`, router `192.168.3.1`, VPN server en `24.232.1.1`, red interna de la VPN `10.3.0.0/24`, gateway VPN `10.3.0.1`.

### Full tunnel — todo el tráfico sale por la VPN

| Red         | Mascara | interfaz | Gateway     |
| ----------- | ------- | -------- | ----------- |
| 127.0.0.0   | /8      | lo       | -           |
| 192.168.3.2 | /32     | lo       | -           |
| 192.168.3.0 | /24     | eth0     | -           |
| 0.0.0.0     | /0      | vpn0     | 10.3.0.1    |
| 10.3.0.0    | /24     | vpn0     | -           |
| 24.232.1.1  | /32     | eth0     | 192.168.3.1 |

> [!important] La ruta /32 al servidor VPN
> La entrada `24.232.1.1/32` via `eth0` es **obligatoria** en full tunnel. Sin ella, los paquetes que mantienen el túnel mismo intentarían salir por `vpn0` → loop infinito. Esa ruta más específica rompe el ciclo y manda el tráfico del túnel directamente por eth0.

---

### Split tunnel — internet sale normalmente, VPN solo para la red interna

| Red         | Mascara | interfaz | Gateway     |
| ----------- | ------- | -------- | ----------- |
| 127.0.0.0   | /8      | lo       | -           |
| 192.168.3.2 | /32     | lo       | -           |
| 192.168.3.0 | /24     | eth0     | -           |
| 0.0.0.0     | /0      | eth0     | 192.168.3.1 |
| 10.3.0.0    | /24     | vpn0     | -           |

> [!note] Diferencia clave
> La ruta default (`0.0.0.0/0`) apunta a `eth0` con el router local como gateway: todo el tráfico de internet sale igual que sin VPN. Solo el tráfico hacia `10.3.0.0/24` (la red interna de la VPN) va por `vpn0`.
> 
> En este caso **no hace falta** la ruta `/32` al servidor VPN porque la ruta default ya va por `eth0`, entonces los paquetes que sostienen el túnel llegan al servidor sin problema.
