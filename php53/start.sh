#!/bin/bash
fpmFile="/etc/php5/fpm/pool.d/www.conf"
iniFile="/etc/php5/fpm/php.ini"
env | sed "s/\(.*\)=\(.*\)/env[\1]='\2'/" >> $fpmFile

sed -i -e "s/^.*mailhub=.*$/mailhub=$SMTP_SERVER/" /etc/ssmtp/ssmtp.conf

## global settings
if [ -n "${PHP53_cookie_lifetime}" ]; then
    sed -i -e "s/.*session.cookie_lifetime =.*/session.cookie_lifetime = $PHP53_cookie_lifetime/" $iniFile
else
    sed -i -e "s/.*session.cookie_lifetime =.*/session.cookie_lifetime = 315360000/" $iniFile
fi

if [ -n "${PHP53_memory_limit}" ]; then
    sed -i -e "s/.*memory_limit =.*/memory_limit = $PHP53_memory_limit/" $iniFile
else
    sed -i -e "s/.*memory_limit =.*/memory_limit = 1024M/" $iniFile
fi

if [ -n "${PHP53_post_max_size}" ]; then
    sed -i -e "s/.*post_max_size =.*/post_max_size = $PHP53_post_max_size/" $iniFile  
else
    sed -i -e "s/.*post_max_size =.*/post_max_size = 128M/" $iniFile  
fi

if [ -n "${PHP53_max_input_vars}" ]; then
    sed -i -e "s/.*max_input_vars =.*/max_input_vars = $PHP53_max_input_vars/" $iniFile  
else
    sed -i -e "s/.*max_input_vars =.*/max_input_vars = 1000/" $iniFile  
fi

if [ -n "${PHP53_error_reporting}" ]; then
    sed -i -e "s/.*error_reporting =.*/error_reporting = $PHP53_error_reporting/" $iniFile  
else
    sed -i -e "s/.*error_reporting =.*/error_reporting = E_ALL \& ~E_DEPRECATED/" $iniFile  
fi

if [ -n "${PHP53_display_errors}" ]; then
    sed -i -e "s/.*display_errors =.*/display_errors = $PHP53_display_errors/" $iniFile  
else
    sed -i -e "s/.*display_errors =.*/display_errors = off/" $iniFile  
fi

if [ -n "${PHP53_upload_max_filesize}" ]; then
    sed -i -e "s/.*upload_max_filesize =.*/upload_max_filesize = $PHP53_upload_max_filesize/" $iniFile  
else
    sed -i -e "s/.*upload_max_filesize =.*/upload_max_filesize = 500M/" $iniFile  
fi

if [ -n "${PHP53_max_execution_time}" ]; then
    sed -i -e "s/.*max_execution_time =.*/max_execution_time = $PHP53_max_execution_time/" $iniFile  
else
    sed -i -e "s/.*max_execuiont_time =.*/max_execution_time = 300/" $iniFile  
fi

if [ -n "${PHP53_default_socket_timeout}" ]; then
    sed -i -e "s/.*default_socket_timeout =.*/default_socket_timeout = $PHP53_default_socket_timeout/" $iniFile  
else
    sed -i -e "s/.*default_socket_timeout =.*/default_socket_timeout = 120/" $iniFile  
fi

if [ -n "${PHP53_date_timezone}" ]; then
    sed -i -e "s/.*date.timezone =.*/date.timezone = $PHP53_date_timezone/" $iniFile
    sed -i -e "s/.*date.timezone =.*/date.timezone = $PHP53_date_timezone/" /etc/php5/cli/php.ini
else
    sed -i -e "s/.*date.timezone =.*/date.timezone = Europe\/London/" $iniFile
    sed -i -e "s/.*date.timezone =.*/date.timezone = Europe\/London/" /etc/php5/cli/php.ini
fi

if [ -n "${PHP53_user}" ]; then
    sed -i -e "s/.*user =.*/user = $PHP53_user/" $fpmFile
else
    sed -i -e "s/.*user =.*/user = nobody/" $fpmFile
fi

if [ -n "${PHP53_group}" ]; then
    sed -i -e "s/.*group =.*/group = $PHP53_group/" $fpmFile
else
    sed -i -e "s/.*group =.*/group = nogroup/" $fpmFile
fi
if [ -n "${PHP53_save_handler}" ]; then
    sed -i -e "s/.*session.save_handler =.*/session.save_handler = $PHP53_save_handler/" $iniFile
    
    ## if it has a load balancing server it needs to save the sessions on both in case the client hits different servers on another request
    if [ -n "${LB_SERVER}" ]; then
        sed -i -e "s/.*session.save_path =.*/session.save_path = tcp:\/\/$MEMCACHED_SERVER:11211?persistent=1&weight=1&timeout=1&retry_interval=15,tcp:\/\/$LB_SERVER:11211?persistent=1&weight=1&timeout=1&retry_interval=15/" $iniFile
    else
        sed -i -e "s/.*session.save_path =.*/session.save_path = tcp:\/\/$MEMCACHED_SERVER:11211?persistent=1&weight=1&timeout=1&retry_interval=15/" $iniFile
    fi
fi

## process manager settings

if [ -n "${PHP5_port}" ]; then
    sed -i -e "s/.*listen =.*/listen = 0.0.0.0:$PHP5_port/" $fpmFile
else
    sed -i -e "s/.*listen =.*/listen = 0.0.0.0:9000/" $fpmFile
fi

if [ -n "${PHP53_pm}" ]; then
    sed -i -e "s/.*pm =.*/pm = $PHP53_pm/" $fpmFile
fi
if [ -n "${PHP53_max_children}" ]; then
    sed -i -e "s/.*pm.max_children =.*/pm.max_children = $PHP53_max_children/" $fpmFile
fi
if [ -n "${PHP53_start_servers}" ]; then
    sed -i -e "s/.*pm.start_servers =.*/pm.start_servers = $PHP53_start_servers/" $fpmFile
fi
if [ -n "${PHP53_min_spare_servers}" ]; then
    sed -i -e "s/.*pm.min_spare_servers =.*/pm.min_spare_servers = $PHP53_min_spare_servers/" $fpmFile
fi
if [ -n "${PHP53_max_spare_servers}" ]; then
    sed -i -e "s/.*pm.max_spare_servers =.*/pm.max_spare_servers = $PHP53_max_spare_servers/" $fpmFile
fi
if [ -n "${PHP53_process_idle_timeout}" ]; then
    sed -i -e "s/.*pm.process_idle_timeout =.*/pm.process_idle_timeout = $PHP53_process_idle_timeout/" $fpmFile
fi

/usr/sbin/php5-fpm -c /etc/php5/fpm