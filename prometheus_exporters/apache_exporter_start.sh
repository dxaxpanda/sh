
#!/bin/sh

su -m nobody -c "nohup /usr/local/bin/apache_exporter -telemetry.address "10.1.0.2:9117" >> apache_exporter.log 2>&1 &"
