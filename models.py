from pydantic import BaseModel
from datetime import date, datetime

class Attendance(BaseModel):
    emp_id: int
    is_present: bool
    date: date

class AttendancePercentage(BaseModel):
    emp_id: int
    percentage: float

class Employee(BaseModel):
    id: int
    name: str
    email: str
    created_at: datetime
    role_id: int
    dob: date | None

class EmployeeDashboard(BaseModel):
    id: int
    employee: str
    role: str
    attendance_percentage: float

