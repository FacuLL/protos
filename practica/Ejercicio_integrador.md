---
title: Ejercicio Integrador
tags:
  - protos
  - itba
  - practica
  - ssh
  - networking
  - http
date: 2026-05-19
author: Rodrigo Alejandro Hernandez
---

# Ejercicio Integrador

## Enunciado

A usted le han otorgado acceso a un laboratorio militar de último calibre, escondido en las profundidades del Ártico. Su comandante le entrega el siguiente diagrama de red:

![](attachments/Pasted%20image%2020260519205846.png)


Siendo el nuevo miembro de su unidad cibernética, usted está ansioso de demostrar las increíbles habilidades que aprendió en la materia 72.07 - Protocolos de Comunicación.

El servidor “The Vault” contiene secretos de estado ocultados por la industria farmacéutica, que si logra obtener entonces no precisará comenzar a tomar pastillas de vitaminas a medida que envejece (algo muy deseable).  

Por desgracia para usted, la persona que maneja este servidor tomó varias medidas de seguridad para impedir que pueda entrar.

Uno de sus compañeros, que también cursó protos, le dice “es imposible, no hay ni internet ahí adentro! No puedo ver el partido 😭”. A diferencia de él, usted sí prestó atención en clase en vez de mirar el partido, y por ende tiene todas las herramientas necesarias para forzarse dentro de este servidor de todos modos.

Objetivo: entrar a The Vault.

---
## Como conectarse

Para conectarse hacemos

```sh
docker pull cloudflare/cloudflared

ssh -o ProxyCommand="docker run --rm -i cloudflare/cloudflared access ssh --hostname %h" rohernandez@protolab.thomasmiz.me
```

`tunombre` es la parte antes del @ en tu mail del itba y la contraseña es el legajo

Para borrar la imagen despues de terminar:

```sh
docker image rm cloudflare/cloudflared
```

---
## Solucion

### Inicio

Primero vemos si podemos llegar a los servidores con `ping`, como no podemos llegar a ninguno revisamos la tabla de routeo

```sh
route -n
```

Vemos que no tiene configurado para acceder a las redes que queremos, luego agregamos las entradas:

```sh
ip route add 192.168.124.0/24 via 192.168.123.200
ip route add 6.9.4.0/24 via 192.168.123.69
```

Ahora nos contestan los ping :)

Vemos si hay un servidor web corriendo en 192.168.124.80 

>[!note]
>tiene DNAT por lo que no hace falta que especifiquemos el puerto 8080. Si lo especificamos tambien anda

```sh
curl 192.168.124.80
```

y nos contestan

```html
<h2>Bienvenido!</h2><p>Este desafío es imposible, mejor rendite así no perdés tiempo.</p><p>Si querés proceder, accedé a <a href="/start">/start</a></p>
```

Luego vamos a ver que hay en `/start`

```sh
curl 192.168.124.80/start
```

Y nos dicen: No te respondo nada sin un header "Tiki: Taka"!

Entonces se lo agregamos en el header

```sh
curl 192.168.124.80/start -H "Tiki: Taka"
```

Ahora si nos dicen:

```
Excelente.

Para responder cada pregunta de este challenge, deberás concatenar a la URL un /response, realizar un POST a dicho recurso y enviar un JSON (indicando al servidor que eso es un JSON) un documento con la respuesta: {"rta": "entendido"}.

Entendido?
```

Osea que a partir de ahora las respuestas las vamos a mandar de la forma

```sh
curl -X POST 192.168.124.80/<url>/response -H "Content-Type: application/json" -d '{"rta": "<respuesta>"}'
```

Asi que para empezar mandamos

```sh
curl -X POST 192.168.124.80/start/response -H "Tiki: Taka" -H "Content-Type: application/json" -d '{"rta": "entendido"}'
```

y nos contestan

```
Procedemos a /juialepan para tu primer desafío.
```

### Preguntas

#### juialepan

Accedemos con 

```sh
curl 192.168.124.80/juialepan
```

y nos contestan

```
## PRIMERA PREGUNTA

¿Cuál es el gateway de pampero para llegar a la IP 1.1.1.1?

Su respuesta debe ser una dirección IP.
```

Entonces nos conectamos por ssh a pampero

```sh
ssh user@pampero.itba.edu.ar
```

y una vez adentro vemos la tabla de routeo

```sh
route -n
```

Vemos que el Gateway es `10.16.1.254`, luego mandamos la respuesta

```sh
curl -X POST 192.168.124.80/juialepan/response -H "Content-Type: application/json" -d '{"rta": "10.16.1.254"}'
```

y nos contestan

```
Muy bien!

Procedemos a /ketylanuchi para tu segunda pregunta.
```

#### ketylanuchi

Accedemos con

```sh
curl 192.168.124.80/ketylanuchi
```

y nos contestan

```
## SEGUNDA PREGUNTA: El router que expone este servidor HTTP también expone un servidor DNS. ¿Cuál es el SERIAL de www.google.com según este?
```

Luego tiramos un `dig` a google.com indicando que queremos el server 192.168.124.53

```sh
dig SOA google.com @192.168.124.53
```

Y vemos que el serial es 74757169, luego mandamos nuestra respuesta

```sh
curl -X POST 192.168.124.80/ketylanuchi/response -H "Content-Type: application/json" -d '{"rta": "74757169"}'
```

y nos contestan

```sh
Procedemos a /urururuluru para la tercer pregunta.
```

#### urururuluru

Accedemos con

```sh
curl 192.168.124.80/urururuluru
```

y nos contestan

```
## TERCERA PREGUNTA: ¿Cuál es el contenido EN LENGUAJE ESPAÑOL del recurso /turulu?
```

Entonces entramos vemos que hay en `/turulu`

```sh
curl 192.168.124.80/turulu
```

y obtenemos

```html
<h3>The cat is under the table</h3>
```

que no esta en español, incluso poniento `?lang=es` como query param tampoco. Lo que tenemos que hacer es

```sh
curl 192.168.124.80/turulu -H "Accept-Language: es"
```

y obtenemos

```
Hoy aprendimos a negociar contenido sobre HTTP
```

Luego mandamos nuestra respuesta

```sh
curl -X POST 192.168.124.80/urururuluru/response -H "Content-Type: application/json" -d '{"rta": "Hoy aprendimos a negociar contenido sobre HTTP"}'
```

y nos contestan

```
Bien. Aprender es importante.

Procedemos a /papopepoparapapapapiparapopepo para la tercer pregunta.
```

#### papopepoparapapapapiparapopepo

Accedemos con

```sh
curl 192.168.124.80/papopepoparapapapapiparapopepo
```

y nos contestan

```
## CUARTA PREGUNTA

El endpoint POST /maketoken?email=usuario@dominio es capaz de enviar mails secretos, pero no a cualquier dirección!

Para recibir un mail, debe entrar a https://temp-mail.org/en/ donde automáticamente se le dará una casilla de email temporal.

Usted debe utilizar su nueva casilla de emails para pedir un mail secreto. En este se encontrará un token generado únicamente para usted. Dicho token es la respuesta a esta pregunta.
```

Luego accedemos a [https://temp-mail.org/en/](https://temp-mail.org/en/), nos creamos un mail y tiramos el post al endpoint que nos dicen, con el mail que nos generamos

```sh
curl -X POST 192.168.124.80/maketoken?email=sidiyap206@nriza.com
```

Y nos llega el mail del cual obtenemos 2 cosas:

1. Del texto en blanco: lpm ya perdí tantas veces la clave q tuve q dejarla accesible en un puerto abierto en _"The Vault"_ entre el 49000 y el 50000... Tal vez sí soy el tipo de boludo que dejó un servidor HTTP abierto para esas cosas :-)
2. Este contenido en base 64: UGVybyBxIGJ1ZW5vIHEgc295IGVzY29uZGllbmRvIG1lbnNhamVzIHhEeGQKCkVsIHRva2VuIGVzOiBiR1Z2UFd4bGJ6dHlkR0U5YzNSeWFXNW5YMlZ4ZFdGc2N3PT0KClNhbHVkb3MKCg==

la 1 nos va a servir mas tarde, de la 2 vemos el contenido decodificandolo

```sh
echo "UGVybyBxIGJ1ZW5vIHEgc295IGVzY29uZGllbmRvIG1lbnNhamVzIHhEeGQKCkVsIHRva2VuIGVzOiBiR1Z2UFd4bGJ6dHlkR0U5YzNSeWFXNW5YMlZ4ZFdGc2N3PT0KClNhbHVkb3MKCg==" | base64 -d
```

y obtenemos

```
Pero q bueno q soy escondiendo mensajes xDxd

El token es: bGVvPWxlbztydGE9c3RyaW5nX2VxdWFscw==

Saludos
```

Luego mandamos nuestra respuesta

```sh
curl -X POST 192.168.124.80/papopepoparapapapapiparapopepo/response -H "Content-Type: application/json" -d '{"rta": "bGVvPWxlbztydGE9c3RyaW5nX2VxdWFscw=="}'
```

y nos contestan

```
Muy bien. (Espero que hayas entendido lo que hiciste)

Procedemos a /dalequevamooo para tu última pregunta >:)
```

#### dalequevamooo

Accedemos con

```sh
curl 192.168.124.80/dalequevamooo
```

y nos contestan

```
## ÚLTIMA PREGUNTA!

Sabiendo que este servidor no tiene estado (y por ende no se acuerda qué tokens emitió), ¿Cómo hace para saber que el token que recién ingresaste no fue inventado?

La respuesta a esta pregunta se encuentra en el mismísimo token.
```

Luego agarramos el token y lo decodificamos en base 64

```sh
echo "bGVvPWxlbztydGE9c3RyaW5nX2VxdWFscw==" | base64 -d
```

y obtenemos

```
leo=leo;rta=string_equals
```

Luego mandamos nuestra respuesta

```sh
curl -X POST 192.168.124.80/dalequevamooo/response -H "Content-Type: application/json" -d '{"rta": "string_equals"}'
```

y nos contestan

```
Felicidades!

La respuesta es correcta; "string_equals".

Esta también resulta ser **la contraseña de la clave SSH** de el servidor The Vault...

(Si aún no sabés dónde encontrar esta clave, volvé al mensaje de email y leé entre las líneas...)

;-)
```

Por lo que recordamos `string_equals` como la passphrase de la clave ssh y vamos a entrar a *The Vault*

### The Vaullt

Recordamos que en el mail nos dijeron:

> lpm ya perdí tantas veces la clave q tuve q dejarla accesible en un puerto abierto en _"The Vault"_ entre el 49000 y el 50000... Tal vez sí soy el tipo de boludo que dejó un servidor HTTP abierto para esas cosas :-)

Luego hacemos un escaneo

```sh
nmap 6.9.4.20 -p 49000-50000
```

y obtenemos

```
Starting Nmap 7.94SVN ( https://nmap.org ) at 2026-05-20 02:29 UTC
Nmap scan report for 6.9.4.20
Host is up (0.000013s latency).
Not shown: 1000 closed tcp ports (reset)
PORT      STATE SERVICE
49681/tcp open  unknown

Nmap done: 1 IP address (1 host up) scanned in 0.09 seconds
```

Osea que hay un servidor HTTP corriendo en el puerto 49681. Veamos que hay

```sh
curl 6.9.4.20:49681
```

y obtenemos

```html
<!DOCTYPE HTML>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Directory listing for /</title>
</head>
<body>
<h1>Directory listing for /</h1>
<hr>
<ul>
<li><a href="cat.jpg">cat.jpg</a></li>
<li><a href="IMPORTANTE_NOMBRE_DE_USUARIO.txt">IMPORTANTE_NOMBRE_DE_USUARIO.txt</a></li>
<li><a href="supersecretkey">supersecretkey</a></li>
</ul>
<hr>
</body>
</html>
```

Luego nos guardamos el nombre de usuario y la key

```sh
curl 6.9.4.20:49681/IMPORTANTE_NOMBRE_DE_USUARIO.txt -o user.txt
curl 6.9.4.20:49681/supersecretkey -o key
```

Hacemos `cat user.txt` y vemos la salida

```
IMPORTANTE!!!

El nombre de usuario de tu servidor SSH es "bububu"

NO TE OLVIDES
```

Le cambiamos los permisos para poder usarla como ssh key

```sh
chmod 600 key
```

y ahora entramos a *The Vault*

```sh
ssh -i ./key bububu@6.9.4.20
```

Ingresamos `string_equals` como passphrase y

![](attachments/Pasted%20image%2020260519234553.png)
