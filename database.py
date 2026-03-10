from databases import Database
import asyncpg
import asyncio

DATABASE_URL = "postgresql://postgres:password@localhost:5432/ksystem"
database = Database(DATABASE_URL)

# Function to listen to postgres notifications
async def attendance_listener():
    conn = await asyncpg.connect(DATABASE_URL)
    async def callback(conn, pid, channel, payload):
        print(f"Noti on '{channel}': '{payload}")

    await conn.add_listener('attendance_change', callback)
    print("Listening for notifications...")
    while True:
        await asyncio.sleep(60)