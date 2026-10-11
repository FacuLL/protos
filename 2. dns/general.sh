# Borrar si existen
rm /etc/named.caching-server.conf
rm /var/named/chroot/etc/named.caching-server.conf

# Instalar bind
sudo apt install bind9 bind9utils bind9-doc dnsutils -y

# Configuracion de zona
sudo nano /etc/bind/named.conf.local
sudo nano /etc/bind/db.foo.pdc.lab
sudo nano /etc/bind/db.192.168.1

# Validar la configuración general
sudo named-checkconf

# Validar cada zona creada
sudo named-checkzone foo.pdc.lab /etc/bind/db.foo.pdc.lab
sudo named-checkzone 1.168.192.in-addr.arpa /etc/bind/db.192.168.1

# Reiniciar el servicio
sudo systemctl restart bind9

# Inpeccionar logs
sudo journalctl -u bind9 -n 50 --no-pager

# Probar con dig
dig @127.0.0.1 web.foo.pdc.lab
dig @127.0.0.1 foo.pdc.lab SOA
dig @127.0.0.1 -x 192.168.1.11

# Probar con host
host host1.foo.pdc.lab 127.0.0.1
host web.foo.pdc.lab 127.0.0.1
host 192.168.1.11 127.0.0.1

# Probar con nslookup
nslookup web.foo.pdc.lab 127.0.0.1
nslookup 192.168.1.11 127.0.0.1

# Establecer nuestro DNS como el principal en la interfaz de red
sudo nano /etc/resolv.conf
# O si lo queremos permanente, en /etc/netplan/01-netcfg.yaml (o el que corresponda) y luego sudo netplan apply

# Editar forwarders
sudo nano /etc/bind/named.conf.options
sudo systemctl restart bind9

# Limpiar cache de bind
sudo rndc flush
