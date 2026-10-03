DROP DATABASE IF EXISTS blood_bank_db;
CREATE DATABASE blood_bank_db;
USE blood_bank_db;

-- ============================================================
-- 1. TABLE: users
-- Stores login accounts for staff who operate the system
-- ============================================================
CREATE TABLE users (
    user_id     INT PRIMARY KEY AUTO_INCREMENT,
    username    VARCHAR(50)  NOT NULL UNIQUE,
    password    VARCHAR(100) NOT NULL,
    full_name   VARCHAR(100) NOT NULL,
    role        ENUM('Admin','Manager','Staff') NOT NULL DEFAULT 'Staff',
    email       VARCHAR(100) UNIQUE
);

-- ============================================================
-- 2. TABLE: donors
-- Stores donor personal details (age removed, DOB used instead)
-- ============================================================
CREATE TABLE donors (
    donor_id      INT PRIMARY KEY AUTO_INCREMENT,
    name          VARCHAR(100) NOT NULL,
    date_of_birth DATE NOT NULL,
    gender        ENUM('Male','Female','Other') NOT NULL,
    blood_group   ENUM('A+','A-','B+','B-','AB+','AB-','O+','O-') NOT NULL,
    phone         VARCHAR(15) NOT NULL UNIQUE,
    email         VARCHAR(100),
    address       VARCHAR(255)
);

-- ============================================================
-- 3. TABLE: donations
-- Each row = one donation event by one donor (1:N with donors)
-- ============================================================
CREATE TABLE donations (
    donation_id   INT PRIMARY KEY AUTO_INCREMENT,
    donor_id      INT NOT NULL,
    donation_date DATE NOT NULL,
    units_donated INT NOT NULL DEFAULT 1 CHECK (units_donated BETWEEN 1 AND 2),
    FOREIGN KEY (donor_id) REFERENCES donors(donor_id)
);

-- ============================================================
-- 4. TABLE: blood_stock
-- Current inventory per blood group
-- ============================================================
CREATE TABLE blood_stock (
    stock_id        INT PRIMARY KEY AUTO_INCREMENT,
    blood_group     ENUM('A+','A-','B+','B-','AB+','AB-','O+','O-') NOT NULL UNIQUE,
    units_available INT NOT NULL DEFAULT 0 CHECK (units_available >= 0),
    last_updated    TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- ============================================================
-- 5. TABLE: hospitals
-- Hospitals that request blood
-- ============================================================
CREATE TABLE hospitals (
    hospital_id    INT PRIMARY KEY AUTO_INCREMENT,
    hospital_name  VARCHAR(150) NOT NULL,
    contact_person VARCHAR(100),
    phone          VARCHAR(15) NOT NULL,
    email          VARCHAR(100),
    address        VARCHAR(255)
);

-- ============================================================
-- 6. TABLE: blood_requests
-- A hospital's request for blood, logged by a staff user
-- (hospitals -> blood_requests, users -> blood_requests, both 1:N)
-- ============================================================
CREATE TABLE blood_requests (
    request_id     INT PRIMARY KEY AUTO_INCREMENT,
    hospital_id    INT NOT NULL,
    user_id        INT NOT NULL,
    blood_group    ENUM('A+','A-','B+','B-','AB+','AB-','O+','O-') NOT NULL,
    units_required INT NOT NULL CHECK (units_required > 0),
    request_date   DATE NOT NULL DEFAULT (CURRENT_DATE),
    status         ENUM('Pending','Approved','Rejected') NOT NULL DEFAULT 'Pending',
    FOREIGN KEY (hospital_id) REFERENCES hospitals(hospital_id),
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

-- ============================================================
-- 7. TABLE: blood_issues
-- Actual blood handed over against an approved request
-- (blood_requests -> blood_issues, users -> blood_issues, both 1:N)
-- ============================================================
CREATE TABLE blood_issues (
    issue_id      INT PRIMARY KEY AUTO_INCREMENT,
    request_id    INT NOT NULL,
    user_id       INT NOT NULL,
    units_issued  INT NOT NULL CHECK (units_issued > 0),
    issue_date    DATE NOT NULL DEFAULT (CURRENT_DATE),
    FOREIGN KEY (request_id) REFERENCES blood_requests(request_id),
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

-- ============================================================
-- SAMPLE DATA
-- ============================================================

-- ---------- users ----------
INSERT INTO users (username, password, full_name, role, email) VALUES
('admin',    'admin123',  'System Administrator', 'Admin',   'admin@bloodbank.com'),
('manager1', 'manager123','Ravi Verma',           'Manager', 'ravi.verma@bloodbank.com'),
('manager2', 'manager456','Lakshmi Nair',         'Manager', 'lakshmi.nair@bloodbank.com'),
('staff1',   'staff123',  'Anil Kumar',           'Staff',   'anil.kumar@bloodbank.com'),
('staff2',   'staff123',  'Divya Menon',          'Staff',   'divya.menon@bloodbank.com'),
('staff3',   'staff123',  'Karthik Reddy',        'Staff',   'karthik.reddy@bloodbank.com'),
('staff4',   'staff123',  'Meena Iyer',           'Staff',   'meena.iyer@bloodbank.com'),
('staff5',   'staff123',  'Suresh Babu',          'Staff',   'suresh.babu@bloodbank.com');

-- ---------- donors----------
INSERT INTO donors (name, date_of_birth, gender, blood_group, phone, email, address) VALUES
('Rahul Kumar',    '1999-05-14', 'Male',   'O+',  '9876543210', 'rahul.kumar@gmail.com',   'Hyderabad'),
('Sneha Reddy',    '2001-03-22', 'Female', 'A+',  '9876543211', 'sneha.reddy@gmail.com',   'Vijayawada'),
('Arjun Rao',      '1996-11-02', 'Male',   'B+',  '9876543212', 'arjun.rao@gmail.com',     'Guntur'),
('Priya Sharma',   '2000-07-19', 'Female', 'AB+', '9876543213', 'priya.sharma@gmail.com',  'Warangal'),
('Kiran Kumar',    '1994-01-30', 'Male',   'O-',  '9876543214', 'kiran.kumar@gmail.com',   'Hyderabad'),
('Anjali Gupta',   '1998-09-09', 'Female', 'B-',  '9876543215', 'anjali.gupta@gmail.com',  'Secunderabad'),
('Vikram Singh',   '1993-04-12', 'Male',   'A-',  '9876543216', 'vikram.singh@gmail.com',  'Karimnagar'),
('Pooja Desai',    '1999-12-25', 'Female', 'AB-', '9876543217', 'pooja.desai@gmail.com',   'Nizamabad'),
('Manoj Pillai',   '1997-06-18', 'Male',   'O+',  '9876543218', 'manoj.pillai@gmail.com',  'Khammam'),
('Deepa Nair',     '2002-02-14', 'Female', 'A+',  '9876543219', 'deepa.nair@gmail.com',    'Hyderabad'),
('Suresh Yadav',   '1995-08-08', 'Male',   'B+',  '9876543220', 'suresh.yadav@gmail.com',  'Vijayawada'),
('Kavya Reddy',    '2000-10-05', 'Female', 'O+',  '9876543221', 'kavya.reddy@gmail.com',   'Guntur'),
('Ramesh Chandra', '1992-03-17', 'Male',   'AB+', '9876543222', 'ramesh.chandra@gmail.com','Warangal'),
('Neha Verma',     '1998-05-27', 'Female', 'A-',  '9876543223', 'neha.verma@gmail.com',    'Hyderabad'),
('Ajay Mehta',     '1996-07-07', 'Male',   'O-',  '9876543224', 'ajay.mehta@gmail.com',    'Secunderabad'),
('Swati Joshi',    '1999-01-11', 'Female', 'B-',  '9876543225', 'swati.joshi@gmail.com',   'Karimnagar'),
('Rohit Sharma',   '1994-11-23', 'Male',   'A+',  '9876543226', 'rohit.sharma@gmail.com',  'Nizamabad'),
('Divya Rani',     '2001-09-30', 'Female', 'AB+', '9876543227', 'divya.rani@gmail.com',    'Khammam'),
('Sandeep Rao',    '1997-04-04', 'Male',   'B+',  '9876543228', 'sandeep.rao@gmail.com',   'Hyderabad'),
('Meera Iyer',     '2000-06-21', 'Female', 'O+',  '9876543229', 'meera.iyer@gmail.com',    'Vijayawada'),
('Vinay Kumar',    '1993-08-15', 'Male',   'AB-', '9876543230', 'vinay.kumar@gmail.com',   'Guntur'),
('Sunita Rao',     '1998-02-28', 'Female', 'A+',  '9876543231', 'sunita.rao@gmail.com',    'Warangal');

-- ---------- donations ----------
INSERT INTO donations (donor_id, donation_date, units_donated) VALUES
(1,  '2026-01-10', 1),
(2,  '2026-01-12', 1),
(3,  '2026-01-15', 1),
(4,  '2026-01-18', 1),
(5,  '2026-01-20', 1),
(6,  '2026-02-02', 1),
(7,  '2026-02-05', 1),
(8,  '2026-02-08', 1),
(9,  '2026-02-11', 1),
(10, '2026-02-14', 1),
(11, '2026-03-01', 1),
(12, '2026-03-04', 1),
(13, '2026-03-07', 1),
(14, '2026-03-10', 1),
(15, '2026-03-13', 1),
(16, '2026-04-01', 1),
(17, '2026-04-04', 1),
(18, '2026-04-07', 1),
(19, '2026-04-10', 1),
(20, '2026-04-13', 1),
(21, '2026-05-01', 1),
(22, '2026-05-04', 1),
(1,  '2026-06-01', 1),
(3,  '2026-06-05', 1),
(5,  '2026-06-10', 1),
(9,  '2026-07-01', 1),
(12, '2026-07-05', 1);

-- ---------- blood_stock----------
INSERT INTO blood_stock (blood_group, units_available) VALUES
('A+',  18),
('A-',  9),
('B+',  14),
('B-',  7),
('AB+', 11),
('AB-', 5),
('O+',  22),
('O-',  9);

-- ---------- hospitals----------
INSERT INTO hospitals (hospital_name, contact_person, phone, email, address) VALUES
('Sunshine Hospital', 'Dr. Kiran', '9876500017', 'sunshine@hospital.com', 'Hyderabad'),
('Yashoda Hospitals', 'Dr. Meera', '9876500018', 'yashodahospitals@hospital.com', 'Hyderabad'),
('Care Hospitals', 'Dr. Rahul', '9876500019', 'carehospitals@hospital.com', 'Warangal'),
('Narayana Hospital', 'Dr. Anjali', '9876500020', 'narayana@hospital.com', 'Vijayawada'),
('Medicover Hospital', 'Dr. Arjun', '9876500021', 'medicover@hospital.com', 'Hyderabad'),
('Rainbow Hospital', 'Dr. Sneha', '9876500022', 'rainbow@hospital.com', 'Hyderabad'),
('Apollo Hospitals', 'Dr. Vikram', '9876500023', 'apollohospitals@hospital.com', 'Bengaluru'),
('Kamineni Hospital', 'Dr. Lakshmi', '9876500024', 'kamineni@hospital.com', 'Hyderabad'),
('Global Hospital', 'Dr. Rakesh', '9876500025', 'global@hospital.com', 'Chennai'),
('KIMS Hospital', 'Dr. Divya', '9876500026', 'kimshospital@hospital.com', 'Secunderabad'),
('AIG Hospitals', 'Dr. Naveen', '9876500031', 'aig@hospital.com', 'Hyderabad'),
('Continental Hospitals', 'Dr. Farah', '9876500032', 'continental@hospital.com', 'Hyderabad'),
('Basavatarakam Hospital', 'Dr. Rajesh', '9876500033', 'basavatarakam@hospital.com', 'Hyderabad'),
('Government General Hospital', 'Dr. Mahesh', '9876500034', 'general@hospital.com', 'Vijayawada');

-- ---------- blood_requests----------
INSERT INTO blood_requests (hospital_id, user_id, blood_group, units_required, request_date, status) VALUES
(1, 4, 'O+',  3, '2026-06-01', 'Approved'),
(2, 5, 'A+',  2, '2026-06-02', 'Approved'),
(3, 6, 'B+',  4, '2026-06-03', 'Pending'),
(4, 7, 'AB+', 1, '2026-06-04', 'Rejected'),
(5, 4, 'O-',  2, '2026-06-05', 'Approved'),
(6, 5, 'A-',  3, '2026-06-06', 'Pending'),
(1, 6, 'B-',  2, '2026-06-10', 'Approved'),
(2, 7, 'AB-', 1, '2026-06-11', 'Pending'),
(3, 8, 'O+',  5, '2026-06-12', 'Approved'),
(4, 4, 'A+',  2, '2026-06-15', 'Pending'),
(5, 5, 'B+',  3, '2026-06-18', 'Approved'),
(6, 6, 'O+',  4, '2026-06-20', 'Pending'),
(1, 7, 'AB+', 2, '2026-06-22', 'Rejected'),
(2, 8, 'O-',  1, '2026-06-25', 'Approved');

-- ---------- blood_issues---------
INSERT INTO blood_issues (request_id, user_id, units_issued, issue_date) VALUES
(1,  2, 3, '2026-06-02'),
(2,  2, 2, '2026-06-03'),
(5,  3, 2, '2026-06-06'),
(7,  3, 2, '2026-06-11'),
(9,  2, 5, '2026-06-13'),
(11, 3, 3, '2026-06-19'),
(14, 2, 1, '2026-06-26');

-- ============================================================
-- TRIGGERS
-- ============================================================

DELIMITER $$

-- Trigger 1: Protect Admin/Manager accounts from role tampering
-- Runs: BEFORE any UPDATE on the users table
-- Checks: if the row being updated currently has role Admin/Manager
--         and the new value tries to change that role
-- Action: blocks the update and raises a custom error
CREATE TRIGGER trg_protect_admin_role
BEFORE UPDATE ON users
FOR EACH ROW
BEGIN
    IF OLD.role IN ('Admin','Manager') AND NEW.role <> OLD.role THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Role of Admin/Manager users cannot be changed';
    END IF;
END$$

-- Trigger 2: Prevent blood_stock units_available from going negative
-- Runs: BEFORE any UPDATE on the blood_stock table
-- Checks: if the new units_available value is less than 0
-- Action: blocks the update and raises a custom error
CREATE TRIGGER trg_prevent_negative_stock
BEFORE UPDATE ON blood_stock
FOR EACH ROW
BEGIN
    IF NEW.units_available < 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Blood stock units cannot become negative';
    END IF;
END$$

DELIMITER ;

-- ============================================================
-- TEST QUERIES
-- ============================================================

-- 1. Current inventory
SELECT * FROM blood_stock;

-- 2. Number of donations made by each donor
SELECT d.name, d.blood_group, COUNT(dn.donation_id) AS total_donations
FROM donors d
JOIN donations dn ON d.donor_id = dn.donor_id
GROUP BY d.donor_id, d.name, d.blood_group
ORDER BY total_donations DESC;

-- 3. All pending requests with hospital names
SELECT h.hospital_name, br.blood_group, br.units_required, br.status
FROM blood_requests br
JOIN hospitals h ON br.hospital_id = h.hospital_id
WHERE br.status = 'Pending';

-- 4. Total units issued per blood group
SELECT br.blood_group, SUM(bi.units_issued) AS total_units_issued
FROM blood_issues bi
JOIN blood_requests br ON bi.request_id = br.request_id
GROUP BY br.blood_group;

-- 5. Which staff/manager issued blood, and for which hospital
SELECT u.full_name AS issued_by, h.hospital_name, bi.units_issued, bi.issue_date
FROM blood_issues bi
JOIN users u ON bi.user_id = u.user_id
JOIN blood_requests br ON bi.request_id = br.request_id
JOIN hospitals h ON br.hospital_id = h.hospital_id
ORDER BY bi.issue_date;

-- ============================================================
-- TRIGGER DEMO (commented out - uncomment to test, will raise errors)
-- ============================================================
-- UPDATE users SET role = 'Staff' WHERE username = 'admin';
--   -> Error: Role of Admin/Manager users cannot be changed
-- UPDATE blood_stock SET units_available = -5 WHERE blood_group = 'O+';
--   -> Error: Blood stock units cannot become negative