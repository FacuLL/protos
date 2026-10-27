---
tags:
  - protos
  - practica
  - sockets
  - c
  - guia
---

# Guía Práctica: Sockets (API Berkeley en C)

---

## Creación de un socket

```c
#include <sys/socket.h>

int fd = socket(domain, type, protocol);
// Retorna file descriptor si OK, -1 en error
```

| Parámetro | Valores comunes |
|---|---|
| `domain` | `AF_INET` (IPv4), `AF_INET6` (IPv6), `AF_UNIX` (local) |
| `type` | `SOCK_STREAM` (TCP), `SOCK_DGRAM` (UDP), `SOCK_RAW` |
| `protocol` | `0` (default), `IPPROTO_TCP`, `IPPROTO_UDP`, `IPPROTO_SCTP` |

```c
// TCP IPv4
int s = socket(AF_INET, SOCK_STREAM, 0);

// UDP IPv4
int s = socket(AF_INET, SOCK_DGRAM, 0);
```

---

## Dirección de socket

```c
struct sockaddr_in addr = {
    .sin_family = AF_INET,
    .sin_port   = htons(8080),     // IMPORTANTE: siempre usar htons()
    .sin_addr.s_addr = INADDR_ANY  // escuchar en todas las interfaces
};

// Para conectarse a un IP específico:
inet_pton(AF_INET, "192.168.1.10", &addr.sin_addr);
```

> `htons()` = host to network short: convierte de little-endian a big-endian (la red usa big-endian).

---

## Flujo TCP — servidor

```c
int server_fd = socket(AF_INET, SOCK_STREAM, 0);

// Evitar "Address already in use"
int opt = 1;
setsockopt(server_fd, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt));

bind(server_fd, (struct sockaddr*)&addr, sizeof(addr));
listen(server_fd, 10);    // 10 = backlog (conexiones pendientes en cola)

while (1) {
    struct sockaddr_in client_addr;
    socklen_t len = sizeof(client_addr);
    int client_fd = accept(server_fd, (struct sockaddr*)&client_addr, &len);

    // Atender la conexión (leer/escribir con client_fd)
    char buf[1024];
    recv(client_fd, buf, sizeof(buf), 0);
    send(client_fd, "respuesta", 9, 0);

    close(client_fd);
}
```

## Flujo TCP — cliente

```c
int fd = socket(AF_INET, SOCK_STREAM, 0);

struct sockaddr_in server = {
    .sin_family = AF_INET,
    .sin_port   = htons(8080),
};
inet_pton(AF_INET, "127.0.0.1", &server.sin_addr);

connect(fd, (struct sockaddr*)&server, sizeof(server));

send(fd, "GET / HTTP/1.0\r\n\r\n", 18, 0);

char buf[4096];
int n = recv(fd, buf, sizeof(buf), 0);

close(fd);
```

---

## Flujo UDP — servidor y cliente

```c
// Servidor UDP
int s = socket(AF_INET, SOCK_DGRAM, 0);
bind(s, (struct sockaddr*)&addr, sizeof(addr));

struct sockaddr_in client;
socklen_t len = sizeof(client);
char buf[1024];
recvfrom(s, buf, sizeof(buf), 0, (struct sockaddr*)&client, &len);
sendto(s, "respuesta", 9, 0, (struct sockaddr*)&client, len);

// Cliente UDP
int s = socket(AF_INET, SOCK_DGRAM, 0);
sendto(s, "data", 4, 0, (struct sockaddr*)&server, sizeof(server));
recvfrom(s, buf, sizeof(buf), 0, NULL, NULL);
```

---

## Resolución de nombres (DNS desde C)

```c
#include <netdb.h>

struct addrinfo hints = {
    .ai_family   = AF_UNSPEC,     // IPv4 o IPv6
    .ai_socktype = SOCK_STREAM,
};

struct addrinfo *res;
getaddrinfo("www.google.com", "80", &hints, &res);

// Usar res->ai_addr, res->ai_addrlen para connect()
// Si hay múltiples resultados: iterar con res->ai_next

freeaddrinfo(res);   // liberar la lista
```

---

## Multiplexing de I/O

### select()

```c
fd_set rfds;
FD_ZERO(&rfds);
FD_SET(fd1, &rfds);
FD_SET(fd2, &rfds);

struct timeval tv = {.tv_sec = 5, .tv_usec = 0};  // timeout 5 segundos

int ready = select(max_fd + 1, &rfds, NULL, NULL, &tv);
// ready > 0: hay fds listos
// ready == 0: timeout
// ready == -1: error

if (FD_ISSET(fd1, &rfds)) {
    // fd1 tiene datos para leer
}
```

### poll()

```c
struct pollfd fds[] = {
    {.fd = fd1, .events = POLLIN},
    {.fd = fd2, .events = POLLIN},
};
int n = poll(fds, 2, 5000);  // timeout 5000ms

if (fds[0].revents & POLLIN) { /* fd1 listo */ }
```

### epoll() (Linux, más eficiente para muchos fds)

```c
int epfd = epoll_create1(0);

struct epoll_event ev = {.events = EPOLLIN, .data.fd = fd};
epoll_ctl(epfd, EPOLL_CTL_ADD, fd, &ev);

struct epoll_event events[10];
int n = epoll_wait(epfd, events, 10, -1);  // -1 = sin timeout

for (int i = 0; i < n; i++) {
    int ready_fd = events[i].data.fd;
    // leer de ready_fd
}
```

> `epoll` no itera sobre todos los fds: el kernel notifica solo los activos → mejor rendimiento con muchas conexiones.

---

## Socket no bloqueante

```c
#include <fcntl.h>

int flags = fcntl(s, F_GETFL, 0);
fcntl(s, F_SETFL, flags | O_NONBLOCK);

// Ahora recv/send retornan -1 con errno=EWOULDBLOCK si no hay datos
// connect() retorna -1 con errno=EINPROGRESS (la conexión sigue en curso)
```

---

## Socket options importantes

```c
// SO_REUSEADDR: evitar "Address already in use" al reiniciar el servidor
int opt = 1;
setsockopt(s, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt));

// SO_RCVTIMEO: timeout de lectura
struct timeval tv = {.tv_sec = 5, .tv_usec = 0};
setsockopt(s, SOL_SOCKET, SO_RCVTIMEO, &tv, sizeof(tv));

// TCP_NODELAY: deshabilitar Nagle (enviar inmediatamente sin buffering)
int flag = 1;
setsockopt(s, IPPROTO_TCP, TCP_NODELAY, &flag, sizeof(flag));

// SO_KEEPALIVE: detectar conexiones caídas
setsockopt(s, SOL_SOCKET, SO_KEEPALIVE, &opt, sizeof(opt));
```

---

## Señales relevantes en sockets

| Señal | Causa | Qué hacer |
|---|---|---|
| `SIGPIPE` | Escribir en socket cerrado por el otro extremo | Ignorar o manejar; sin handler el proceso termina |
| `SIGCHLD` | Proceso hijo terminó | Llamar a `waitpid()` para evitar zombies |
| `EINTR` | Una señal interrumpió un socket call | Reintentar la llamada |

```c
// Ignorar SIGPIPE
signal(SIGPIPE, SIG_IGN);

// Reintentar si fue interrumpido por señal
while (1) {
    int n = recv(sock, buf, sizeof(buf), 0);
    if (n == -1 && errno == EINTR) continue;
    break;
}
```

---

## shutdown() vs close()

```c
shutdown(fd, SHUT_WR);   // cerrar solo la mitad de escritura (envía FIN)
shutdown(fd, SHUT_RD);   // cerrar solo la mitad de lectura
shutdown(fd, SHUT_RDWR); // cerrar ambas

close(fd);               // cierra el fd; el kernel envía FIN cuando puede
                         // (si SO_LINGER=0, envía RST inmediatamente)
```

---

## Servidor iterativo vs concurrente

```c
// Concurrente con fork()
int client_fd = accept(server_fd, NULL, NULL);
if (fork() == 0) {
    // proceso hijo
    close(server_fd);    // el hijo no necesita el socket pasivo
    handle_client(client_fd);
    close(client_fd);
    exit(0);
} else {
    // proceso padre
    close(client_fd);    // el padre no necesita el socket activo
}
```

> Siempre hacer `waitpid()` en el padre (o ignorar SIGCHLD con SA_NOCLDWAIT) para evitar procesos zombie.
