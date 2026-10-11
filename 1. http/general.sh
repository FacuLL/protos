# Instalacion
sudo apt install nginx

# Check de que esta corriendo (daemon)
systemctl status nginx

# Check de que esta escuchando puertos (sockets abiertos)
sudo apt install net-tools
netstat -l -t   # -l para ver solo listening, pasivos. -t para ver solo tcp
# otros flags: -n no resuelve dominios. -p muestra pids

# Config padre
nano /etc/nginx/nginx.conf
# Se importan los conf de /sites-enabled que direcciona a /sites-available. Archivo default "default". Puedo borrarlo y crear otro.
# En ese default se sirven los archivos de /var/www/html.
rm /etc/nginx/sites-enabled/default

# Ej 36 (foo, bar, what): Creamos las configs
nano /etc/nginx/sites-available/foo
nano /var/www/html/foo/index.html
ln -s /etc/nginx/sites-available/foo /etc/nginx/sites-enabled/foo

nano /etc/nginx/sites-available/bar
nano /var/www/html/bar/index.html
ln -s /etc/nginx/sites-available/bar /etc/nginx/sites-enabled/bar

nano /etc/nginx/sites-available/what
nano /var/www/html/what/index.html
ln -s /etc/nginx/sites-available/what /etc/nginx/sites-enabled/what

# Verificamos syntaxis
sudo nginx -t

# Restart config
# NO USAMOS systemctl restart nginx PUES MATA LAS CONEXIONES
nginx -s reload # O BIEN service nginx reload O BIEN systemctl reload nginx

# Probar
curl localhost -v # -v muestra los headers enviados y recibidos
curl localhost -H "Host: foo" -v
curl localhost -H "Host: bar" -v
curl localhost -H "Host: dhaisdnq" -v

# Si no puedo setear headers a mano, necesito cambiar los hosts
nano /etc/hosts