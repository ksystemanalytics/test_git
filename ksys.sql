create table employee(
id serial primary key,
name text not null,
email text unique,
created_at timestamptz default CURRENT_TIMESTAMP(2)
);

create table projects(
id serial primary key,
name text not null,
description text
);

create table role(
id serial primary key,
name text not null,
description text
);


alter table employee
add column role_id int,
add column dob date


alter table employee
add constraint fk_employee_role
foreign key (role_id)
references role(id)
ON UPDATE CASCADE 
ON DELETE SET NULL



INSERT INTO role (name, description) VALUES
('Developer', 'Writes and maintains application code'),
('Manager', 'Manages team members and project delivery'),
('QA Engineer', 'Tests software and ensures quality'),
('DevOps Engineer', 'Maintains infrastructure and deployment pipelines');

INSERT INTO projects (name, description) VALUES
('Inventory System', 'Internal inventory tracking platform'),
('Website Redesign', 'New company website with updated branding'),
('Mobile App', 'Customer-facing mobile application'),
('Analytics Dashboard', 'Internal analytics and reporting tool');


INSERT INTO employee (name, email, role_id) VALUES
('Alice Johnson', 'alice.johnson@company.com', 1),
('Bob Smith', 'bob.smith@company.com', 1),
('Carol Williams', 'carol.williams@company.com', 2),
('David Brown', 'david.brown@company.com', 3),
('Eva Davis', 'eva.davis@company.com', 4),
('Frank Miller', 'frank.miller@company.com', 1);

SELECT
e.id,
e.name AS employee,
r.name AS role
FROM employee e
JOIN role r ON e.role_id = r.id;



create table attendances(
id serial primary key,
emp_id int,
is_present boolean,
date date,
updated_at timestamptz default CURRENT_TIMESTAMP(2)
);


alter table attendances
add constraint fk_attendance_emp_id
foreign key (emp_id)
references employee(id)
ON UPDATE CASCADE


select * from attendances;

insert into attendances (emp_id, is_present, date)
select 
	emp.id as emp_id,
	(random()<0.9) as is_present,
	d.day as date
	from generate_series('2026-02-01'::date, '2026-02-28'::date, '1 day') d(day)
	cross join employee emp;



SELECT e.name AS employee, a.date, a.is_present
FROM attendances a
JOIN employee e ON a.emp_id = e.id
ORDER BY a.date, e.id;



CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN 
	NEW.updated_at=NOW();
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_updated_at
BEFORE UPDATE ON attendances
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

update attendances a set is_present = true where a.id=19;
select * from attendances a;





CREATE OR REPLACE FUNCTION attendance_percentage(user_id int)
RETURNS FLOAT AS $$
declare percentage FLOAT;
BEGIN 
	SELECT SUM(CASE WHEN is_present THEN 1 ELSE 0 END)::FLOAT / COUNT(*) into percentage
FROM attendances
WHERE emp_id = user_id;
RETURN (percentage * 100.0);
END;
$$ LANGUAGE plpgsql;

select  attendance_percentage(6)

select * from attendances a where emp_id = 6 and is_present=true;


create view employee_dashboard as
SELECT
e.id,
e.name AS employee,
r.name AS role,
attendance_percentage(e.id)
FROM employee e
JOIN role r ON e.role_id = r.id;

drop view employee_dashboard

select * from employee_dashboard;




CREATE OR REPLACE FUNCTION notify_attendance_change()
RETURNS TRIGGER AS $$
BEGIN
    PERFORM pg_notify(
        'attendance_change', 
        'Employee ' || NEW.emp_id || ' presence updated to ' || NEW.is_present
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER attendance_notify_trigger
AFTER INSERT OR UPDATE ON attendances
FOR EACH ROW EXECUTE FUNCTION notify_attendance_change();


LISTEN attendance_change;

UPDATE attendances SET is_present = false WHERE id = 24;