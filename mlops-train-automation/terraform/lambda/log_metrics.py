def handler(event, context):
    print("Logging metrics...")
    print(f"Received input: {event}")

    return {
        "status": "logged",
        "validation_status": event.get("status", "unknown"),
        "source": event.get("source", "unknown"),
        "commit": event.get("commit", "unknown"),
    }
