from fastapi import FastAPI, HTTPException
from database import database, attendance_listener
from models import Attendance, AttendancePercentage, Employee, EmployeeDashboard
from typing import List
import asyncio

# Initialize FastAPI application
app = FastAPI(title="Employee Attendance API")


@app.on_event("startup")
async def startup():
    # Connect to database on startup
    await database.connect()

    # Start background listener for attendance updates
    asyncio.create_task(attendance_listener())


@app.on_event("shutdown")
async def shutdown():
    # Disconnect database on shutdown
    await database.disconnect()


@app.get("/attendance/{emp_id}", response_model=AttendancePercentage)
async def get_attendance_percentage(emp_id: int):
    query = """
    SELECT attendance_percentage(:emp_id) AS percentage;
    """

    result = await database.fetch_one(query=query, values={"emp_id": emp_id})

    if result is None or result["percentage"] is None:
        raise HTTPException(
            status_code=404,
            detail="Employee not found or no attendance"
        )

    return {"emp_id": emp_id, "percentage": result["percentage"]}


@app.get("/attendances", response_model=List[Attendance])
async def list_attendances():
    query = "SELECT emp_id, is_present, date FROM attendances ORDER BY date, emp_id;"
    rows = await database.fetch_all(query=query)
    return rows

@app.get("/users", response_model=List[Employee])
async def list_employees():
    query = "SELECT * from employee"
    rows = await database.fetch_all(query=query)
    return rows

@app.get("/users/{id}", response_model=Employee)
async def get_employee(id: int):
    query = "SELECT * from employee e where e.id=(:emp_id)"
    rows = await database.fetch_one(query=query, values={"emp_id": id})
    return rows

@app.patch("/attendance/{att_id}", response_model=Attendance)
async def update_is_present_true(att_id: int):
    query = "update attendances a set is_present = true where a.id=:att_id RETURNING emp_id, is_present, date, updated_at"
    rows = await database.fetch_one(query=query, values={"att_id": att_id})
    if rows is None:
        raise HTTPException(status_code=404, detail="Attendance record not found")
    return rows

@app.get("/dashboard", response_model=List[EmployeeDashboard])
async def list_employees_dashboard():
    query = "SELECT * from employee_dashboard"
    rows = await database.fetch_all(query=query)
    return rows

