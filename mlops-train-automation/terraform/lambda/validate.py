def handler(event, context):
    print("Validating data...")
    print(f"Received input: {event}")

    return {
        "status": "validated",
        "source": event.get("source", "unknown"),
        "commit": event.get("commit", "unknown"),
    }
