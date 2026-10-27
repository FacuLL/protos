---
materia: protos
tipo: apuntes
---

# Routing

---

El **routing** (o enrutamiento) es el proceso de determinar la ruta que deben seguir los paquetes de una red hacia otra en cualquier parte del mundo. Es fundamental distinguir entre:

*   **Forwarding (o reenvío):** Acto de pasar paquetes de una interfaz de entrada a una de salida en un router, basándose en la información de las tablas de ruteo.
*   **Protocolos de routing:** Programas encargados de intercambiar información entre routers para construir y mantener dichas tablas de ruteo de forma dinámica.

---

## Tipos de Routing

Existen tres configuraciones comunes para el manejo de rutas en una red:

1.  **Routing Mínimo:** Se da en redes aisladas de otras redes TCP/IP, donde solo existe conectividad local.
2.  **Routing Estático:** La tabla de ruteo es construida y mantenida manualmente por un administrador de red. No se adapta a cambios topológicos automáticamente.
3.  **Routing Dinámico:** La tabla se construye automáticamente mediante el intercambio de información entre routers utilizando protocolos específicos.

>[!note]
>En routing dinamico, mientras se actualizan las tablas de routeo, hay perdida de paquetes.
>Se busca minimizar este tiempo

### ICMP Redirect
Las tablas de ruteo también pueden actualizarse mediante paquetes **ICMP Redirect** (Type 5). Un router envía este mensaje a un host de su misma red para informarle que existe un gateway más óptimo para alcanzar un destino específico.

---

## Clasificación de Protocolos Dinámicos

Los protocolos de routing dinámico se dividen según el ámbito de aplicación:

### Interior Gateway Protocols (IGP)
Diseñados para redes bajo el control de una sola organización (Sistemas Autónomos pequeños o medianos).
*   Ejemplos: **RIP**, **OSPF**, **IS-IS**, **EIGRP**.

### Exterior Gateway Protocols (EGP)
Diseñados para intercambiar información entre distintos Sistemas Autónomos (redes de diferentes organizaciones).
*   Estándar actual: **BGP** (Border Gateway Protocol).

---

## Algoritmos de Routing Dinámico

### Algoritmos de Ruteo Descentralizado (Distance Vector)
Cada router mantiene una tabla con la distancia mínima conocida a cada destino y el vecino a través del cual se alcanza. Periódicamente, cada router comparte su tabla de ruteo completa con sus vecinos directos.

*   **Algoritmo (Bellman-Ford):**
    1.  El router $X$ recibe de su vecino $V$ una distancia $d_V(D)$ hacia el destino $D$.
    2.  $X$ calcula su propia distancia: $d_X(D) = \min(d_X(D), \text{costo}(X, V) + d_V(D))$.
    3.  Si la distancia cambió, $X$ actualiza su tabla y notifica a sus vecinos en el próximo ciclo.

> [!IMPORTANT]
> **Problema: Cuenta al Infinito (Count-to-Infinity)**
> Este problema ocurre porque el algoritmo es propenso a creer en "rumores" positivos pero reacciona mal ante fallas.
> 1. Si un enlace hacia un destino $D$ cae, el router que lo detecta pone su distancia como $\infty$.
> 2. Sin embargo, un vecino podría informarle que *él* todavía tiene una ruta hacia $D$ (que en realidad pasaba por el router que acaba de fallar).
> 3. El router original cree que esa es una ruta válida, actualiza su tabla a un valor mayor, y ambos routers incrementan sus métricas paso a paso buscando el infinito.
> **Las buenas noticias viajan rápido, las malas viajan lento.**

> [!TIP]
> **Soluciones a la Cuenta al Infinito**
> - **Split Horizon:** No reenviar información sobre una ruta al vecino del cual se aprendió dicha ruta.
> - **Ruta Envenenada (Poison Reverse):** Informar la ruta al vecino de origen con una métrica infinita ($\infty$) para romper el bucle inmediatamente.
> - **Actualizaciones Disparadas (Triggered Updates):** Enviar las malas noticias inmediatamente sin esperar al próximo ciclo periódico de 30 segundos.

### Algoritmos de Ruteo Globales (Link State)
Requieren un conocimiento global y completo de toda la red. Cada router posee una visión completa de la topología de la red.
*   **Funcionamiento:** Cada router descubre a sus vecinos, mide el costo de los enlaces, construye un paquete de estado de enlace (LSP) y lo inunda a **toda** la red. Luego, utiliza el algoritmo de **Dijkstra** para calcular el camino más corto a cada router.

---

## Sistemas Autónomos (AS)
Un **Sistema Autónomo** es un conjunto de redes bajo una misma administración o política de routing común.
*   **IGP (Interior Gateway Protocol):** Utilizados para la comunicación interna dentro de un AS. (Ej: RIP, OSPF, IS-IS, EIGRP).
*   **EGP (Exterior Gateway Protocol):** Utilizados para la comunicación entre distintos AS. (Ej: BGP).

Ejemplos de AS: IPLAN, Telecom, UBA.

---

## RIP (Routing Information Protocol)

Protocolo basado en **Vector de Distancia**. Utiliza el número de **saltos** (hops) como métrica de costo.

| Característica | RIP v1 (RFC 1058 - 1988) | RIP v2 (RFC 2453 - 1998) |
| :--- | :--- | :--- |
| **Tipo** | Classful (Máscara natural) | CIDR (Soporta máscaras variables) |
| **Envío** | Broadcast | Multicast (`224.0.0.9`) |
| **Autenticación** | No soportada | Opcional |
| **Límite** | 15 saltos (16 es $\infty$) | 15 saltos (16 es $\infty$) |
| **Compatibilidad** | - | Compatible con RIP v1 |

> [!NOTE]
> En sistemas Unix/Linux, RIP se implementa mediante el demonio **routed**. No requiere parámetros obligatorios, pero puede usar `/etc/gateways` para configuraciones iniciales.

---

## OSPF (Open Shortest Path First)

Protocolo basado en **Estado de Enlace** (RFC 2328 - 1998). Es un estándar abierto muy utilizado en redes grandes.

*   **Métrica:** Permite asignar pesos (costos) a los enlaces.
*   **Actualización:** Se envía información cuando se detecta un cambio en la topología.
*   **Jerarquía:** Permite definir **áreas** para reducir la carga de procesamiento y el tamaño de las tablas.
*   **Área 0 (Backbone):** Es el área central a la cual deben conectarse todas las demás áreas a través de routers de borde (**ABR**).
*   **Áreas Stub:** Áreas que no requieren un router de borde de gran capacidad; suelen usar rutas estáticas o por defecto.

> [!NOTE]
> En Unix, OSPF se implementa mediante el demonio **gated**, que permite configurar múltiples protocolos en el archivo `/etc/gated.conf`.


---

## Comparativa: Distance Vector vs. Link State

| Característica | Distance Vector (ej. RIP) | Link State (ej. OSPF) |
| :--- | :--- | :--- |
| **Visión** | Solo a través de vecinos | Topología completa de la red |
| **Cálculo** | Suma de distancias | Algoritmo Dijkstra (camino más corto) |
| **Actualización** | Periódica (frecuente) | Disparada por cambios |
| **Convergencia** | Lenta (riesgo de bucles) | Rápida |
| **Límite de red** | 15 saltos (en RIP) | Sin límite teórico |


## Preguntas

### Pregunta 1

![](attachments/Pasted%20image%2020260506185930.png)

2. Estatico

![](attachments/Pasted%20image%2020260506191422.png)

2. Determinar la ruta optima

![](attachments/Pasted%20image%2020260506191430.png)

3. Enrutamiento que se adapta en forma automatica al trafico de red o a los cambios de topologia

![](attachments/Pasted%20image%2020260506191439.png)

2. Numero de saltos

### Pregunta 2

![](attachments/Pasted%20image%2020260506192202.png)

En total tenemos $4 \cdot 5 = 20$ subredes cada una con 20 computadoras.

RIPv1 es un protocolo que **no** envia la mascara de subred en sus actualizaciones, no podria entender esta division y fallaria. En cambio RIPv2 soporta VLSM y permite que las 20 subredes se comuniquen correctamente

**Catedra**: Como la cantidad de saltos y subredes no es muy grande se podria usar RIPv2

osea RIPv1 se queda corto y OSPF es un *overkil*

### Pregunta 3

![](attachments/Pasted%20image%2020260506193206.png)

Si.

Si esta creciendo constantemente y hay cada vez as subredes, podria ser conveniente usar OSPF creando 4 zonas para las subredes principales dentro de cada red RIPv2






---

## Referencias
- Ver [[6_Red#Routing|Conceptos de Forwarding vs Routing]]
- Bibliografía recomendada: Capítulos 4.5 y 4.6.
