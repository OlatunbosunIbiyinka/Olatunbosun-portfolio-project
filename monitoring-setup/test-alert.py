import requests
import datetime
import json

#  Correct v2 API endpoint
ALERTMANAGER_URL = "http://localhost:9093/api/v2/alerts"

# Create a simple test alert
alert = [{
    "labels": {
        "alertname": "EmailTestAlert",
        "severity": "critical"
    },
    "annotations": {
        "summary": "This is a test alert to verify email delivery",
        "description": "If you see this email, Gmail alerting works!"
    },
    "startsAt": datetime.datetime.utcnow().isoformat() + "Z",
    "endsAt": (datetime.datetime.utcnow() + datetime.timedelta(minutes=5)).isoformat() + "Z"
}]

# Send alert to Alertmanager
response = requests.post(ALERTMANAGER_URL, data=json.dumps(alert), headers={"Content-Type": "application/json"})

if response.status_code == 200:
    print(" Test alert sent successfully to Alertmanager v2 API.")
else:
    print(f" Failed to send alert ({response.status_code}): {response.text}")
