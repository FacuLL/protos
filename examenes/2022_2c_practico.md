
## Ejercicio 2

![](attachments/Pasted%20image%2020260526181225.png)


Primero desde nuestra compu hacemos un tunel 

```sh
ssh -R 5522:localhost:8080 rohernandez@pampero.itba.edu.ar
```

y en nuestra compu vamos a redirigir la salida de el puerto 8080 a el `archivo.log`

```sh
nc -l localhost 8080 > archivo.log
```

Ahora en pampero

```sh
tail -f /etc/pdc | nc localhost 5522
```

Y ahi ya lo esta redirigiendo, luego en nuestra compu podemos ver el contenido en tiempo real ejecutando

```sh
tail -f archivo.log
```

