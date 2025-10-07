import psycopg2

host = "34.100.194.2"       
port = "5432"             
user = "postgres"    
password = "Pointers#123"

try:
    # Connect to PostgreSQL
    conn = psycopg2.connect(
        host=host,
        port=port,
        user=user,
        password=password,
        dbname="postgres"  # connect to default 'postgres' database
    )
    conn.autocommit = True  # needed for some queries like listing databases

    # Create a cursor object
    cur = conn.cursor()

    # Execute query to list all databases
    cur.execute("SELECT datname FROM pg_database WHERE datistemplate = false;")
    
    # Fetch all results
    databases = cur.fetchall()
    
    print("Databases on this server:")
    for db in databases:
        print(db[0])

    # Close cursor and connection
    cur.close()
    conn.close()

except Exception as e:
    print("Error connecting to PostgreSQL:", e)
