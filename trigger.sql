CREATE OR REPLACE TRIGGER JLS_VS_PRICE
BEFORE INSERT ON JLS_VIS
FOR EACH ROW
DECLARE
  DOB DATE;
BEGIN
  SELECT V_DOB INTO DOB FROM JLS_VISITORS WHERE V_ID = :NEW.V_ID;
  IF TRUNC(MONTHS_BETWEEN(SYSDATE, DOB)) / 12 < 7 THEN
    :NEW.PRICE := 0;
  END IF;
END;
/

CREATE OR REPLACE TRIGGER JLS_TK_DISCOUNT
BEFORE INSERT ON JLS_TICKETS
FOR EACH ROW
DECLARE 
  V_WEEKDAY VARCHAR2(5);
  V_YEAR NUMBER;
	V_MONTH NUMBER;
  V_DAY NUMBER;
	DOB DATE;
	MEMBER_ID NUMBER;
	GROUP_ID NUMBER;
	MEMBER_IDX NUMBER;
  FIRST_DAY_OF_MAY DATE;
  FIRST_DAY_OF_SEP DATE;
  FIRST_DAY_OF_NOV DATE;
  FIRST_MAY NUMBER;
  FIRST_SEP NUMBER;
  FIRST_NOV NUMBER;

BEGIN
    
  -- CHECK DATE
  V_WEEKDAY := TO_CHAR(TO_DATE(:NEW.TK_VDATE, 'DD-MON-YY'), 'DY');
  V_YEAR := EXTRACT(YEAR FROM :NEW.TK_VDATE);
  V_MONTH := EXTRACT(MONTH FROM :NEW.TK_VDATE);
  V_DAY := EXTRACT(DAY FROM :NEW.TK_VDATE);

  FIRST_DAY_OF_MAY := TO_DATE('01-MAY-' || V_YEAR, 'DD-MON-YYYY');
  FIRST_DAY_OF_SEP := TO_DATE('01-SEP-' || V_YEAR, 'DD-MON-YYYY');
  FIRST_DAY_OF_NOV := TO_DATE('01-NOV-' || V_YEAR, 'DD-MON-YYYY');

  FIRST_MAY := TO_NUMBER(TO_CHAR(FIRST_DAY_OF_MAY, 'D'));
  FIRST_SEP := TO_NUMBER(TO_CHAR(FIRST_DAY_OF_MAY, 'D'));
  FIRST_NOV := TO_NUMBER(TO_CHAR(FIRST_DAY_OF_MAY, 'D'));

  IF V_WEEKDAY IN ('SAT', 'SUN') OR
    -- NEW YEAR'S DAY
    (V_MONTH = 1 AND V_DAY = 1) OR 
    -- MEMORIAL DAY (LAST MONDAY IN MAY)
    (V_MONTH = 5 AND V_DAY = 28-FIRST_MAY+3) OR 
    -- INDEPENDENCE DAY
    (V_MONTH = 7 AND V_DAY = 4) OR 
    -- LABOR DAY (FIRST MONDAY IN SEPTEMBER)
    (V_MONTH = 9 AND V_DAY = 7-FIRST_SEP+3) OR 
    -- THANKSGIVING (FOURTH THURSDAY IN NOVEMBER)
    (V_MONTH = 11 AND V_DAY = 28-FIRST_NOV+6) OR 
    -- CHRISTMAS
    (V_MONTH = 12 AND V_DAY = 25) THEN 
    :NEW.TK_DISCOUNT := 0;

  ELSE
    -- CHECK AGE 
    SELECT V_DOB INTO DOB FROM JLS_VISITORS WHERE V_ID = :NEW.V_ID;
      
      IF TRUNC(MONTHS_BETWEEN(SYSDATE, DOB)) / 12 < 7 THEN
        :NEW.TK_DISCOUNT := 0.15;
      ELSIF TRUNC(MONTHS_BETWEEN(SYSDATE, DOB)) / 12 >= 60 THEN
        :NEW.TK_DISCOUNT := 0.15;
      ELSE
        :NEW.TK_DISCOUNT := 0;
      END IF;

    -- CHECK PURCHASE METHOD
      IF :NEW.TK_METHOD = 'OL' THEN
        :NEW.TK_DISCOUNT := :NEW.TK_DISCOUNT + 0.05;
      END IF;

    -- CHECK MEMBERSHIP
    SELECT M_ID INTO MEMBER_ID FROM JLS_VISITORS WHERE V_ID = :NEW.V_ID;

    IF MEMBER_ID IS NOT NULL THEN
      SELECT G_ID INTO GROUP_ID FROM JLS_GPV WHERE V_ID = :NEW.V_ID;

      IF GROUP_ID IS NOT NULL THEN
        SELECT MEM_INDEX INTO MEMBER_IDX FROM JLS_GPV WHERE V_ID = :NEW.V_ID;

        IF MEMBER_IDX <= 5 THEN
          :NEW.TK_DISCOUNT := :NEW.TK_DISCOUNT + 0.1;
        END IF;
      END IF;
    END IF;
  END IF;

  -- CALCULATE THE TICKET PRICE AFTER DISCOUNT
  :NEW.TK_PRICE := :NEW.TK_PRICE - (:NEW.TK_PRICE * :NEW.TK_DISCOUNT);

END;
/

