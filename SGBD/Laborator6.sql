-- EXEMPLE
-- 1. Definiti un pachet care permite prin intermediul a doua functii calculul numarului de angajati si
-- suma ce trebuie alocata pentru plata salariilor si comisioanelor pentru un departament
-- al carui cod este dat ca paramteru.

CREATE OR REPLACE PACKAGE package1_dda AS
    FUNCTION f_numar(cod_dept departments.department_id%TYPE)
        RETURN NUMBER;
    FUNCTION f_suma(cod_dept departments.department_id%TYPE)
        RETURN NUMBER;
END package1_dda;
/

CREATE OR REPLACE PACKAGE BODY package1_dda AS
    FUNCTION f_numar(cod_dept departments.department_id%TYPE)
        RETURN NUMBER IS numar_angajati NUMBER;
    BEGIN
        SELECT COUNT(*) INTO numar_angajati
        FROM employees
        WHERE department_id = cod_dept;
        RETURN numar_angajati;
    END f_numar;
    
    FUNCTION f_suma(cod_dept departments.department_id%TYPE)
        RETURN NUMBER IS suma NUMBER;
    BEGIN
        SELECT SUM(NVL(salary,0) + NVL(commission_pct,0) * NVL(salary,0) ) INTO suma
        FROM employees
        WHERE department_id = cod_dept;
        RETURN suma;
    END f_suma;
END package1_dda;
/

-- Apelare:
--In SQL
SELECT package1_dda.f_numar(80) AS "Numar angajati" FROM DUAL;
SELECT package1_dda.f_suma(80) FROM DUAL;

--IN PL/SQL
SET SERVEROUTPUT ON;
BEGIN
    DBMS_OUTPUT.PUT_LINE('Numarul de salariati din departamentul 80 este ' || package1_dda.f_numar(80));
    DBMS_OUTPUT.PUT_LINE('Suma alocata pentru departamentul 80 este ' || package1_dda.f_suma(80));
END;
/


-- 2. Creati un pachet ce include ce include actiuni pentru adaugarea unui nou departament in tabelul dep_dda si a unui nou angajat 
-- (ce va lucra in acest departament) in tabelul emp_dda. Procedurile pachetului vor fi apelate din SQL, respectiv PL/SQL. 
-- Se va verifica daca managerul departamentului exista inregistrat ca salariat. De asemenea, se va verifica daca locatia departamentului exista.
-- Pentru inserarea codului salariatului se va utiliza o secventa.
DESC dep_dda;
DESC emp_dda;

--ALTER TABLE dep_dda
--ADD PRIMARY KEY (department_id);

CREATE SEQUENCE sec_dda;

CREATE OR REPLACE PACKAGE package2_dda AS
    PROCEDURE p_add_dep (v_dep_id dep_dda.department_id%TYPE,
                         v_dep_name dep_dda.department_name%TYPE,
                         v_mng_id dep_dda.manager_id%TYPE,
                         v_location_id dep_dda.location_id%TYPE);
    PROCEDURE p_add_emp (v_first_name emp_dda.first_name%TYPE,
                         v_last_name emp_dda.last_name%TYPE,
                         v_email emp_dda.email%TYPE,
                         v_phone_number emp_dda.phone_number%TYPE := NULL,
                         v_hire_date emp_dda.hire_date%TYPE := SYSDATE,
                         v_job_id emp_dda.job_id%TYPE,
                         v_salary emp_dda.salary%TYPE :=0,
                         v_commission_pct emp_dda.commission_pct%TYPE :=0,
                         v_mng_id emp_dda.manager_id%TYPE,
                         v_dep_id emp_dda.department_id%TYPE);
    FUNCTION exista_loc_id(id_location dep_dda.location_id%TYPE)
    RETURN BOOLEAN;
    FUNCTION exista_mng_id(id_mng dep_dda.manager_id%TYPE)
    RETURN BOOLEAN;
END package2_dda;
/

CREATE OR REPLACE PACKAGE BODY package2_dda AS
    FUNCTION exista_loc_id(id_location dep_dda.location_id%TYPE)
    RETURN BOOLEAN IS
        rez_id_loc NUMBER;
        rezultat BOOLEAN := TRUE;
    BEGIN
        SELECT COUNT(*) INTO rez_id_loc
        FROM dep_dda
        WHERE location_id = id_location;
        
        IF rez_id_loc = 0 THEN
            rezultat := FALSE;
        END IF;
        RETURN rezultat;
    END;

    FUNCTION exista_mng_id(id_mng dep_dda.manager_id%TYPE)
    RETURN BOOLEAN IS
        rez_id_mng NUMBER;
        rezultat BOOLEAN := TRUE;
    BEGIN
        SELECT COUNT(*) INTO rez_id_mng
        FROM dep_dda
        WHERE manager_id = id_mng;
        
        IF rez_id_mng = 0 THEN
            rezultat := FALSE;
        END IF;
        RETURN rezultat;
    END;
    
    PROCEDURE p_add_dep (v_dep_id dep_dda.department_id%TYPE,
                     v_dep_name dep_dda.department_name%TYPE,
                     v_mng_id dep_dda.manager_id%TYPE,
                     v_location_id dep_dda.location_id%TYPE) AS
    BEGIN
        IF exista_loc_id(v_location_id) = FALSE OR exista_mng_id(v_mng_id) = FALSE THEN
            DBMS_OUTPUT.PUT_LINE('NU s-au introdus date coerente pentru tabelul dep_dda!');
        ELSE
            INSERT INTO dep_dda
                (department_id, department_name, manager_id, location_id)
            VALUES (v_dep_id, v_dep_name, v_mng_id, v_location_id);
        END IF;    
    END p_add_dep;
    
    PROCEDURE p_add_emp (v_first_name emp_dda.first_name%TYPE,
                     v_last_name emp_dda.last_name%TYPE,
                     v_email emp_dda.email%TYPE,
                     v_phone_number emp_dda.phone_number%TYPE := NULL,
                     v_hire_date emp_dda.hire_date%TYPE := SYSDATE,
                     v_job_id emp_dda.job_id%TYPE,
                     v_salary emp_dda.salary%TYPE :=0,
                     v_commission_pct emp_dda.commission_pct%TYPE :=0,
                     v_mng_id emp_dda.manager_id%TYPE,
                     v_dep_id emp_dda.department_id%TYPE) AS
    BEGIN
        INSERT INTO emp_dda
        VALUES (sec_dda.NEXTVAL, v_first_name, v_last_name, v_email,
            v_phone_number,v_hire_date, v_job_id, v_salary,
            v_commission_pct, v_mng_id, v_dep_id );
    END p_add_emp;
END package2_dda;
/


EXECUTE package2_dda.p_add_dep(50,'Economic',200,2000);

SELECT * FROM dep_dda WHERE department_id=50;

DESC emp_dda;
EXECUTE package2_dda.p_add_emp('f','l','email',v_job_id => 'j', v_mng_id => 200,v_dep_id => 50);

SELECT * FROM emp_dda WHERE job_id='j';

ROLLBACK;

BEGIN
   package2_dda.p_add_dep(150,'Economic',99,2000);
   package2_dda.p_add_emp('f','l','e',v_job_id=>'j',v_mng_id=>200,v_dep_id=>150);
END;
/

SELECT * FROM emp_dda WHERE job_id='j';
SELECT * FROM dep_dda WHERE department_name = 'Economic';
ROLLBACK;


--3. Definiti un pachet caruia sa se obtina salariul maxim inregistrat pentru salariatii care lucreaza  intr-un anumit oras si
-- lista salariatilor care au salariul mai mare sau egal decat acel maxim. Pachetul va contine un cursor si o functie.
CREATE OR REPLACE PACKAGE package3_dda AS
    CURSOR c_salariati(sal NUMBER) RETURN employees%ROWTYPE;
    FUNCTION f_salariu_maxim(v_city locations.city%TYPE)
    RETURN NUMBER;
END package3_dda;
/

CREATE OR REPLACE PACKAGE BODY package3_dda AS
    CURSOR c_salariati(sal NUMBER)
    RETURN employees%ROWTYPE
    IS
        SELECT *
        FROM employees
        WHERE salary >= sal;
        
    FUNCTION f_salariu_maxim(v_city locations.city%TYPE)
    RETURN NUMBER IS salariu_maxim NUMBER;
    BEGIN
        SELECT MAX(e.salary) INTO salariu_maxim
        FROM employees e JOIN departments d
            ON e.department_id = d.department_id
        JOIN locations l
            ON d.location_id = l.location_id
        WHERE UPPER(l.city) = UPPER(v_city);
        RETURN salariu_maxim;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('Could not find the city ' || v_city);
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE(SQLCODE || ' - ' || SQLERRM);  
    END f_salariu_maxim;    
END package3_dda;
/

SET  SERVEROUTPUT ON;
DECLARE
    v_sal_maxim NUMBER := 0;
    v_city locations.city%TYPE := 'Toronto';
BEGIN
    v_sal_maxim := package3_dda.f_salariu_maxim(v_city);
    DBMS_OUTPUT.PUT_LINE('CITY: ' || v_city || '  SALARY: ' || v_sal_maxim);
    DBMS_OUTPUT.NEW_LINE;
    FOR v_cursor IN package3_dda.c_salariati(v_sal_maxim) LOOP
        DBMS_OUTPUT.PUT_LINE(v_cursor.employee_id || ' | ' || v_cursor.last_name || ' ' || v_cursor.first_name || ' | ' || v_cursor.salary);
    END LOOP;
END;
/


--4. Definiti un pachet  care sa contina o procedura prin care se verifica daca o combinatie specificata dintre campurile
-- employee_id si job_id este o combinatie care exista in tabelul employees.
CREATE OR REPLACE PACKAGE package4_dda IS
    PROCEDURE p_verify(v_emp_id employees.employee_id%TYPE,
                      v_job_id employees.job_id%TYPE);
    CURSOR c_employees RETURN employees%ROWTYPE;
END package4_dda;
/

CREATE OR REPLACE PACKAGE BODY package4_dda IS
    CURSOR c_employees RETURN employees%ROWTYPE IS
        SELECT *
        FROM employees;
    
    PROCEDURE p_verify(v_emp_id employees.employee_id%TYPE,
                      v_job_id employees.job_id%TYPE) 
    IS
        employee_row employees%ROWTYPE;
        found BOOLEAN := FALSE;
        my_exception EXCEPTION;
    BEGIN
        OPEN c_employees;
        LOOP
            FETCH c_employees INTO employee_row;
            EXIT WHEN c_employees%NOTFOUND OR found = TRUE;
            IF employee_row.employee_id = v_emp_id AND employee_row.job_id = v_job_id THEN
                found := TRUE;
            END IF;
        END LOOP;
        CLOSE c_employees;
        
        IF found = FALSE THEN RAISE my_exception;
        ELSE
            DBMS_OUTPUT.PUT_LINE('Combination exists!');
        END IF;
    EXCEPTION
        WHEN MY_EXCEPTION THEN
            DBMS_OUTPUT.PUT_LINE('There is no employee with employee_id ' || v_emp_id || ' and job_id ' || v_job_id);
        WHEN CURSOR_ALREADY_OPEN THEN
            DBMS_OUTPUT.PUT_LINE('Cursor is already open : ' || SQLCODE || ' - ' || SQLERRM);
        WHEN INVALID_NUMBER THEN 
            DBMS_OUTPUT.PUT_LINE('Invalid number(verify parameters): ' || SQLCODE || ' - ' || SQLERRM);
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE(SQLCODE || ' - '|| SQLERRM);         
    END p_verify;
END package4_dda;
/

SET SERVEROUTPUT ON;       
EXECUTE package4_dda.p_verify(200,'AD_ASST');
EXECUTE package4_dda.p_verify(700,'AD_PRES');
        
--- PACHETE PREDEFINITE
-- 1. Pachetul DBMS_OUTPUT 
SET SERVEROUTPUT ON;
DECLARE
-- paramentrii de tip OUT pt procedura GET_LINE
     linie1 VARCHAR2(255);
     stare1 INTEGER;
     linie2 VARCHAR2(255);
     stare2 INTEGER;
     linie3 VARCHAR2(255);
     stare3 INTEGER; 
     
     v_emp employees.employee_id%TYPE;
     v_job employees.job_id%TYPE;
     v_dept employees.department_id%TYPE;
BEGIN
    SELECT employee_id, job_id, department_id
    INTO v_emp, v_job, v_dept
    FROM employees
    WHERE UPPER(last_name) LIKE UPPER('Hunold');

    -- se introduce o linie in buffer fara caracter de terminare linie
    DBMS_OUTPUT.PUT(' 1 ' || v_emp || ' ');
    
    -- se incearca extragerea liniei introdusa in buffer si starea acesteia
    DBMS_OUTPUT.GET_LINE(linie1,stare1);
    
    -- se depunde informatia pe aceeasi linie in buffer
    DBMS_OUTPUT.PUT(' 2 ' || v_job || ' ');
    
    -- se inchide linia depusa in buffer si se extrage linia din buffer
    DBMS_OUTPUT.NEW_LINE;
    DBMS_OUTPUT.GET_LINE(linie2,stare2);
    
    --se introduc informatii pe aceeasi linie si se afiseaza apoi
    DBMS_OUTPUT.PUT_LINE(' 3 ' || v_emp || ' ' || v_dept);
    DBMS_OUTPUT.GET_LINE(linie3,stare3);
    
    -- se afiseaza ceea ce s-a extras
    DBMS_OUTPUT.PUT_LINE('linie1 = ' || linie1 || '; stare1 = ' || stare1);
    DBMS_OUTPUT.PUT_LINE('linie2 = ' || linie2 || '; stare2 = ' || stare2);
    DBMS_OUTPUT.PUT_LINE('linie3 = ' || linie3 || '; stare3 = ' || stare3);
END;
/

--2.
DECLARE
    -- parametru de tip OUT pentru NEW_LINES
    -- tablou de siruri de caractere
    linii DBMS_OUTPUT.CHARARR;
    -- paramentru de tip IN OUT pentru NEW_LINES
    nr_linii INTEGER;
    v_emp employees.employee_id%TYPE;
    v_job employees.job_id%TYPE;
    v_dept employees.department_id%TYPE; 
BEGIN
    SELECT employee_id, job_id, department_id
    INTO v_emp,v_job,v_dept
    FROM employees
    WHERE last_name='Lorentz';
    -- se mareste dimensiunea bufferului
    DBMS_OUTPUT.ENABLE(1000000);
    DBMS_OUTPUT.PUT(' 1 '||v_emp|| ' ');
    DBMS_OUTPUT.PUT(' 2 '||v_job|| ' ');
    DBMS_OUTPUT.NEW_LINE;
    DBMS_OUTPUT.PUT_LINE(' 3 ' ||v_emp|| ' '|| v_job);
    DBMS_OUTPUT.PUT_LINE(' 4 ' ||v_emp|| ' '||
    v_job||' ' ||v_dept);
    -- se afiseaza ceea ce s-a extras
    nr_linii := 4;
    DBMS_OUTPUT.GET_LINES(linii,nr_linii);
    DBMS_OUTPUT.put_line('In buffer sunt '||
    nr_linii ||' linii');
    FOR i IN 1..nr_linii LOOP
    DBMS_OUTPUT.put_line(linii(i));
    END LOOP;
    nr_linii := 4;
    DBMS_OUTPUT.GET_LINES(linii,nr_linii);
    DBMS_OUTPUT.put_line('Acum in buffer sunt '|| nr_linii ||' linii');
    FOR i IN 1..nr_linii LOOP
        DBMS_OUTPUT.put_line(linii(i));
    END LOOP;
    
--    DBMS_OUTPUT.disable;
--    DBMS_OUTPUT.enable;
    
    nr_linii := 4;
    DBMS_OUTPUT.GET_LINES(linii,nr_linii);
    DBMS_OUTPUT.put_line('Acum in buffer sunt '|| nr_linii ||' linii');
END;
/


-- 2. Pachetul DBMS_JOB este utlizat pentru planificarea executiei programelor PL/SQL
--    - SUBMIT - adauga un nou job in coada de asteptarea a job-urilor
--    - REMOVE - sterge un job din coada de asteptare
--    - RUN - executa imediat un job specificat
--    - INTERVAL este de tip VARCHAR2 DEFAULT 'NULL'
CREATE OR REPLACE PROCEDURE marire_salariu_dda(id_angajat employees.employee_id%TYPE, valoare NUMBER)
IS
BEGIN
    UPDATE emp_dda
    SET salary = salary + valoare
    WHERE employee_id = id_angajat;
END;
/


SELECT salary FROM emp_dda WHERE employee_id = 100;

VARIABLE nr_job NUMBER
BEGIN
    DBMS_JOB.SUBMIT(
        -- intoarce numarul job-ului, printr-o variabila de legatura
        JOB => :nr_job,
        -- codul PL/SQL ce va fi executat
        WHAT => 'marire_salariu_dda(100, 1000);',
        -- data de start a executiei (dupa 30 de secunde)
        NEXT_DATE => SYSDATE + 30 / 86400,
        -- intervalul de timp la care se repeta executia
        INTERVAL => 'SYSDATE+1'
    );
    COMMIT;
END;
/

-- numarul jobului 
PRINT nr_job; 

-- asteptati 30 de secunde
SELECT salary FROM emp_dda WHERE employee_id = 100;


--Varianta 2
CREATE OR REPLACE PACKAGE pachet_job_dda 
IS
    nr_job NUMBER;
    FUNCTION obtine_job RETURN NUMBER;
END;
/

CREATE OR REPLACE PACKAGE BODY pachet_job_dda
IS
    FUNCTION obtine_job RETURN NUMBER 
    IS
    BEGIN
        RETURN nr_job;
    END;
END;
/
    
SELECT salary FROM emp_dda WHERE employee_id = 100;    
BEGIN
    DBMS_JOB.SUBMIT(
    -- intoarce numarul jobului printr-o variabila de legatura
    JOB => pachet_job_dda.nr_job,
    --codul PL/SQL ce trebuie executat
    WHAT => 'marire_salariu_dda(100,1000);',
    -- data de start a executiei
    NEXT_DATE => SYSDATE + 30/86400,
    --intervalul de timp la care se repeta executia
    INTERVAL => 'SYSDATE+1');
END;
/

-- Asteptati 30 de secunde
SELECT salary FROM emp_dda WHERE employee_id = 100;    

-- informatii despre joburi
SELECT JOB, NEXT_DATE, WHAT
FROM USER_JOBS
WHERE JOB = pachet_job_dda.obtine_job;

-- lansarea jobului la momentul dat
BEGIN
    DBMS_JOB.RUN(JOB => pachet_job_dda.obtine_job);
END;
/
SELECT salary FROM emp_dda WHERE employee_id = 100;    

-- stergerea unui job
SET SERVEROUTPUT ON
DECLARE
    exceptie EXCEPTION;
    PRAGMA EXCEPTION_INIT(exceptie,-23421);
BEGIN
    DBMS_JOB.REMOVE(JOB => pachet_job_dda.obtine_job);
EXCEPTION
    WHEN exceptie THEN
        DBMS_OUTPUT.PUT_LINE('There is no job visible  with number ' || pachet_job_dda.obtine_job || ' in the job queue!');
        DBMS_OUTPUT.PUT_LINE('Maybe it was removed before.');
END;
/

UPDATE emp_dda
SET salary = 24000 
WHERE  employee_id = 100; 
COMMIT;


--Pachetul UTL_FILE
CREATE OR REPLACE PROCEDURE scriu_fisier_dda(director VARCHAR2, fisier VARCHAR2)
IS   
    v_file UTL_FILE.FILE_TYPE;   
    CURSOR cursor_rez IS
        SELECT department_id departament, SUM(salary) suma      
        FROM employees      
        GROUP BY department_id      
        ORDER BY SUM(salary);  
    v_rez cursor_rez%ROWTYPE; 
BEGIN  
    v_file := UTL_FILE.FOPEN(director, fisier, 'w');  
    UTL_FILE.PUTF(v_file, 'Suma salariilor pe departamente\nRaport generat pe data ');  
    UTL_FILE.PUT(v_file, SYSDATE);  
    UTL_FILE.NEW_LINE(v_file);  
    OPEN cursor_rez;  
    LOOP      
        FETCH cursor_rez INTO v_rez;      
        EXIT WHEN cursor_rez%NOTFOUND;      
        UTL_FILE.NEW_LINE(v_file);      
        UTL_FILE.PUT(v_file, v_rez.departament);      
        UTL_FILE.PUT(v_file, '         ');      
        UTL_FILE.PUT(v_file, v_rez.suma);  
    END LOOP;  
    CLOSE cursor_rez;  
    UTL_FILE.FCLOSE(v_file); 
END; 
/ 

EXECUTE scriu_fisier_dda('C:\Users\Dana\Desktop','test.txt'); 

-- EXERCITII
DESC emp_dda;

ALTER TABLE emp_dda
ADD PRIMARY KEY (employee_id);
-- 1. Definiti un pachet care sa permita gestionarea angajatilor companiei. Pachetul va contine:
--    a) o procedura care determina adaugarea unui angajat, dandu-se informatii complete despre acesta
--       - codul angajatului va fi generat automat utilizandu-se o secventa; 
--       - informatiile personale vor fi date ca parametrii (nume, prenume, telefon, email); 
--       - data angajarii va fi data curenta; 
--       - salariul va fi cel mai mic salariu din departamentul respectiv, pentru jobul respectiv (se vor obtine cu ajutorul unei functii stocate in pachet);   
--       - nu va avea comision; 
--       - codul managerului se va obtine cu ajutorul unei functii stocate in pachet care va avea ca parametrii numele si prenumele managerului); 
--       - codul  departamentului  va  fi  obtinut  cu  ajutorul  unei  functii  stocate  �n  pachet,  dandu-se ca parametru numele acestuia; 
--       - codul jobului va fi obtinut cu ajutorul unei functii stocate in pachet, dandu-se ca parametru numele acesteia

CREATE SEQUENCE sec_dda;

DESC JOBS;
SELECT * FROM JOBS;

CREATE OR REPLACE PACKAGE pachet1_dda AS
    FUNCTION f_cod_job(job_name jobs.job_title%TYPE)
    RETURN jobs.job_id%TYPE;
    FUNCTION f_salariu_minim(dept_id emp_dda.department_id%TYPE)
    RETURN emp_dda.salary%TYPE;
    FUNCTION f_cod_manager(prenume emp_dda.first_name%TYPE, nume emp_dda.last_name%TYPE)
    RETURN emp_dda.employee_id%TYPE;
END pachet1_dda;
/

CREATE OR REPLACE PACKAGE BODY pachet1_dda AS
    FUNCTION f_cod_job(job_name jobs.job_title%TYPE)
        RETURN jobs.job_id%TYPE IS job_cod jobs.job_id%TYPE;
    BEGIN
        SELECT job_id INTO job_cod
        FROM jobs
        WHERE UPPER(TRIM (BOTH ' ' FROM (job_title))) = UPPER(TRIM(BOTH ' ' FROM (job_name)));
    RETURN job_cod;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('Job title does not exist! -- SQLCODE: ' || SQLCODE || '-' || SQLERRM);
            RETURN -1;
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20001,'An error was encountered - '||SQLCODE||' -ERROR- '||SQLERRM);
            RETURN -3;
    END f_cod_job;
    
    FUNCTION f_salariu_minim(dept_id emp_dda.department_id%TYPE)
        RETURN emp_dda.salary%TYPE IS salariu emp_dda.salary%TYPE;
    BEGIN
        SELECT MIN(salary) INTO salariu
        FROM emp_dda
        WHERE department_id = dept_id;
    RETURN salariu;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('Department id does not exist!');
            RETURN -1;
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20001,'An error was encountered - '||SQLCODE||' -ERROR- '||SQLERRM);
            RETURN -3;
    END f_salariu_minim;
    
    FUNCTION f_cod_manager(prenume emp_dda.first_name%TYPE, nume emp_dda.last_name%TYPE) 
    RETURN emp_dda.employee_id%TYPE IS manager_id emp_dda.employee_id%TYPE;
    BEGIN
        SELECT employee_id INTO manager_id
        FROM emp_dda
        WHERE first_name = prenume 
            AND last_name = nume;
        RETURN manager_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('There is no employee with first_name ' || prenume || ' and last_name ' || nume);
            RETURN -1;
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20001,'An error was encountered - '||SQLCODE||' -ERROR- '||SQLERRM);
            RETURN -3;  
    END f_cod_manager;
END pachet1_dda;
/

SELECT pachet1_dda.f_cod_job('Accountant') FROM DUAL; -- o functie care primeste ca parametru un job_name si returneaza un job_id
SELECT pachet1_dda.f_salariu_minim(50) FROM DUAL; -- o functie ce primeste ca parametru un job_id si returneaza salariul minim pe respectivul departament
SELECT pachet1_dda.f_cod_manager('Steven', 'King') FROM DUAL; -- o functie ce primeste ca parametru numele si prenumele managerului si intoarce codul acestuia