# `trombik.icingaweb2`

`ansible` role to manage `icingaweb2`.

# Requirements

* [trombik.x509_certificate](https://github.com/trombik/ansible-role-x509_certificate)
  if you need API

# Role Variables

| variable | description | default |
|----------|-------------|---------|


# Dependencies

None

# Example Playbook

```yaml
---
- hosts: localhost
  roles:
    - role: trombik.postgresql
    - role: trombik.cfssl
    - role: trombik.icinga2
    - role: trombik.php_fpm
    - role: trombik.nginx
    - ansible-role-icingaweb2
  vars:
    # an example to create icinga2 server, icingaweb2, postgresql server, and
    # web application sevrers on a single host.
    #
    # XXX in this example, icinga2_database_user and
    # icingaweb2_database_login_user are created by `trombik.postgresql`.
    # these variables are not available when the role is being executed. thus,
    # define `project_*` variables so that the role can create users.
    project_db_host: 127.0.0.1
    project_db_port: 5432
    project_db_name: icingaweb
    project_db_user: icingaweb
    project_db_password: password

    icingaweb2_database_host: "{{ project_db_host }}"
    icingaweb2_database_port: "{{ project_db_port }}"
    icingaweb2_database_name: "{{ project_db_name }}"
    icingaweb2_database_login_host: "{{ project_db_host }}"
    icingaweb2_database_login_user: "{{ project_db_user }}"
    icingaweb2_database_login_password: "{{ project_db_password }}"

    project_db_ido_host: "{{ project_db_host }}"
    project_db_ido_port: "{{ project_db_port }}"
    project_db_ido_name: icinga_ido
    project_db_ido_user: icinga_ido
    project_db_ido_password: password

    icinga2_database_login_password: "{{ project_db_ido_password }}"
    icinga2_database_name: "{{ project_db_ido_name }}"
    icinga2_database_user: "{{ project_db_ido_user }}"
    icinga2_database_password: "{{ project_db_ido_password }}"

    project_api_user: root
    project_api_password: 0660d951f4a29e8b

    icingaweb2_default_admin_password: password
    icingaweb2_modules:
      - name: monitoring
        state: enabled
      - name: setup
        state: disabled

    icingaweb2_extra_packages:
      - jq
    icingaweb2_conf_files:
      - name: config.ini
        content: |
          [global]
          show_stacktraces = "1"
          show_application_state_messages = "1"
          config_backend = "db"
          config_resource = "icingaweb_db"

          [logging]
          log = "syslog"
          level = "ERROR"
          application = "icingaweb2"
          facility = "user"

      - name: authentication.ini
        content: |
          [icingaweb2]
          backend = "db"
          resource = "icingaweb_db"

      - name: groups.ini
        content: |
          [icingaweb2]
          backend = "db"
          resource = "icingaweb_db"

      - name: resources.ini
        content: |
          [icingaweb_db]
          type = "db"
          db = "pgsql"
          host = "{{ icingaweb2_database_host }}"
          port = "{{ icingaweb2_database_port }}"
          dbname = "{{ icingaweb2_database_name }}"
          username = "{{ icingaweb2_database_user }}"
          password = "{{ icingaweb2_database_password }}"
          charset = ""
          use_ssl = "0"

          [icinga_ido]
          type = "db"
          db = "pgsql"
          host = "{{ project_db_ido_host }}"
          port = "{{ project_db_ido_port }}"
          dbname = "{{ project_db_ido_name }}"
          username = "{{ project_db_ido_user }}"
          password = "{{ project_db_ido_password }}"
          charset = ""
          use_ssl = "0"
      - name: roles.ini
        content: |
          [Administrators]
          users = "{{ icingaweb2_default_admin_name }} "
          permissions = "*"
          groups = "Administrators"

      - name: modules/monitoring/backends.ini
        content: |
          [icinga]
          type = "ido"
          resource = "icinga_ido"

      - name: modules/monitoring/commandtransports.ini
        content: |
          [API]
          transport = "api"
          host = "localhost"
          port = "5665"
          username = "root"
          password = "0660d951f4a29e8b"

      - name: modules/monitoring/config.ini
        content: |
          [security]
          protected_customvars = "*pw*,*pass*,community"
    # ________________________________postgresql
    postgresql_initial_password: password
    postgresql_debug: yes
    postgresql_pg_hba_config: |
      host    all             all             127.0.0.1/32            {{ postgresql_default_auth_method }}
      host    all             all             ::1/128                 {{ postgresql_default_auth_method }}
      local   replication     all                                     trust
      host    replication     all             127.0.0.1/32            trust
      host    replication     all             ::1/128                 trust

    postgresql_major_version: 13
    postgresql_db_dir: "/var/db/postgres/data{{ postgresql_major_version }}"
    os_postgresql_package:
      FreeBSD: "databases/postgresql{{ postgresql_major_version }}-server"
    postgresql_package: "{{ os_postgresql_package[ansible_os_family] }}"

    os_postgresql_extra_packages:
      FreeBSD: "databases/postgresql{{ postgresql_major_version }}-client"
    postgresql_extra_packages: "{{ os_postgresql_extra_packages[ansible_os_family] }}"
    postgresql_config: |
      {% if ansible_os_family == 'Debian' %}
      data_directory = '{{ postgresql_db_dir }}'
      hba_file = '{{ postgresql_conf_dir }}/pg_hba.conf'
      ident_file = '{{ postgresql_conf_dir }}/pg_ident.conf'
      external_pid_file = '/var/run/postgresql/{{ postgresql_major_version }}-main.pid'
      max_connections = 100
      unix_socket_directories = '/var/run/postgresql'
      ssl = on
      ssl_cert_file = '/etc/ssl/certs/ssl-cert-snakeoil.pem'
      ssl_key_file = '/etc/ssl/private/ssl-cert-snakeoil.key'
      shared_buffers = 128MB
      dynamic_shared_memory_type = posix
      log_line_prefix = '%m [%p] %q%u@%d '
      log_timezone = 'UTC'
      cluster_name = '{{ postgresql_major_version }}/main'
      stats_temp_directory = '/var/run/postgresql/{{ postgresql_major_version }}-main.pg_stat_tmp'
      datestyle = 'iso, mdy'
      timezone = 'UTC'
      lc_messages = 'C'
      lc_monetary = 'C'
      lc_numeric = 'C'
      lc_time = 'C'
      default_text_search_config = 'pg_catalog.english'
      include_dir = 'conf.d'
      password_encryption = {{ postgresql_default_auth_method }}
      {% else %}
      max_connections = 100
      shared_buffers = 128MB
      dynamic_shared_memory_type = posix
      max_wal_size = 1GB
      min_wal_size = 80MB
      log_destination = 'syslog'
      log_timezone = 'UTC'
      update_process_title = off
      datestyle = 'iso, mdy'
      timezone = 'UTC'
      lc_messages = 'C'
      lc_monetary = 'C'
      lc_numeric = 'C'
      lc_time = 'C'
      default_text_search_config = 'pg_catalog.english'
      password_encryption = {{ postgresql_default_auth_method }}
      {% endif %}
    postgresql_users:
      - name: "{{ project_db_user }}"
        password: "{{ project_db_password }}"
      - name: "{{ project_db_ido_user }}"
        password: "{{ project_db_ido_password }}"

    postgresql_databases:
      - name: "{{ project_db_name }}"
        owner: "{{ project_db_user }}"
        state: present
      - name: "{{ project_db_ido_name }}"
        owner: "{{ project_db_ido_user }}"
        state: present

    project_postgresql_initdb_flags: --encoding=utf-8 --lc-collate=C --locale=en_US.UTF-8
    project_postgresql_initdb_flags_pwfile: "--pwfile={{ postgresql_initial_password_file }}"
    project_postgresql_initdb_flags_auth: "--auth-host={{ postgresql_default_auth_method }} --auth-local={{ postgresql_default_auth_method }}"
    os_postgresql_initdb_flags:
      FreeBSD: "{{ project_postgresql_initdb_flags }} {{ project_postgresql_initdb_flags_pwfile }} {{ project_postgresql_initdb_flags_auth }}"
      OpenBSD: "{{ project_postgresql_initdb_flags }} {{ project_postgresql_initdb_flags_pwfile }} {{ project_postgresql_initdb_flags_auth }}"
      RedHat: "{{ project_postgresql_initdb_flags }} {{ project_postgresql_initdb_flags_pwfile }} {{ project_postgresql_initdb_flags_auth }}"
      # XXX you cannot use --auth-host or --auth-local here because
      # pg_createcluster, which is executed during the installation, overrides
      # them, forcing md5
      Debian: "{{ project_postgresql_initdb_flags }} {{ project_postgresql_initdb_flags_pwfile }}"
    postgresql_initdb_flags: "{{ os_postgresql_initdb_flags[ansible_os_family] }}"

    os_postgresql_flags:
      FreeBSD: |
        postgresql_flags="-w -s -m fast"
      OpenBSD: ""
      Debian: ""
      RedHat: ""
    postgresql_flags: "{{ os_postgresql_flags[ansible_os_family] }}"

    # ________________________________php_fpm
    php_additional_packages_map:
      FreeBSD:
        - "archivers/php{{ php_version_without_dot }}-zip"
        - "textproc/php{{ php_version_without_dot }}-xsl"
      OpenBSD:
        - "php-zip%{{ php_version }}"
        - "php-xsl%{{ php_version }}"
      Debian:
        - "php{{ php_version }}-zip"
        - "php{{ php_version }}-xsl"
    php_additional_packages: "{{ php_additional_packages_map[ansible_os_family] }}"

    php_version: "{% if ansible_distribution == 'Ubuntu' and ansible_distribution_version is version('20.04', '<') %}7.2{% elif ansible_distribution == 'Devuan' %}7.3{% else %}7.4{% endif %}"
    php_ini_config: |
      [PHP]
      engine = On
      short_open_tag = Off
      precision = 14
      output_buffering = 4096
      zlib.output_compression = Off
      implicit_flush = Off
      unserialize_callback_func =
      serialize_precision = -1
      disable_functions =
      disable_classes =
      zend.enable_gc = On
      expose_php = On
      max_execution_time = 30
      max_input_time = 60
      memory_limit = 128M
      error_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT
      display_errors = Off
      display_startup_errors = Off
      log_errors = On
      log_errors_max_len = 1024
      ignore_repeated_errors = Off
      ignore_repeated_source = Off
      report_memleaks = On
      html_errors = On
      variables_order = "GPCS"
      request_order = "GP"
      register_argc_argv = Off
      auto_globals_jit = On
      post_max_size = 8M
      auto_prepend_file =
      auto_append_file =
      default_mimetype = "text/html"
      default_charset = "UTF-8"
      doc_root =
      user_dir =
      enable_dl = Off
      file_uploads = On
      upload_max_filesize = 2M
      max_file_uploads = 20
      allow_url_fopen = On
      allow_url_include = Off
      default_socket_timeout = 60

      [CLI Server]
      cli_server.color = On

    php_fpm_config: |
      [global]
      pid = {{ php_fpm_pid_file }}
      error_log = {{ php_fpm_log_dir }}/php-fpm.log
      include = {{ php_fpm_pool_dir }}/*.conf
    php_fpm_pool_config:
      - name: www
        content: |
          [www]
          user = {{ php_fpm_user }}
          group = {{ php_fpm_group }}
          listen = 127.0.0.1:9000
          pm = dynamic
          pm.max_children = 5
          pm.start_servers = 2
          pm.min_spare_servers = 1
          pm.max_spare_servers = 3
          access.log = {{ php_fpm_log_dir }}/access.log
    # ________________________________nginx
    www_root_dir: "{% if ansible_os_family == 'FreeBSD' %}/usr/local/www/nginx{% elif ansible_os_family == 'OpenBSD' %}/var/www/htdocs{% elif ansible_os_family == 'Debian' %}/var/www/html{% elif ansible_os_family == 'RedHat' %}/usr/share/nginx/html{% endif %}"
    nginx_flags: -q
    nginx_config: |
      {% if ansible_os_family == 'Debian' or ansible_os_family == 'RedHat' %}
      user {{ nginx_user }};
      pid /run/nginx.pid;
      {% endif %}
      worker_processes 1;
      error_log {{ nginx_error_log_file }};
      events {
        worker_connections 1024;
      }
      http {
        include {{ nginx_conf_dir }}/mime.types;
        access_log {{ nginx_access_log_file }};
        default_type application/octet-stream;
        sendfile on;
        keepalive_timeout 65;
        server {
          listen 80;
          server_name localhost;
          root {{ www_root_dir }};
          location / {
            index index.html;
          }
          error_page 500 502 503 504 /50x.html;
          location = /50x.html {
          }
          include {{ nginx_conf_fragments_dir }}/icinga.conf;
        }
      }
    nginx_config_fragments:
      - name: icinga.conf
        state: present
        config: |
          location ~ ^/icingaweb2/index\.php(.*)$ {
            fastcgi_pass 127.0.0.1:9000;
            fastcgi_index index.php;
            include {{ nginx_conf_dir }}/fastcgi_params;
            fastcgi_param SCRIPT_FILENAME /usr/local/www/icingaweb2/public/index.php;
            fastcgi_param ICINGAWEB_CONFIGDIR /usr/local/etc/icingaweb2;
            fastcgi_param REMOTE_USER $remote_user;
          }

          location ~ ^/icingaweb2(.+)? {
            alias /usr/local/www/icingaweb2/public;
            index index.php;
            try_files $1 $uri $uri/ /icingaweb2/index.php$is_args$args;
          }
    nginx_extra_packages_by_os:
      FreeBSD:
        - security/py-certbot-nginx
      OpenBSD: []
      Debian:
        - nginx-extras
      RedHat: []
    nginx_extra_packages: "{{ nginx_extra_packages_by_os[ansible_os_family] }}"
    redhat_repo:
      epel:
        mirrorlist: "http://mirrors.fedoraproject.org/mirrorlist?repo=epel-{{ ansible_distribution_major_version }}&arch={{ ansible_architecture }}"
        gpgcheck: yes
        enabled: yes

    nginx_htpasswd_users:
      - path: /tmp/my_htpasswd
        owner: root
        group: "{{ nginx_group }}"
        create: yes
        mode: "0640"
        name: foo
        password: password
        state: present
      - path: /tmp/another_htpaswd
        group: "{{ nginx_group }}"
        mode: "0640"
        name: bar
        password: password
        state: present
      - path: /tmp/my_htpasswd
        group: "{{ nginx_group }}"
        name: buz
        password: password
        state: present

    # ________________________________icinga2

    icinga2_features:
      - name: checker
      - name: ido-pgsql
      - name: mainlog
      - name: notification
      - name: api

    icinga2_include_role_x509_certificate: yes
    # XXX The ApiListener type expects its certificate files to be in
    # certain locations. see:
    # https://icinga.com/docs/icinga-2/latest/doc/09-object-types/#objecttype-apilistener
    project_root_ca_cert_file: "{{ icinga2_data_dir }}/certs/ca.crt"
    icinga2_x509_certificate_vars:
      x509_certificate_debug_log: yes
      x509_certificate_cfssl_scheme: http
      x509_certificate_cfssl_host: 127.0.0.1
      x509_certificate_cfssl_info:
        - path: "{{ project_root_ca_cert_file }}"
          body:
            label: primary
            profile: default
      x509_certificate_cfssl_certificate_newcert:
        - csr:
            path: "{{ icinga2_data_dir }}/certs/{{ ansible_hostname }}.csr"
            owner: "{{ icinga2_user }}"
            group: "{{ icinga2_group }}"
            mode: "0444"
          public:
            path: "{{ icinga2_data_dir }}/certs/{{ ansible_hostname }}.crt"
            owner: "{{ icinga2_user }}"
            group: "{{ icinga2_group }}"
            mode: "0444"
            notify:
              - Restart icinga2
          private:
            path: "{{ icinga2_data_dir }}/certs/{{ ansible_hostname }}.key"
            owner: "{{ icinga2_user }}"
            group: "{{ icinga2_group }}"
            mode: "0440"
          body:
            profile: backend
            request:
              CN: "{{ ansible_hostname }}"
              hosts:
                - 127.0.0.1
                - localhost
                - ::1
                - "{{ ansible_hostname }}"
                - "{{ ansible_fqdn }}"
              key:
                algo: rsa
                size: 2048
              names:
                - O: example.org

    icinga2_conf_files:
      - name: icinga2.conf
        state: present
        content: |
          /**
           * Icinga 2 configuration file
           * - this is where you define settings for the Icinga application including
           * which hosts/services to check.
           *
           * For an overview of all available configuration options please refer
           * to the documentation that is distributed as part of Icinga 2.
           */

          /**
           * The constants.conf defines global constants.
           */
          include "constants.conf"

          /**
           * The zones.conf defines zones for a cluster setup.
           * Not required for single instance setups.
           */
          include "zones.conf"

          /**
           * The Icinga Template Library (ITL) provides a number of useful templates
           * and command definitions.
           * Common monitoring plugin command definitions are included separately.
           */
          include <itl>
          include <plugins>
          include <plugins-contrib>
          include <manubulon>

          /**
           * This includes the Icinga 2 Windows plugins. These command definitions
           * are required on a master node when a client is used as command endpoint.
           */
          include <windows-plugins>

          /**
           * This includes the NSClient++ check commands. These command definitions
           * are required on a master node when a client is used as command endpoint.
           */
          include <nscp>

          /**
           * The features-available directory contains a number of configuration
           * files for features which can be enabled and disabled using the
           * icinga2 feature enable / icinga2 feature disable CLI commands.
           * These commands work by creating and removing symbolic links in
           * the features-enabled directory.
           */
          include "features-enabled/*.conf"

          /**
           * Although in theory you could define all your objects in this file
           * the preferred way is to create separate directories and files in the conf.d
           * directory. Each of these files must have the file extension ".conf".
           */
          include_recursive "conf.d"
      - name: zones.conf
        content: |
          /*
           * Endpoint and Zone configuration for a cluster setup
           * This local example requires `NodeName` defined in
           * constants.conf.
           */

          object Endpoint NodeName {
            host = NodeName
          }

          object Zone ZoneName {
            endpoints = [ NodeName ]
          }

          /*
           * Defines a global zone for distributed setups with masters,
           * satellites and clients.
           * This is required to sync configuration commands,
           * templates, apply rules, etc. to satellite and clients.
           * All nodes require the same configuration and must
           * have `accept_config` enabled in the `api` feature.
           */

          object Zone "global-templates" {
            global = true
          }

          /*
           * Defines a global zone for the Icinga Director.
           * This is required to sync configuration commands,
           * templates, apply rules, etc. to satellite and clients.
           * All nodes require the same configuration and must
           * have `accept_config` enabled in the `api` feature.
           */

          object Zone "director-global" {
            global = true
          }

          /*
           * Read the documentation on how to configure
           * a cluster setup with multiple zones.
           */

          /*
          object Endpoint "master.example.org" {
            host = "master.example.org"
          }

          object Endpoint "satellite.example.org" {
            host = "satellite.example.org"
          }

          object Zone "master" {
            endpoints = [ "master.example.org" ]
          }

          object Zone "satellite" {
            parent = "master"
            endpoints = [ "satellite.example.org" ]
          }
          */
      - name: constants.conf
        content: |
          /**
           * This file defines global constants which can be used in
           * the other configuration files.
           */

          /* The directory which contains the plugins from the Monitoring Plugins project. */
          const PluginDir = "/usr/local/libexec/nagios"

          /* The directory which contains the Manubulon plugins.
           * Check the documentation, chapter "SNMP Manubulon Plugin Check Commands", for details.
           */
          const ManubulonPluginDir = "/usr/local/libexec/nagios"

          /* The directory which you use to store additional plugins which ITL provides user contributed command definitions for.
           * Check the documentation, chapter "Plugins Contribution", for details.
           */
          const PluginContribDir = "/usr/local/libexec/nagios"

          /* Our local instance name. By default this is the server's hostname as returned by `hostname --fqdn`.
           * This should be the common name from the API certificate.
           */
          const NodeName = "{{ ansible_hostname }}"

          /* Our local zone name. */
          const ZoneName = "{{ ansible_hostname }}"

          /* Secret key for remote node tickets */
          const TicketSalt = ""

      - name: conf.d/api-users.conf
        content: |
          object ApiUser "{{ project_api_user }}" {
            password = "{{ project_api_password }}"
            // client_cn = ""

            permissions = [ "*" ]
          }
      - name: features-available/api.conf
        content: |
          /**
           * The API listener is used for distributed monitoring setups.
           */

          object ApiListener "api" {
            bind_host = "{{ icinga2_api_bind_host }}"
            bind_port = {{ icinga2_api_bind_port }}
            //accept_config = false
            //accept_commands = false

            ticket_salt = TicketSalt
          }
      - name: conf.d/app.conf
        content: |
          object IcingaApplication "app" { }

      - name: conf.d/commands.conf
        content: |
          /* Command objects */

          /* Notification Commands
           *
           * Please check the documentation for all required and
           * optional parameters.
           */

          object NotificationCommand "mail-host-notification" {
            command = [ ConfigDir + "/scripts/mail-host-notification.sh" ]

            arguments += {
              "-4" = "$notification_address$"
              "-6" = "$notification_address6$"
              "-b" = "$notification_author$"
              "-c" = "$notification_comment$"
              "-d" = {
                required = true
                value = "$notification_date$"
              }
              "-f" = {
                value = "$notification_from$"
                description = "Set from address. Requires GNU mailutils (Debian/Ubuntu) or mailx (RHEL/SUSE)"
              }
              "-i" = "$notification_icingaweb2url$"
              "-l" = {
                required = true
                value = "$notification_hostname$"
              }
              "-n" = {
                required = true
                value = "$notification_hostdisplayname$"
              }
              "-o" = {
                required = true
                value = "$notification_hostoutput$"
              }
              "-r" = {
                required = true
                value = "$notification_useremail$"
              }
              "-s" = {
                required = true
                value = "$notification_hoststate$"
              }
              "-t" = {
                required = true
                value = "$notification_type$"
              }
              "-v" = "$notification_logtosyslog$"
            }

            vars += {
              notification_address = "$address$"
              notification_address6 = "$address6$"
              notification_author = "$notification.author$"
              notification_comment = "$notification.comment$"
              notification_type = "$notification.type$"
              notification_date = "$icinga.long_date_time$"
              notification_hostname = "$host.name$"
              notification_hostdisplayname = "$host.display_name$"
              notification_hostoutput = "$host.output$"
              notification_hoststate = "$host.state$"
              notification_useremail = "$user.email$"
            }
          }

          object NotificationCommand "mail-service-notification" {
            command = [ ConfigDir + "/scripts/mail-service-notification.sh" ]

            arguments += {
              "-4" = "$notification_address$"
              "-6" = "$notification_address6$"
              "-b" = "$notification_author$"
              "-c" = "$notification_comment$"
              "-d" = {
                required = true
                value = "$notification_date$"
              }
              "-e" = {
                required = true
                value = "$notification_servicename$"
              }
              "-f" = {
                value = "$notification_from$"
                description = "Set from address. Requires GNU mailutils (Debian/Ubuntu) or mailx (RHEL/SUSE)"
              }
              "-i" = "$notification_icingaweb2url$"
              "-l" = {
                required = true
                value = "$notification_hostname$"
              }
              "-n" = {
                required = true
                value = "$notification_hostdisplayname$"
              }
              "-o" = {
                required = true
                value = "$notification_serviceoutput$"
              }
              "-r" = {
                required = true
                value = "$notification_useremail$"
              }
              "-s" = {
                required = true
                value = "$notification_servicestate$"
              }
              "-t" = {
                required = true
                value = "$notification_type$"
              }
              "-u" = {
                required = true
                value = "$notification_servicedisplayname$"
              }
              "-v" = "$notification_logtosyslog$"
            }

            vars += {
              notification_address = "$address$"
              notification_address6 = "$address6$"
              notification_author = "$notification.author$"
              notification_comment = "$notification.comment$"
              notification_type = "$notification.type$"
              notification_date = "$icinga.long_date_time$"
              notification_hostname = "$host.name$"
              notification_hostdisplayname = "$host.display_name$"
              notification_servicename = "$service.name$"
              notification_serviceoutput = "$service.output$"
              notification_servicestate = "$service.state$"
              notification_useremail = "$user.email$"
              notification_servicedisplayname = "$service.display_name$"
            }
          }

          /*
           * If you prefer to use the notification scripts with environment
           * variables instead of command line parameters, you can use
           * the following commands. They have been updated from < 2.7
           * to support the new notification scripts and should help
           * with an upgrade.
           * Remove the comment blocks and comment the notification commands above.
           */

          /*

          object NotificationCommand "mail-host-notification" {
            command = [ ConfigDir + "/scripts/mail-host-notification.sh" ]

            env = {
              NOTIFICATIONTYPE = "$notification.type$"
              HOSTDISPLAYNAME = "$host.display_name$"
              HOSTNAME = "$host.name$"
              HOSTADDRESS = "$address$"
              HOSTSTATE = "$host.state$"
              LONGDATETIME = "$icinga.long_date_time$"
              HOSTOUTPUT = "$host.output$"
              NOTIFICATIONAUTHORNAME = "$notification.author$"
              NOTIFICATIONCOMMENT = "$notification.comment$"
              HOSTDISPLAYNAME = "$host.display_name$"
              USEREMAIL = "$user.email$"
            }
          }

          object NotificationCommand "mail-service-notification" {
            command = [ ConfigDir + "/scripts/mail-service-notification.sh" ]

            env = {
              NOTIFICATIONTYPE = "$notification.type$"
              SERVICENAME = "$service.name$"
              HOSTNAME = "$host.name$"
              HOSTDISPLAYNAME = "$host.display_name$"
              HOSTADDRESS = "$address$"
              SERVICESTATE = "$service.state$"
              LONGDATETIME = "$icinga.long_date_time$"
              SERVICEOUTPUT = "$service.output$"
              NOTIFICATIONAUTHORNAME = "$notification.author$"
              NOTIFICATIONCOMMENT = "$notification.comment$"
              HOSTDISPLAYNAME = "$host.display_name$"
              SERVICEDISPLAYNAME = "$service.display_name$"
              USEREMAIL = "$user.email$"
            }
          }

          */

      - name: conf.d/downtimes.conf
        content: |
          /**
           * The example downtime apply rule.
           */

          apply ScheduledDowntime "backup-downtime" to Service {
            author = "icingaadmin"
            comment = "Scheduled downtime for backup"

            ranges = {
              monday = service.vars.backup_downtime
              tuesday = service.vars.backup_downtime
              wednesday = service.vars.backup_downtime
              thursday = service.vars.backup_downtime
              friday = service.vars.backup_downtime
              saturday = service.vars.backup_downtime
              sunday = service.vars.backup_downtime
            }

            assign where service.vars.backup_downtime != ""
          }

      - name: conf.d/groups.conf
        content: |
          /**
           * Host group examples.
           */

          object HostGroup "FreeBSD-servers" {
            display_name = "FreeBSD Servers"

            assign where host.vars.os == "FreeBSD"
          }

          object HostGroup "windows-servers" {
            display_name = "Windows Servers"

            assign where host.vars.os == "Windows"
          }

          /**
           * Service group examples.
           */

          object ServiceGroup "ping" {
            display_name = "Ping Checks"

            assign where match("ping*", service.name)
          }

          object ServiceGroup "http" {
            display_name = "HTTP Checks"

            assign where match("http*", service.check_command)
          }

          object ServiceGroup "disk" {
            display_name = "Disk Checks"

            assign where match("disk*", service.check_command)
          }

      - name: conf.d/hosts.conf
        content: |
          /*
           * Host definitions with object attributes
           * used for apply rules for Service, Notification,
           * Dependency and ScheduledDowntime objects.
           *
           * Tip: Use `icinga2 object list --type Host` to
           * list all host objects after running
           * configuration validation (`icinga2 daemon -C`).
           */

          /*
           * This is an example host based on your
           * local host's FQDN. Specify the NodeName
           * constant in `constants.conf` or use your
           * own description, e.g. "db-host-1".
           */

          object Host NodeName {
            /* Import the default host template defined in `templates.conf`. */
            import "generic-host"

            /* Specify the address attributes for checks e.g. `ssh` or `http`. */
            address = "127.0.0.1"
            address6 = "::1"

            /* Set custom variable `os` for hostgroup assignment in `groups.conf`. */
            vars.os = "FreeBSD"

            /* Define http vhost attributes for service apply rules in `services.conf`. */
            vars.http_vhosts["http"] = {
              http_uri = "/"
            }
            /* Uncomment if you've sucessfully installed Icinga Web 2. */
            //vars.http_vhosts["Icinga Web 2"] = {
            //  http_uri = "/icingaweb2"
            //}

            /* Define disks and attributes for service apply rules in `services.conf`. */
            vars.disks["disk"] = {
              /* No parameters. */
            }
            vars.disks["disk /"] = {
              disk_partitions = "/"
            }

            /* Define notification mail attributes for notification apply rules in `notifications.conf`. */
            vars.notification["mail"] = {
              /* The UserGroup `icingaadmins` is defined in `users.conf`. */
              groups = [ "icingaadmins" ]
            }
          }

          object Host "Google DNS" {
            import "generic-host"
            address = "8.8.8.8"
            vars.dns_services["google.com"] = {
              dig_lookup = "google.com"
            }
          }
      - name: conf.d/notifications.conf
        content: |
          /**
           * The example notification apply rules.
           *
           * Only applied if host/service objects have
           * the custom variable `notification` defined
           * and containing `mail` as key.
           *
           * Check `hosts.conf` for an example.
           */

          apply Notification "mail-icingaadmin" to Host {
            import "mail-host-notification"
            user_groups = host.vars.notification.mail.groups
            users = host.vars.notification.mail.users

            //interval = 2h

            //vars.notification_logtosyslog = true

            assign where host.vars.notification.mail
          }

          apply Notification "mail-icingaadmin" to Service {
            import "mail-service-notification"
            user_groups = host.vars.notification.mail.groups
            users = host.vars.notification.mail.users

            //interval = 2h

            //vars.notification_logtosyslog = true

            assign where host.vars.notification.mail
          }

      - name: conf.d/services.conf
        content: |
          /*
           * Service apply rules.
           *
           * The CheckCommand objects `ping4`, `ping6`, etc
           * are provided by the plugin check command templates.
           * Check the documentation for details.
           *
           * Tip: Use `icinga2 object list --type Service` to
           * list all service objects after running
           * configuration validation (`icinga2 daemon -C`).
           */

          /*
           * This is an example host based on your
           * local host's FQDN. Specify the NodeName
           * constant in `constants.conf` or use your
           * own description, e.g. "db-host-1".
           */

          /*
           * These are generic `ping4` and `ping6`
           * checks applied to all hosts having the
           * `address` resp. `address6` attribute
           * defined.
           */
          apply Service "ping4" {
            import "generic-service"

            check_command = "ping4"

            assign where host.address
          }

          apply Service "ping6" {
            import "generic-service"

            check_command = "ping6"

            assign where host.address6
          }

          /*
           * Apply the `ssh` service to all hosts
           * with the `address` attribute defined and
           * the custom variable `os` set to `FreeBSD`.
           */
          apply Service "ssh" {
            import "generic-service"

            check_command = "ssh"

            assign where (host.address || host.address6) && host.vars.os == "FreeBSD"
          }

          apply Service for (http_vhost => config in host.vars.http_vhosts) {
            import "generic-service"

            check_command = "http"

            vars += config
          }

          apply Service for (disk => config in host.vars.disks) {
            import "generic-service"

            check_command = "disk"

            vars += config
          }

          apply Service "icinga" {
            import "generic-service"

            check_command = "icinga"

            assign where host.name == NodeName
          }

          apply Service "load" {
            import "generic-service"

            check_command = "load"

            /* Used by the ScheduledDowntime apply rule in `downtimes.conf`. */
            vars.backup_downtime = "02:00-03:00"

            assign where host.name == NodeName
          }

          apply Service "procs" {
            import "generic-service"

            check_command = "procs"

            assign where host.name == NodeName
          }

          apply Service "swap" {
            import "generic-service"

            check_command = "swap"

            assign where host.name == NodeName
          }

          apply Service "users" {
            import "generic-service"

            check_command = "users"

            assign where host.name == NodeName
          }

          apply Service "dig" for (dns_service => config in host.vars.dns_services) {
            import "generic-service"
            check_command = "dig"
            vars += config
          }

      - name: conf.d/templates.conf
        content: |
          /*
           * Generic template examples.
           */


          /**
           * Provides default settings for hosts. By convention
           * all hosts should import this template.
           *
           * The CheckCommand object `hostalive` is provided by
           * the plugin check command templates.
           * Check the documentation for details.
           */
          template Host "generic-host" {
            max_check_attempts = 3
            check_interval = 1m
            retry_interval = 30s

            check_command = "hostalive"
          }

          /**
           * Provides default settings for services. By convention
           * all services should import this template.
           */
          template Service "generic-service" {
            max_check_attempts = 5
            check_interval = 1m
            retry_interval = 30s
          }

          /**
           * Provides default settings for users. By convention
           * all users should inherit from this template.
           */

          template User "generic-user" {

          }

          /**
           * Provides default settings for host notifications.
           * By convention all host notifications should import
           * this template.
           */
          template Notification "mail-host-notification" {
            command = "mail-host-notification"

            states = [ Up, Down ]
            types = [ Problem, Acknowledgement, Recovery, Custom,
                      FlappingStart, FlappingEnd,
                      DowntimeStart, DowntimeEnd, DowntimeRemoved ]

            vars += {
              // notification_icingaweb2url = "https://www.example.com/icingaweb2"
              // notification_from = "Icinga 2 Host Monitoring <icinga@example.com>"
              notification_logtosyslog = false
            }

            period = "24x7"
          }

          /**
           * Provides default settings for service notifications.
           * By convention all service notifications should import
           * this template.
           */
          template Notification "mail-service-notification" {
            command = "mail-service-notification"

            states = [ OK, Warning, Critical, Unknown ]
            types = [ Problem, Acknowledgement, Recovery, Custom,
                      FlappingStart, FlappingEnd,
                      DowntimeStart, DowntimeEnd, DowntimeRemoved ]

            vars += {
              // notification_icingaweb2url = "https://www.example.com/icingaweb2"
              // notification_from = "Icinga 2 Service Monitoring <icinga@example.com>"
              notification_logtosyslog = false
            }

            period = "24x7"
          }

      - name: conf.d/timeperiods.conf
        content: |
          /**
           * Sample timeperiods for Icinga 2.
           * Check the documentation for details.
           */

          object TimePeriod "24x7" {
            display_name = "Icinga 2 24x7 TimePeriod"
            ranges = {
              "monday" 	= "00:00-24:00"
              "tuesday" 	= "00:00-24:00"
              "wednesday" = "00:00-24:00"
              "thursday" 	= "00:00-24:00"
              "friday" 	= "00:00-24:00"
              "saturday" 	= "00:00-24:00"
              "sunday" 	= "00:00-24:00"
            }
          }

          object TimePeriod "9to5" {
            display_name = "Icinga 2 9to5 TimePeriod"
            ranges = {
              "monday" 	= "09:00-17:00"
              "tuesday" 	= "09:00-17:00"
              "wednesday" = "09:00-17:00"
              "thursday" 	= "09:00-17:00"
              "friday" 	= "09:00-17:00"
            }
          }

          object TimePeriod "never" {
            display_name = "Icinga 2 never TimePeriod"
            ranges = {
            }
          }
      - name: conf.d/users.conf
        content: |
          /**
           * The example user 'icingaadmin' and the example
           * group 'icingaadmins'.
           */

          object User "icingaadmin" {
            import "generic-user"

            display_name = "Icinga 2 Admin"
            groups = [ "icingaadmins" ]

            email = "icinga@localhost"
          }

          object UserGroup "icingaadmins" {
            display_name = "Icinga 2 Admin Group"
          }

      - name: features-available/checker.conf
        content: |
          /**
           * The checker component takes care of executing service checks.
           */

          object CheckerComponent "checker" { }

      - name: features-available/ido-pgsql.conf
        content: |
          /**
           * The IdoPgsqlConnection type implements PostgreSQL support
           * for DB IDO.
           */

          object IdoPgsqlConnection "ido-pgsql" {
            user = "{{ icinga2_database_user }} "
            password = "{{ icinga2_database_password }}"
            host = "{{ icinga2_database_login_host }}"
            database = "{{ icinga2_database_name }}"
          }

      - name: features-available/mainlog.conf
        content: |
          /**
           * The FileLogger type writes log information to a file.
           */

          object FileLogger "main-log" {
            severity = "information"
            path = LogDir + "/icinga2.log"
          }

      - name: features-available/notification.conf
        state: present
        content: |
          /**
           * The notification component is responsible for sending notifications.
           */

          object NotificationComponent "notification" { }
    # _____________________________________________cfssl
    cfssl_db_migration_environment: production
    cfssl_db_migration_config:
      production:
        driver: sqlite3
        open: "{{ cfssl_db_sqlite_database_file }}"

    cfssl_db_type: sqlite
    os_cfssl_extra_packages:
      FreeBSD: sqlite3
    cfssl_extra_packages: "{{ os_cfssl_extra_packages[ansible_os_family] }}"
    project_auth_key: 0123456789ABCDEF0123456789ABCDEF
    project_auth_key_name: primary

    # this test case follows the same steps described at
    # https://docs.sensu.io/sensu-go/latest/guides/generate-certificates/
    cfssl_ca_config:
      auth_keys:
        primary:
          type: standard
          key: "{{ project_auth_key }}"
      signing:
        default:
          expiry: 17520h
          usages:
            - signing
            - key encipherment
            - client auth
          auth_key: "{{ project_auth_key_name }}"
        profiles:
          backend:
            expiry: 4320h
            usages:
              - signing
              - key encipherment
              - server auth
              - client auth
            auth_key: "{{ project_auth_key_name }}"
          agent:
            expiry: 4320h
            usages:
              - signing
              - key encipherment
              - client auth
            auth_key: "{{ project_auth_key_name }}"

    # see https://github.com/cloudflare/cfssl/tree/master/certdb/README.md
    cfssl_db_config:
      driver: sqlite3
      data_source: "{{ cfssl_db_sqlite_database_file }}"

    cfssl_ca_csr_config:
      CN: Test CA
      key:
        algo: rsa
        size: 2048
    os_cfssl_flags:
      FreeBSD: |

        cfssl_flags="-db-config {{ cfssl_ca_root_dir }}/db.json -ca {{ cfssl_ca_root_dir }}/ca.pem -ca-key {{ cfssl_ca_root_dir }}/ca-key.pem -config {{ cfssl_ca_config_file }} -address 127.0.0.1"
      Debian: ""
    cfssl_flags: "{{ os_cfssl_flags[ansible_os_family] }}"
    # "
```

# License

```
Copyright (c) 2021 Tomoyuki Sakurai <y@trombik.org>

Permission to use, copy, modify, and distribute this software for any
purpose with or without fee is hereby granted, provided that the above
copyright notice and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
```

# Author Information

Tomoyuki Sakurai <y@trombik.org>

This README was created by [qansible](https://github.com/trombik/qansible)
