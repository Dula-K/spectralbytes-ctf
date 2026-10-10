"""
Formatting helper for collector.py. root:telemetry, mode 664, so anyone in
the telemetry group can edit it — and whatever's in here runs as root on
the next collection cycle.
"""


def format_reading(reading: dict) -> str:
    return f"[telemetry] sensor={reading.get('sensor')} status={reading.get('status')}"
