---
materia: practica
tipo: tutorial
tags:
  - herramientas
  - editor
  - vim
---

# Comandos Útiles de Vim

Vim es un editor de texto modal, lo que significa que tiene diferentes modos para diferentes tareas. Los más importantes son el **Modo Normal** (para moverse y ejecutar comandos) y el **Modo Insertar** (para escribir texto).

## 1. Modos Básicos

- `Esc`: Vuelve al **Modo Normal** desde cualquier otro modo. Es tu salvavidas.
- `i`: Entra al **Modo Insertar** antes del cursor.
- `I`: Entra al **Modo Insertar** al principio de la línea.
- `a`: Entra al **Modo Insertar** después del cursor.
- `A`: Entra al **Modo Insertar** al final de la línea.
- `o`: Inserta una nueva línea debajo del cursor y entra al Modo Insertar.
- `O`: Inserta una nueva línea encima del cursor y entra al Modo Insertar.

> [!tip] Regla de Oro
> Si no sabes en qué modo estás, presiona `Esc` un par de veces para asegurarte de estar en Modo Normal.

---

## 2. Guardar y Salir (Modo Normal)

Todos estos comandos se ejecutan en Modo Normal y empiezan con `:` (que abre el modo de línea de comandos).

- `:w`: Guardar el archivo (write).
- `:q`: Salir de Vim (quit).
- `:wq` o `:x`: Guardar y salir.
- `:q!`: Salir descartando los cambios (forzar salida).

---

## 3. Movimiento Básico (Modo Normal)

Aunque puedes usar las flechas, lo ideal en Vim es usar estas teclas para no mover las manos de la posición base:

- `h`: Izquierda
- `j`: Abajo
- `k`: Arriba
- `l`: Derecha

**Movimientos más rápidos:**
- `w`: Salta al inicio de la siguiente palabra.
- `b`: Salta al inicio de la palabra anterior.
- `0` (cero): Salta al principio de la línea.
- `$`: Salta al final de la línea.
- `gg`: Va al principio del archivo.
- `G`: Va al final del archivo.
- `:<número>`: Va a la línea especificada (ej. `:45` va a la línea 45).

---

## 4. Edición de Texto (Modo Normal)

- `x`: Borra el carácter bajo el cursor (como Suprimir).
- `dd`: Borra (corta) la línea entera.
- `dw`: Borra desde el cursor hasta el final de la palabra.
- `D`: Borra desde el cursor hasta el final de la línea.
- `yy`: Copia (yank) la línea entera.
- `p`: Pega el texto copiado o cortado debajo del cursor.
- `P`: Pega el texto antes del cursor.
- `u`: Deshace el último cambio (undo).
- `Ctrl + r`: Rehace el cambio deshecho (redo).

> [!note] Copiar y Cortar
> En Vim, borrar (`d`, `x`) también actúa como cortar. Lo que borras lo puedes pegar con `p`.

---

## 5. Búsqueda y Reemplazo (Modo Normal)

- `/palabra`: Busca "palabra" hacia adelante en el archivo. Presiona `Enter`.
- `?palabra`: Busca "palabra" hacia atrás en el archivo.
- `n`: Va a la siguiente coincidencia de la búsqueda.
- `N`: Va a la coincidencia anterior.
- `:%s/viejo/nuevo/g`: Reemplaza todas las apariciones de "viejo" por "nuevo" en todo el archivo.

---

## Resumen Rápido para Supervivencia

Si solo vas a recordar 4 cosas para editar configuraciones rápido en la VM:

1. Presiona `i` para empezar a escribir.
2. Escribe lo que necesites.
3. Presiona `Esc` para salir de la escritura.
4. Escribe `:wq` y dale a `Enter` para guardar y salir.