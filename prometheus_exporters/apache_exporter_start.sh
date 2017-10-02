

#!/bin/sh

su -m nobody -c "touch apache_exporter.log"
su -m nobody -c "nohup /usr/local/bin/apache_exporter -scrape_uri 'http://localhost/server-status?auto' -telemetry.address '10.1.0.2:9117' >> apache_exporter.log 2>&1 &"

