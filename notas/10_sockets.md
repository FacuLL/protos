---
materia: protos
tipo: apuntes
---

# Sockets

Un **socket** es una abstracción de la API de red que permite a un proceso comunicarse con otro proceso en la misma máquina o en hosts remotos. El S.O. lo representa como un *file descriptor* en la tabla de descriptores del proceso.

> [!IMPORTANT] Definición
> Un socket identifica un *endpoint* de comunicación mediante la combinación de **IP + puerto**. Cada host se identifica por su IP; el número de puerto distingue al proceso dentro del host (ej: `80` → HTTP, `5432` → PostgreSQL).

Para UDP alcanza con 1 socket.

En TCP tenemos sockets **activos** (conectados a un cliente) y **pasivos** (de escucha, esperando conexiones).

El protocolo de nivel de aplicación debe definir:
- Tipos de mensajes intercambiados
- Sintaxis de los mensajes
- Semántica de los mensajes
- Reacción frente a errores

---

## Socket API (Berkeley)

**Berkeley sockets** fue diseñado en los 80 para UNIX. Es la API más aceptada junto con Winsock (Microsoft) y TLI (AT&T).

Características:
- Reutiliza system calls existentes (como `read`/`write`)
- Soporta múltiples familias de protocolos, no solo TCP/IP
- El usuario indica la **familia** (ej: `PF_INET`) y el **tipo de servicio** (con o sin conexión)

### Creación de un socket

```c
#include <sys/socket.h>
// Retorna: file descriptor si OK, -1 en error
int socket(int domain, int type, int protocol);
```

| Parámetro  | Descripción                        | Valores comunes                                                                            |
| ---------- | ---------------------------------- | ------------------------------------------------------------------------------------------ |
| `domain`   | Familia de la dirección            | `AF_INET`, `AF_INET6`, `AF_UNIX`, `AF_UNSPEC`                                              |
| `type`     | Tipo de comunicación               | `SOCK_STREAM` (TCP), `SOCK_DGRAM` (UDP), `SOCK_RAW`, `SOCK_SEQPACKET` (no lo vamos a usar) |
| `protocol` | Protocolo específico (0 = default) | `IPPROTO_TCP`, `IPPROTO_UDP`, `IPPROTO_SCTP`                                               |

### Formato de direcciones

Las direcciones son específicas por familia y se castean al formato genérico `sockaddr`:

```c
struct sockaddr {
    sa_family_t sa_family; // familia de la dirección
    char        sa_data[...]; // dirección de longitud variable
};
```

**IPv4:**
```c
struct sockaddr_in {
    sa_family_t  sin_family; // AF_INET
    in_port_t    sin_port;   // uint16_t: número de puerto
    struct in_addr sin_addr; // uint32_t: dirección IPv4
    unsigned char  sin_zero[8]; // relleno
};

int bind(int socket, const struct sockaddr *address, socklen_t address_len);
```

**IPv6:**
```c
struct sockaddr_in6 {
    sa_family_t  sin6_family;   // AF_INET6
    in_port_t    sin6_port;
    uint32_t     sin6_flowinfo;
    struct in6_addr sin6_addr;  // 16 bytes
    uint32_t     sin6_scope_id;
};


bind( socket, (struct sockaddr *) (&myAddress), sizeof(myAddress));[[]()]()
```

### Resolución de nombres

Si el cliente solo conoce el FQDN del servidor, debe resolverlo:

```c
#include <sys/socket.h>
#include <netdb.h>

int getaddrinfo(const char *restrict host,
                const char *restrict service,
                const struct addrinfo *restrict hint,
                struct addrinfo **restrict res);

void freeaddrinfo(struct addrinfo *ai);
```

La estructura `addrinfo` retornada contiene familia, tipo, protocolo, dirección y un puntero al siguiente resultado (lista enlazada).

### Socket I/O

La comunicación en un socket es **bidireccional** (*full duplex*). Se puede deshabilitar con `shutdown`:

```c
int shutdown(int sockfd, int how);
// how: SHUT_RD | SHUT_WR | SHUT_RDWR
```

---

## Sockets bloqueantes

En el modelo bloqueante, las llamadas de I/O **suspenden el proceso** hasta que la operación se completa.

### Flujo TCP (cliente/servidor)


![](attachments/Pasted%20image%2020260514193531.png)


El servidor puede ser **iterativo** (atiende una conexión a la vez) o **concurrente** (crea un proceso/hilo por conexión).

### Diseño de servidor iterativo (sin conexión — UDP)

1. Crear socket y ligarlo (`bind`) a un puerto
2. Leer un datagrama *request* del cliente
3. Enviar datagrama/s como respuesta
4. Volver al paso 2

> [!NOTE] Un **datagrama** es un mensaje auto-suficiente (lleva toda la info necesaria para ser enrutado).

### Diseño de servidor iterativo (orientado a conexión — TCP)

1. Crear socket y ligarlo (`bind`) a un puerto
2. Aceptar pedido de conexión (`accept`)
3. Obtener nuevo socket para esa conexión
4. Leer *request* del cliente
5. Enviar respuesta
6. Si el cliente no finalizó, volver al paso 4
7. Cerrar el socket de la conexión
8. Volver al paso 2

> [!TIP] El servidor iterativo tiene un problema: si atiende una transferencia de 200 MB, bloquea a todos los demás clientes hasta terminar. El servidor concurrente resuelve esto.

### Diseño de servidor concurrente con multitasking (TCP)

**Master (proceso padre):**
1. Crear socket y ligarlo a un puerto
2. Aceptar pedido de conexión
3. Crear proceso hijo para atender la conexión
4. Volver al paso 2

**Slave (proceso hijo):**
1. Atender la conexión pasada por el master
2. Interactuar con el cliente
3. Cerrar la conexión y finalizar el proceso

---

## Multiplexing de I/O

Permite que un proceso atienda **múltiples canales** (puertos, protocolos) desde un único hilo, sin bloquearse indefinidamente en uno solo.

### `select()`

Se bloquea hasta que al menos uno de los descriptores del conjunto esté listo para I/O:

```c
int select(int n,
           fd_set *readfds,
           fd_set *writefds,
           fd_set *exceptfds,
           struct timeval *timeout);
```

Los fd-sets son arrays de bits. Se manipulan con macros:
- `FD_ZERO(set)` — limpiar conjunto
- `FD_SET(fd, set)` — agregar fd
- `FD_CLR(fd, set)` — quitar fd
- `FD_ISSET(fd, set)` — verificar si fd está listo

### `pselect()`

Similar a `select` pero permite bloquear señales durante la espera (evita race conditions con señales UNIX):

```c
int pselect(int n, fd_set *readfds, fd_set *writefds, fd_set *exceptfds,
            const struct timespec *timeout, const sigset_t *sigmask);
```

### `poll()`

A diferencia de `select`, recibe **solo los fds de interés** (no un array de tamaño fijo):

```c
int poll(struct pollfd *fds, unsigned int nfds, int timeout);

struct pollfd {
    int   fd;
    short events;  // eventos a vigilar
    short revents; // eventos que ocurrieron
};
```

### `epoll()` (Linux)

Solución más eficiente para muchos descriptores:

```c
int epoll_create1(int flags);
int epoll_ctl(int epfd, int op, int fd, struct epoll_event *event);
int epoll_wait(int epfd, struct epoll_event *events, int maxevents, int timeout);
```

> [!NOTE] `epoll` escala mejor que `select`/`poll` porque no itera sobre todos los fds en cada llamada; el kernel notifica solo los que tienen actividad.

---

## Socket Options

Permiten consultar o modificar el comportamiento de un socket:

```c
#include <sys/socket.h>

int getsockopt(int socket, int level, int optionName,
               void *restrict optionValue, socklen_t *restrict optionLen);

int setsockopt(int socket, int level, int optionName,
               const void *optionValue, socklen_t optionLen);
```

El parámetro `level` indica a qué capa pertenece la opción:

| Level | Aplica a |
|-------|----------|
| `SOL_SOCKET` | Opciones independientes del protocolo |
| `IPPROTO_TCP` | Opciones específicas de TCP |
| `IPPROTO_IP` | Opciones de IP v4 |
| `IPPROTO_IPV6` | Opciones de IP v6 |

### Opciones SOL_SOCKET

| Opción         | Descripción                                                         |
| -------------- | ------------------------------------------------------------------- |
| `SO_BROADCAST` | Habilita envío broadcast (0 ó 1)                                    |
| `SO_KEEPALIVE` | Envía keepalives para detectar conexiones caídas                    |
| `SO_RCVBUF`    | Tamaño en bytes del buffer de entrada                               |
| `SO_SNDBUF`    | Tamaño del buffer de salida                                         |
| `SO_RCVLOWAT`  | Mínimo de bytes para procesar el input                              |
| `SO_SNDLOWAT`  | Mínimo de bytes para procesar el output                             |
| `SO_RCVTIMEO`  | Timeout máximo para operaciones de lectura                          |
| `SO_LINGER`    | Si = 0: envía RST al hacer `close()` → *"connection reset by peer"* |
| `SO_REUSEADDR` | Al abortar el programa, reusar dirección y puerto                   |
| `SO_REUSEPORT` | Permite múltiples sockets en el mismo puerto                        |

### Opciones IPPROTO_TCP / IPPROTO_IP / IPPROTO_IPV6

| Opción | Descripción |
|--------|-------------|
| `TCP_KEEPIDLE`, `TCP_KEEPINTVL`, `TCP_KEEPCNT` | Control de keepalive TCP |
| `TCP_NODELAY` | Deshabilita el algoritmo de Nagle (0 ó 1) |
| `IP_TTL` | Time-to-live del paquete IP \[0, 255\] |
| `IP_MULTICAST_LOOP` | Habilita recepción de paquetes multicast propios |
| `IP_ADD_MEMBERSHIP` / `IP_DROP_MEMBERSHIP` | Gestión de grupos multicast |
| `IPV6_V6ONLY` | Restringe el socket solo a IPv6 |

---

## Signals

Las **señales** son un mecanismo del S.O. para notificar a un proceso que ocurrió un evento asincrónico. Ante una señal, el proceso puede:
- Ignorarla
- Terminar abruptamente
- Ejecutar una *rutina de manejo de señal* (signal handler)
- Bloquearla temporalmente

### Señales relevantes

| Señal      | Evento                        | Acción por defecto |
| ---------- | ----------------------------- | ------------------ |
| `SIGALARM` | Expiró un timer               | Terminar           |
| `SIGCHLD`  | Exit de proceso hijo          | Ignorar            |
| `SIGINT`   | Ctrl+C                        | Terminar           |
| `SIGIO`    | Socket listo para I/O         | Ignorar            |
| `SIGPIPE`  | Escritura en socket cerrado   | Terminar           |
| `SIGSEGV`  | Segmentation fault            | Terminar           |
| `SIGTERM`  | Terminación "amable" (`kill`) | Terminar           |
| `SIGKILL`  | Terminación forzosa           | Terminar           |

### Configurar el comportamiento con `sigaction()`

```c
int sigaction(int signum, const struct sigaction *act,
              struct sigaction *oldact);

struct sigaction {
    void      (*sa_handler)(int); // SIG_IGN, SIG_DFL, o función handler
    sigset_t  sa_mask;            // señales a bloquear mientras corre sa_handler
    int       sa_flags;
};
```

Para manipular el conjunto de señales bloqueadas:

```c
sigemptyset(sigset_t *set);        // vaciar conjunto
sigfillset(sigset_t *set);         // llenar con todas las señales
sigaddset(sigset_t *set, int sig); // agregar señal
sigdelset(sigset_t *set, int sig); // quitar señal
```

> [!NOTE] Las señales **no se encolan**: si llega una segunda señal del mismo tipo mientras se atiende la primera, el manejo es pospuesto pero solo se ejecutará una vez que termine el handler actual.

### Señales y socket calls

> [!IMPORTANT] Si una señal llega mientras el proceso está bloqueado en un socket call (`recv`, `connect`, `select`, etc.) y esa señal tiene un handler definido, cuando el handler termina el socket call **retorna `-1`** con `errno = EINTR`.

El patrón idiomático para manejar esto:

```c
while (1) {
    errno = 0;
    int rc = recv(sock, buf, 1, 0);
    if (rc == -1 && errno == EINTR)
        continue; // fue interrumpido por señal, reintentar
    // ...
}
```

---

## Sockets no bloqueantes

Las llamadas a E/S pueden bloquearse por:
- `recv()`, `recvfrom()`: no hay datos en el buffer de entrada
- `send()`: no hay espacio suficiente en el buffer de salida
- `connect()`, `accept()`: hasta que se completa la conexión

Para evitar el bloqueo existen tres estrategias:

### Estrategia 1: socket no bloqueante con `O_NONBLOCK`

Se configura el socket con `fcntl()`:

```c
#include <fcntl.h>

int s = socket(PF_INET, SOCK_STREAM, 0);
int flags = fcntl(s, F_GETFL, 0);
fcntl(s, F_SETFL, flags | O_NONBLOCK);
```

- Si la operación puede completarse inmediatamente → retorna éxito
- Si necesitaría bloquear → retorna `-1` con `errno = EWOULDBLOCK`
- En TCP, `connect()` retorna `-1` con `errno = EINPROGRESS` (la conexión sigue en curso)
- `getaddrinfo()` **siempre bloquea** hasta resolver el nombre

> [!TIP] El polling activo (busy-wait revisando `EWOULDBLOCK` en un loop) tiene mal rendimiento. Combinar con `select`/`epoll` es la forma correcta.

### Estrategia 2: I/O asincrónico con `SIGIO`

En lugar de *polling*, el S.O. notifica al proceso vía señal `SIGIO` cuando el socket está listo:

1. Usar `sigaction()` para capturar `SIGIO`
2. Usar `fcntl()` con `F_SETOWN` para hacerse owner del socket
3. Usar `fcntl()` con `O_NONBLOCK` para no bloquear el socket

El programa realiza otras tareas y solo interrumpe su ejecución cuando llega `SIGIO`.

### Estrategia 3: timeouts con `SO_RCVTIMEO`

Configurar un timeout máximo de espera usando `setsockopt`:

```c
struct timeval timeout = {.tv_sec = 5, .tv_usec = 0};
setsockopt(sock, SOL_SOCKET, SO_RCVTIMEO, &timeout, sizeof(timeout));
```

Si no llegan datos en ese tiempo, la operación retorna `-1` con `errno = EAGAIN` o `EWOULDBLOCK`.


