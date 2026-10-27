---
tags:
  - protos
  - practica
  - dns
  - guia
---

# Guía Práctica: DNS

---

## dig — el comando más importante

```sh
dig <dominio>                          # consulta A record (IPv4)
dig <dominio> MX                       # registro MX (servidores de mail)
dig <dominio> NS                       # servidores autoritativos
dig <dominio> SOA                      # inicio de autoridad (serial, TTL, etc.)
dig <dominio> TXT                      # registros de texto (SPF, DKIM)
dig <dominio> AAAA                     # IPv6
dig <dominio> +trace                   # traza completa desde root servers
dig <dominio> @<ip-servidor>           # usar un DNS específico
dig <dominio> @1.1.1.1                 # usar Cloudflare como resolver
dig <dominio> @8.8.8.8                 # usar Google como resolver
dig -x <ip>                            # resolución inversa (PTR)
```

### Patrones de uso en parcial

```sh
# Ver qué serial tiene www.google.com según un DNS específico
dig SOA google.com @192.168.124.53

# Consultar MX del ITBA
dig MX itba.edu.ar

# Traza de resolución
dig pampero.it.itba.edu.ar +trace

# SPF (registro TXT)
dig TXT itba.edu.ar
```

→ Ver [[guia_respuestas#E42|E42]], [[guia_respuestas#E44|E44]], [[guia_respuestas#E45|E45]], [[guia_respuestas#E62|E62]]  
→ Ver [[Ejercicio_integrador#ketylanuchi]]

---

## Tipos de registros DNS

| Tipo | Para qué sirve | Ejemplo de valor |
|---|---|---|
| **A** | Hostname → IPv4 | `6.7.8.9` |
| **AAAA** | Hostname → IPv6 | `2001:db8::1` |
| **NS** | Servidor autoritativo del dominio | `crystal.it.itba.edu.ar.` |
| **MX** | Servidor de mail (+ prioridad) | `10 aspmx.l.google.com.` |
| **CNAME** | Alias → nombre canónico | `www → servidor-real.com.` |
| **PTR** | IP → nombre (inverso) | `137.121.5.200.in-addr.arpa.` |
| **TXT** | Texto libre (SPF, verificación) | `"v=spf1 include:..."` |
| **SOA** | Info técnica de la zona | serial, refresh, retry, expire |

> En registros MX: menor número = mayor prioridad.

---

## /etc/hosts y /etc/resolv.conf

```sh
# Agregar alias local (se consulta ANTES que DNS)
echo "127.0.0.1 localhost foo bar" >> /etc/hosts
echo "192.168.1.10 vault.local" >> /etc/hosts

# Ver/cambiar el servidor DNS que usa el sistema
cat /etc/resolv.conf
# nameserver 1.1.1.1
# nameserver 8.8.8.8
```

---

## whois

```sh
whois itba.edu.ar    # dueño, registrador, fechas, NS autoritativos
```

→ Ver [[guia_respuestas#E46|E46]]

---

## Configurar servidor BIND9

### Instalación

```sh
sudo apt install bind9
sudo -i   # escalar a root
```

### `/etc/bind/named.conf.local` — definir zona

```bind
zone "foo.pdc.lab" {
    type master;
    file "/etc/bind/foo.pdc.lab.local";
};
```

### `/etc/bind/foo.pdc.lab.local` — archivo de zona

```bind
$ORIGIN foo.pdc.lab.
$TTL 1m

@ IN SOA ns1.foo.pdc.lab. rohernandez.itba.edu.ar. (
            20260331   ; Serial (fecha o número, incrementar al modificar)
            7d         ; Refresh (cada cuánto el slave consulta al master)
            1d         ; Retry (si falla el refresh, reintentar cada tanto)
            10d        ; Expire (el slave deja de responder si no contacta al master)
            1m         ; Negative TTL (caché de "no existe")
)

; Servidores DNS de la zona (NS es obligatorio — sin esto bind9 rechaza cargar la zona)
@    1m    IN NS ns1
@    2m    IN NS ns2
ns1        IN A 1.2.3.5
ns2        IN A 1.2.3.6

; Servidores de mail
@   2h IN MX 1 nsmail
@   2h IN MX 2 ns2mail
nsmail  IN A 2.2.2.2
ns2mail IN A 2.2.2.3

; Hosts
www     IN A 6.7.8.9
@       IN A 6.7.8.10
w3      CNAME www

; Registro TXT
@  TXT "hola manola"
```

> **Regla crítica**: `Expire > Refresh + Retry`

### El email del SOA (RNAME) — trampa clásica

El segundo campo del SOA es un **mail escrito como nombre DNS**: el `@` se reemplaza por `.`

```
admin@it.itba.edu.ar    →   admin.it.itba.edu.ar.
```

Si la parte local **ya tiene un punto**, hay que escaparlo con `\`:

```
example.admin@foo.com.ar   →   example\.admin.foo.com.ar.
```

Y siempre con **punto final** — sino se le pega el `$ORIGIN`.

### TTL por registro

Se puede pisar el `$TTL` global poniendo el TTL entre el nombre y la clase:

```
@   7d  IN MX 10 mx1.protos.foo.
@   1h  IN A  123.123.123.123
www 7d  IN CNAME @
```

### SPF / DKIM como registro TXT

```
@    IN TXT "v=spf1 ip4:1.2.3.4 -all"
@    IN TXT "v=spf1 ip4:1.2.3.4 include:_spf.google.com ~all"
```

| Sufijo | Qué hacer con el mail de una IP no autorizada |
|---|---|
| `-all` | **fail** — rechazarlo |
| `~all` | softfail — aceptarlo pero marcarlo |
| `?all` | neutral |

### Comandos de mantenimiento

```sh
# Validar ANTES de recargar (hacerlo siempre)
named-checkconf                                              # verifica named.conf
named-checkzone foo.pdc.lab /etc/bind/foo.pdc.lab.local     # verifica zone file

systemctl reload bind9     # recargar sin bajar el servicio
systemctl restart bind9    # reinicio completo
systemctl status bind9
tail -f /var/log/syslog | grep named    # ver errores en tiempo real

# Verificar que funcionó
dig SOA foo.pdc.lab @localhost
dig A ns1.foo.pdc.lab @localhost
```

### Diagnóstico de errores comunes

| Síntoma | Causa probable |
|---|---|
| `SERVFAIL` + sin flag `aa` + `AUTHORITY: 0` | La zona no se cargó — sintaxis incorrecta en el zone file o path mal en named.conf.local |
| `NXDOMAIN` con flag `aa` | La zona cargó bien pero el registro no existe |
| `SERVFAIL` con flag `aa` | La zona cargó pero no puede resolver (ej: falta forwarder para internet) |
| Cambios que no se reflejan | Se olvidó hacer `systemctl reload bind9` |

**Errores frecuentes en zone files:**
- **Faltan registros NS** — zona obligatoriamente necesita al menos un NS. Sin NS, bind9 rechaza cargar la zona → SERVFAIL + sin flag `aa` + AUTHORITY: 0
- **NS apunta a un nombre sin A record** — el nombre del NS debe tener su propio A record en la zona
- **Targets de MX sin A record** — si `mail20` aparece en un MX, necesita un `mail20 IN A ...` en la zona
- **Falta el `.` al final de un FQDN** — `example.org` sin punto final se expande a `example.org.carlitos.com.ar.`; siempre poner punto al referenciar nombres externos
- **SOA MNAME distinto a los NS records** — el primer campo del SOA debería coincidir con uno de los NS records
- **Serial sin incrementar** después de un cambio (los slaves no propagan)
- **`A` con un nombre en vez de una IP** — `www IN A pampero` está **mal**: el valor de un
  `A` tiene que ser una IPv4. Para apuntar a otro nombre va `www IN CNAME pampero`
- **`@` literal en el email del SOA** — `admin@it.itba.edu.ar.` está mal, va `admin.it.itba.edu.ar.`
- **FQDN completo en la columna nombre sin punto final** — `ns1.it.itba.edu.ar IN A 1.2.3.4`
  se expande a `ns1.it.itba.edu.ar.it.itba.edu.ar.`. Poner `ns1` a secas, o el FQDN con punto
- **Falta `$ORIGIN`** — funciona (bind usa el nombre de zona de `named.conf`) pero es mala
  práctica y el parcial lo cuenta como error

### "Que los cambios se propaguen rápido y bien"

Cuando la consigna pide eso, son **dos** cosas:

1. **Incrementar el serial** — sin esto los slaves ni se enteran. Formato `YYYYMMDDNN`.
2. **Bajar los tiempos** — `$TTL` chico (caches de terceros expiran antes) y `Refresh`
   chico (los slaves consultan más seguido). Ej: `$TTL 1m` + `Refresh 15m`.

> Siempre correr `named-checkzone` antes de recargar — si da error, bind9 ignora silenciosamente la zona y sigue con la anterior (o sin ella).

### Configurar forwarder (para que el servidor resuelva internet)

En `/etc/bind/named.conf.options`, agregar:

```bind
forwarders {
    1.1.1.1;
    8.8.8.8;
};
```

→ Ver [[guia_respuestas#E49|E49]], [[guia_respuestas#E53|E53]]

---

## Servidor secundario (slave) — transferencia de zona

Un **slave** no tiene el zone file a mano: se lo **copia del master** por una
*transferencia de zona* (AXFR = completa, IXFR = incremental). El slave decide cuándo
re-consultar según los tiempos del **SOA** (`Refresh`/`Retry`/`Expire`) y, si el master lo
soporta, recibe un **NOTIFY** apenas cambia el serial.

> El único que se edita a mano es el master. El slave se sincroniza solo — por eso **no**
> se le incrementa el serial ni se le toca la zona.

### En el MASTER — autorizar la transferencia

`/etc/bind/named.conf.local`:

```bind
zone "foo.pdc.lab" {
    type master;
    file "/etc/bind/foo.pdc.lab.local";
    allow-transfer { 1.2.3.6; };      # IP del slave (sin esto NO transfiere)
    also-notify { 1.2.3.6; };         # avisar al slave apenas cambia el serial (opcional)
};
```

Y la zona tiene que tener un registro **NS para el slave** (si no, no es autoritativo):

```bind
@   IN NS ns1       ; master
@   IN NS ns2       ; slave
ns2 IN A 1.2.3.6
```

### En el SLAVE — definir la zona como secundaria

`/etc/bind/named.conf.local`:

```bind
zone "foo.pdc.lab" {
    type slave;
    file "/var/cache/bind/foo.pdc.lab.slave";   # BIND lo CREA solo al transferir
    masters { 1.2.3.5; };                       # IP del master
};
```

- **No se crea el zone file a mano** en el slave: BIND lo escribe cuando baja la zona.
- El directorio tiene que ser escribible por bind (`/var/cache/bind/` ya lo es).

```sh
systemctl restart bind9
tail -f /var/log/syslog | grep named     # buscar "transfer of 'foo.pdc.lab' ... Transfer completed"
```

### Verificar la transferencia

```sh
# Pedir la zona completa al master (AXFR) — tiene que listar todos los registros
dig AXFR foo.pdc.lab @1.2.3.5

# Si allow-transfer esta bien restringido, desde una IP no autorizada da "Transfer failed"
dig AXFR foo.pdc.lab @1.2.3.5

# Confirmar que el slave responde con los mismos datos y autoritativo (flag aa)
dig SOA foo.pdc.lab @1.2.3.6
dig A www.foo.pdc.lab @1.2.3.6

# Comparar que master y slave tienen el MISMO serial (+short = solo el valor)
dig SOA foo.pdc.lab @1.2.3.5 +short      # master
dig SOA foo.pdc.lab @1.2.3.6 +short      # slave → mismo serial = sincronizado
```

> [!IMPORTANT]
> El slave solo re-transfiere si el **serial del master es mayor** al que ya tiene.
> Cambiaste la zona y el slave no se actualiza → casi siempre **te olvidaste de subir el
> serial** en el master.

> [!NOTE]
> `Expire` del SOA = cuánto aguanta el slave respondiendo si **no logra** contactar al
> master. Pasado ese tiempo, deja de ser autoritativo y devuelve SERVFAIL.

---

## Zona reversa (PTR) — IP → nombre

La resolución inversa usa el dominio especial **`in-addr.arpa`** con los octetos de la red
**al revés**. Para la red `192.168.100.0/24` → zona `100.168.192.in-addr.arpa`.

`/etc/bind/named.conf.local`:

```bind
zone "100.168.192.in-addr.arpa" {
    type master;
    file "/etc/bind/100.168.192.rev";
};
```

`/etc/bind/100.168.192.rev`:

```bind
$ORIGIN 100.168.192.in-addr.arpa.
$TTL 1m

@ IN SOA ns1.foo.pdc.lab. admin.foo.pdc.lab. (
            20260331 7d 1d 10d 1m )

@    IN NS ns1.foo.pdc.lab.

10   IN PTR www.foo.pdc.lab.      ; 192.168.100.10 -> www.foo.pdc.lab
1    IN PTR gw.foo.pdc.lab.       ; 192.168.100.1
```

- El número suelto (`10`) es el último octeto; se completa con el `$ORIGIN` reverso.
- El valor del PTR **siempre** termina en `.` (es un FQDN).

```sh
named-checkzone 100.168.192.in-addr.arpa /etc/bind/100.168.192.rev
systemctl reload bind9
dig -x 192.168.100.10 @localhost      # tiene que devolver www.foo.pdc.lab
```

---

## rndc — controlar BIND sin reiniciar

```sh
rndc reload                 # recargar todas las zonas
rndc reload foo.pdc.lab     # recargar solo una zona
rndc reconfig               # releer named.conf (zonas nuevas) sin tocar las ya cargadas
rndc flush                  # limpiar la cache del resolver
rndc status                 # estado del server
rndc notify foo.pdc.lab     # forzar NOTIFY a los slaves
```

> `rndc reload` recarga pero **no** sube el serial — eso lo hacés vos en el zone file.

---

## DNS + HTTP: resolver sin internet

Si no hay internet, para que `curl <nombre>` funcione sin DNS real:

1. Agregar entrada en `/etc/hosts`
2. O levantar un servidor BIND local
3. O especificar dirección IP directamente

```sh
# Ejemplo: acceder a "foo.pdc.lab" sin DNS externo
echo "192.168.1.10 foo.pdc.lab" >> /etc/hosts
curl foo.pdc.lab
```

→ Ver [[guia_respuestas#E47|E47]]

---

## Split-Horizon

Un mismo nombre resuelve a diferentes IPs según el origen de la consulta:
- Desde adentro de la red → IP privada
- Desde afuera → IP pública

Ocurre en pampero.it.itba.edu.ar: si usás un DNS externo (8.8.8.8) desde dentro del ITBA, obtenés la IP pública, pero la conexión se rechaza por firewall.

→ Ver [[notas/3_dns#Pregunta 1|Pregunta DNS 1]]
