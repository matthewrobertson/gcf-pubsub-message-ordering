
def hello(event, context):
    print(f"Received event with ID: {context.event_id} and data {event}")
    return "OK"
