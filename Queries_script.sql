set search_path to G1_15;

-- SELECT * FROM PATIENT;
-- SELECT * FROM TEST_DETAILS;
-- SELECT * FROM LAB_REPORT;
-- SELECT * FROM ROOMS;
-- SELECT * FROM ROOM_ALLOTMENT;
-- SELECT * FROM PATIENT_PHONE;
-- SELECT * FROM PATIENT_EMAIL;
-- SELECT * FROM DOCTOR;
-- SELECT * FROM APPOINTMENT;
-- SELECT * FROM PATIENT_REPORT;
-- SELECT * FROM MEDICINE;
-- SELECT * FROM PRESCRIPTION_DETAILS;
-- SELECT * FROM SUPPLIER;
-- SELECT * FROM MEDICINE_DETAILS;
-- SELECT * FROM SUPPLIER_CONTACT;
-- SELECT * FROM SUPPLIER_EMAIL;
-- SELECT * FROM INSURANCE;
-- SELECT * FROM BILL;
-- SELECT * FROM DEPARTMENT;
-- SELECT * FROM EMPLOYEE_DETAILS;
-- SELECT * FROM PAYROLL;
-- SELECT * FROM EMPLOYEE_PHONE;
-- SELECT * FROM EMPLOYEE_EMAIL;
-- SELECT * FROM TESTS_LIST;

-- Insertion Queries
-- 1. Give all details of given PID
SELECT * FROM PATIENT WHERE PID = 'P050';

-- 2. Give DocID, full name and last name of Doctor who have speciality in Surgeon
SELECT * FROM DOCTOR WHERE SPECIALITY ILIKE 'SURGEON';

-- 3. Give details of all appointments of a specific DocID
SELECT * FROM APPOINTMENT WHERE DOCID = 'D06';

-- 4. List all appointments of a given date
SELECT * FROM APPOINTMENT WHERE APMNT_DATE = '2023-05-01';

-- 5. List all patient reports handled by given DOCID
SELECT * FROM PATIENT_REPORT WHERE DOCID = 'D03';

-- 6. List rooms and bed no which are currently occupied
SELECT * FROM ROOM_ALLOTMENT WHERE DISCHARGE_DATE IS NULL;

-- 7. List available rooms and bed no
SELECT ROOM_NO, BED_NO, ROOM_CHARGE FROM ROOMS WHERE (ROOM_NO,BED_NO) 
	NOT IN (SELECT ROOM_NO,BED_NO FROM ROOM_ALLOTMENT WHERE DISCHARGE_DATE IS NULL);

-- 8. Generate TOTAL_ROOM_CHARGE FOR A GIVEN INDEX WHO HAS BEEN DISCHARGED.
-- option one for computing
SELECT *, (CHARGE * (DATE(DISCHARGE_DATE) - DATE(ADMIT_DATE)))AS TOTAL_ROOM_CHARGE FROM ROOM_ALLOTMENT WHERE INDEX = 'RA065' ;
-- option two for just showing as text
SELECT *,
CASE
	WHEN DISCHARGE_DATE IS NULL THEN 'Patient is still admitted. Dont worry about payment right now.'
	ELSE (CHARGE * (DATE(DISCHARGE_DATE) - DATE(ADMIT_DATE)))::TEXT
	END AS TOTAL_ROOM_CHARGE FROM ROOM_ALLOTMENT WHERE INDEX = 'RA005'; -- Given an invalid room

-- 9. A patient with corona have to be admitted in single room all alone. Find fully vacant rooms
SELECT ROOM_NO FROM ROOMS
	EXCEPT
SELECT ROOM_NO FROM ROOM_ALLOTMENT WHERE DISCHARGE_DATE IS NULL;

-- 10. Find all patients who came to check heart and lung related problems and their diagnose
SELECT PID, FNAME, LNAME, DIAGNOSIS FROM PATIENT NATURAL JOIN PATIENT_REPORT
	NATURAL JOIN DOCTOR WHERE SPECIALITY ILIKE 'CARDIOLOGY';

-- 11. List all medicines prescribed by Pediatrics.
SELECT MED_ID, MED_NAME FROM MEDICINE NATURAL JOIN PRESCRIPTION_DETAILS NATURAL JOIN PATIENT_REPORT
	NATURAL JOIN (SELECT DOCID FROM DOCTOR WHERE SPECIALITY ILIKE 'PEDIATRICS') AS D;
	
-- 12. List all medicines supplied by a given supplier.
SELECT DISTINCT MED_ID, MED_NAME, MED_DESCRIPTION, SUPPLIER_COMPANY FROM MEDICINE NATURAL JOIN MEDICINE_DETAILS
	NATURAL JOIN  SUPPLIER WHERE SUPPLIER_ID = 'SUP005';

-- 13. List medicine batches which will expire till given date
SELECT MED_ID, MED_NAME, PRODUCTION_DATE FROM MEDICINE_DETAILS NATURAL JOIN MEDICINE
	WHERE EXPIRY_DATE >= '2023-06-01';

-- 14. List patient name whose lab report came abnormal.
SELECT PID, FNAME, LNAME, LAB_REPORT_ID, REPORT_DATE FROM PATIENT NATURAL JOIN LAB_REPORT
	WHERE TEST_RESULT ILIKE 'ABNORMAL';
	
-- 15. List all patients who took blood test and it's charge
SELECT PID, FNAME, LNAME, LAB_REPORT_ID, REPORT_DATE, TEST_CHARGE, TEST_TYPE FROM PATIENT NATURAL JOIN LAB_REPORT
	NATURAL JOIN TESTS_LIST NATURAL JOIN TEST_DETAILS WHERE TEST_TYPE ILIKE '%BLOOD%';

-- 16. List the IDs of any patients who were uninsured at the time of their bill.
SELECT BILL_NO, PID, BILL_DATE FROM BILL WHERE INSURANCE_NO = 'INS000';

-- 17. Check whether insurance covers whole bill of patient or not.
SELECT BILL_NO, PID, BILL_DATE,
CASE
	WHEN INSURANCE_NO = 'INS000' THEN 'No Insurance Issued.'
	WHEN (DOCTOR_CHARGE+LAB_CHARGE+MEDICINE_CHARGE+ROOM_CHARGE+OPERATION_CHARGE) > MED_COVERAGE
		THEN 'Insurance cannot cover whole bill amount.'
	ELSE 'Insurance covered.' END AS JUDGEMENT FROM BILL NATURAL JOIN INSURANCE;
	
-- 18. Verify whether a PID's insurance is still in effect as of the bill date.
SELECT BILL_NO, PID, BILL_DATE,
CASE
	WHEN INSURANCE_NO = 'INS000' THEN 'No Insurance Issured.'
	WHEN BILL_DATE > IN_EXPIRY_DATE THEN 'Insurance has expired.'
	ELSE 'Insurance is in effect.' END AS VERIFICATION FROM BILL NATURAL JOIN INSURANCE;
	
-- 19. How much patient has to pay if bill amount is more than insurance amount.
SELECT BILL_NO, PID, BILL_DATE,
CASE
	WHEN (DOCTOR_CHARGE+LAB_CHARGE+MEDICINE_CHARGE+ROOM_CHARGE+OPERATION_CHARGE) > MED_COVERAGE
		THEN (DOCTOR_CHARGE+LAB_CHARGE+MEDICINE_CHARGE+ROOM_CHARGE+OPERATION_CHARGE) - MED_COVERAGE
	ELSE 0 END AS PATIENT_CREDITS FROM BILL NATURAL JOIN INSURANCE;

-- 20. There was a corona outbreak on a perticular date so List all the patient and their default contact info who visited/Admitted in the hospital at the that date(SCENARIO)
SELECT PID, PHONE_NO 
FROM PATIENT_PHONE NATURAL JOIN (
	SELECT PID FROM APPOINTMENT WHERE DATE(APMNT_CREATED) = '2023-05-01'
	UNION
	SELECT PID FROM PATIENT_REPORT WHERE REPORT_DATE = '2023-05-01'
	UNION
	SELECT PID FROM LAB_REPORT WHERE REPORT_DATE = '2023-05-01'
	UNION
	SELECT PID FROM ROOM_ALLOTMENT
						WHERE (DISCHARGE_DATE IS NULL AND DATE(ADMIT_DATE) >= '2023-05-01') OR
								(DISCHARGE_DATE IS NOT NULL AND DATE(ADMIT_DATE) >= '2023-05-01' AND DATE(DISCHARGE_DATE) <= '2023-05-01')
	UNION
	SELECT PID FROM BILL WHERE BILL_DATE = '2023-05-01'
	)AS WHOLE
WHERE PHONE_TYPE ILIKE 'DEFAULT';

-- 21. List patient IDs who have been prescibed more than three medicines
SELECT PID, REPORT_ID, COUNT(MED_ID) AS TOTAL_MEDS FROM PATIENT_REPORT NATURAL JOIN PRESCRIPTION_DETAILS
	GROUP BY PID, REPORT_ID HAVING COUNT(MED_ID) >= 3 ORDER BY PID,REPORT_ID;
	
-- 22. List department wise hospital expenditure on salaries.
SELECT DEPT_ID, DEPT_NAME, SUM(NET_SALARY) FROM payroll NATURAL JOIN employee_details
	NATURAL JOIN department GROUP BY DEPT_ID, DEPT_NAME ORDER BY DEPT_ID, DEPT_NAME;
	
-- 23. List TOP 3 department wise hospital expenditure on salaries.
SELECT DEPT_ID, DEPT_NAME, SUM(NET_SALARY) FROM payroll NATURAL JOIN employee_details
	NATURAL JOIN department GROUP BY DEPT_ID, DEPT_NAME ORDER BY  SUM(NET_SALARY) DESC LIMIT 3;
	
-- 24. List employee details who does not have alternate phone number.
SELECT ID, FNAME, MINIT, LNAME FROM EMPLOYEE_DETAILS NATURAL JOIN employee_phone
	WHERE ID NOT IN (SELECT ID FROM employee_phone WHERE PHONE_TYPE ILIKE 'ALTERNATE');
	
-- 25. List medicines which were MADE IN INDIA
SELECT DISTINCT MED_ID, MED_NAME, MED_DESCRIPTION FROM MEDICINE NATURAL JOIN medicine_details
	WHERE ORIGIN_COUNTRY = 'India';