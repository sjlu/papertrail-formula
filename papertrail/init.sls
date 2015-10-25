{%- if salt['pillar.get']('papertrail') and salt['pillar.get']('papertrail:port') %}
{%- set port = salt['pillar.get']('papertrail:port') %}
papertrail_certs:
  pkg.installed:
    - name: rsyslog-gnutls
  file.managed:
    - name: /etc/papertrail-bundle.pem
    - source: https://papertrailapp.com/tools/papertrail-bundle.pem
    - source_hash: md5=c75ce425e553e416bde4e412439e3d09
rsyslog:
  file.append:
    - name: /etc/rsyslog.conf
    - text: |
        $DefaultNetstreamDriverCAFile /etc/papertrail-bundle.pem
        $ActionSendStreamDriver gtls
        $ActionSendStreamDriverMode 1
        $ActionSendStreamDriverAuthMode x509/name
        $ActionSendStreamDriverPermittedPeer *.papertrailapp.com
        *.* @logs.papertrailapp.com:{{ port }}
rsyslog-service:
  service:
    - name: rsyslog
    - running
    - restart: True
    - watch:
      - file: /etc/rsyslog.conf
remote_syslog:
  archive:
    - extracted
    - name: /etc/
    - source: https://github.com/papertrail/remote_syslog2/releases/download/v0.14/remote_syslog_linux_amd64.tar.gz
    - source_hash: md5=ebf09fc62ff3dbe42fe431d7430fb955
    - archive_format: tar
    - if_missing: /etc/remote_syslog/
  file.symlink:
    - name: /usr/local/bin/remote_syslog
    - target: /etc/remote_syslog/remote_syslog
remote_syslog-service:
  service:
    - name: remote_syslog
    - running
    - enable: True
    - restart: True
    - watch:
      - file: /etc/log_files.yml
remote_syslog_initd:
  file.managed:
    - name: /etc/init.d/remote_syslog
    - source: https://raw.githubusercontent.com/papertrail/remote_syslog2/eb9b7b7f37b12756ad40242456de22c742fd5f9b/examples/remote_syslog.init.d
    - source_hash: md5=8ebe6a3cf984a1440429aec17e6cd4b5
    - mode: 0755
    - user: root
    - group: root
remote_syslog_config:
  file.append:
    - name: /etc/log_files.yml
    - text: |
        destination:
          host: logs.papertrailapp.com
          port: {{ port }}
          protocol: tls
        files:
          - /logs/**/*
          {%- for log in salt['pillar.get']('papertrail:logs') %}
          - {{ log }}
          {% endfor %}
{%- endif %}
