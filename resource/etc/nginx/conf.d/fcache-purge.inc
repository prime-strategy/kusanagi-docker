       location ~ /fcache-purge/([^/]+)(/.*) {
               allow 127.0.0.1;
               deny all;
               fastcgi_cache_purge wpcache "$1:GET:$scheme://$host$2";
       }
