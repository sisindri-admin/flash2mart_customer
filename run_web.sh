#!/bin/bash
flutter run -d web-server --web-port=8080 &
sleep 3
google-chrome http://localhost:8080 --no-sandbox &
