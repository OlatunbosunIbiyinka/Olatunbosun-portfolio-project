import os
from datetime import datetime, timedelta, timezone
import requests

# Use env var with fallback to local Alertmanager
ALERTMANAGER_URL = os.getenv("ALERTMANAGER_URL", "http://localhost:9093/api/v2/alerts")

# Build timestamps once for consistency
now = datetime.now(timezone.utc)
starts_at = now.isoformat()                       # e.g. "2025-10-23T14:14:47.519845+00:00"
ends_at = (now + timedelta(minutes=5)).isoformat()

alert = [{
    "labels": {
        "alertname": "EmailTestAlert",
        "severity": "critical",
    },
    "annotations": {
        "summary": "This is a test alert to verify email delivery",
        "description": "If you see this email, Gmail alerting works!"
    },
    "startsAt": starts_at,
    "endsAt": ends_at,
}]

try:
    # Use json= so requests handles serialization and content-type
    response = requests.post(ALERTMANAGER_URL, json=alert, timeout=5)
    response.raise_for_status()  # raise HTTPError for bad responses (4xx/5xx)
except requests.RequestException as e:
    print("Failed to send alert:", e)
else:
    print("Test alert sent successfully to Alertmanager v2 API.")
    # If you want to debug the server response:
    # print(response.status_code, response.text)
