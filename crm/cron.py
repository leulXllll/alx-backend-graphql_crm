from gql import Client, gql
from gql.transport.requests import RequestsHTTPTransport
from datetime import datetime

def log_crm_heartbeat():
    # Set up GraphQL client
    transport = RequestsHTTPTransport(url="http://localhost:8000/graphql")
    client = Client(transport=transport, fetch_schema_from_transport=True)
    
    # Query the hello field
    query = gql("""
        query {
            hello
        }
    """)
    
    # Log heartbeat message
    timestamp = datetime.now().strftime("%d/%m/%Y-%H:%M:%S")
    log_message = f"{timestamp} CRM is alive"
    
    try:
        client.execute(query)
    except Exception as e:
        log_message += f" (GraphQL Error: {str(e)})"
    
    # Append to log file
    with open("/tmp/crm_heartbeat_log.txt", "a") as log_file:
        log_file.write(f"{log_message}\n")