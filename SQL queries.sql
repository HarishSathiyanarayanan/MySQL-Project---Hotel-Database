-- 20 SQL Queries
-- Q1. Select all columns and all rows from one table
SELECT * FROM Guest;
-- Q2. Select five columns and all rows from one table
SELECT Room_Category, Room_View, Room_Type, Breakfast, Room_Rate FROM Rooms;
-- Q3. Select all columns from all rows from one view
SELECT * FROM ReservationInfo;
-- Q4. Using a join on 2 tables, select all columns and all rows
SELECT * FROM Reservation
LEFT OUTER JOIN Guest ON Reservation.Guest_ID = Guest.Guest_ID;
-- Q5. Select and order data retrieved from one table
SELECT * FROM Rooms
ORDER BY Room_No;
-- Q6. Using a join on 3 tables, select 5 columns from the 3 tables. Use syntax that would limit the output to 10 rows
SELECT Guest.F_Name, Guest.L_Name, Reservation.Res_Status, Rooms.Room_Type, Rooms.Room_Rate
FROM Reservation
INNER JOIN Guest ON Reservation.Guest_ID = Guest.Guest_ID
INNER JOIN Rooms ON Rooms.Res_No = Reservation.Res_No
LIMIT 10;
-- Q7. Select distinct rows using joins on 3 tables
SELECT DISTINCT Rooms.Room_Category, Rooms.Room_View, Rooms.Room_Type, Rooms.Room_Rate, Payment.Pricing_ID
FROM Rooms
INNER JOIN Reservation ON Rooms.Res_no = Reservation.Res_no
INNER JOIN Payment ON Reservation.Res_no = Payment.Res_no;
-- Q8. Use GROUP BY and HAVING in a select statement using one or more tables
SELECT Room_Category, Room_View, Room_Type, Breakfast, Room_Rate
FROM Rooms
GROUP BY Room_Rate, Room_Category, Room_View, Room_Type, Breakfast
HAVING Room_View = 'Themepark View'
ORDER BY Room_Rate;
-- Q9.Use IN clause to select data from one or more tables
SELECT * FROM Pricing
WHERE Discount_percent IN (10,15,20);
-- Q10.Select length of one column from one table
SELECT L_Name, Length(L_Name) from Guest;
-- Q11.Delete one record from one table. Use select statements to demonstrate the table contents before and after the DELETE statement. Make sure you use ROLLBACK afterwards so that the data will not be physically removed
COMMIT;
SELECT * FROM Payment;
DELETE FROM Payment WHERE Pricing_ID = 6;
SELECT * FROM Payment;
ROLLBACK;
-- Q12.Update one record from one table. Use select statements to demonstrate the table contents before and after the UPDATE statement. Make sure you use ROLLBACK afterwards so that the data will not be physically removed
START TRANSACTION;
-- Your UPDATE statement
UPDATE Pricing
SET Discount_Type = 'Military Service Discount'
WHERE Pricing_ID = '7';
-- Optionally, you can SELECT to verify changes
SELECT * FROM Pricing WHERE Pricing_ID = '7';
SELECT * FROM Pricing;
-- If everything is correct, you can COMMIT the changes
COMMIT;
-- If there's an issue and you want to discard changes, you can ROLLBACK
ROLLBACK;
-- Q13. List all guests whose Reservation is in Confirmed Status. List their IDs, Reservation Number, First Name, Last Name, Room Number, Payment Status and Reservation Status
SELECT Guest.Guest_ID, Reservation.Res_No, Guest.F_Name, Guest.L_Name, Rooms.Room_No, Payment.Pmt_Status, Reservation.Res_Status
FROM Reservation
INNER JOIN Rooms ON Rooms.Res_No = Reservation.Res_No
INNER JOIN Guest ON Guest.Guest_ID = Reservation.Guest_ID
INNER JOIN Payment ON Reservation.Res_No = Payment.Res_No
WHERE Reservation.Res_Status = 'Confirmed';
-- Q14. Write a query to assist the front desk in order to prepare a list of all guests whose room rate is at least $180. The front desk would like to leave a small complimentary gift with a customized note in their room. Display their Room Number, First Name, Last Name, Room Rate, Payment Status
SELECT Rooms.Room_No, Guest.F_Name, Guest.L_Name, Rooms.Room_Rate, Payment.Pmt_Status from Rooms
INNER JOIN Reservation ON Rooms.Res_No = Reservation.Res_No
INNER JOIN Payment ON Reservation.Res_No = payment.Res_No
INNER JOIN Guest on Guest.Guest_ID = Reservation.Guest_ID
WHERE Rooms.Room_Rate >= '$180'
ORDER BY Rooms.Room_No;
-- Q15. Hotel DBF 12's Marketing Team reached out to get a list of most popular room categories that get booked the most. Write a query to assist the marketing team. List the Room Category and the Count of the Ones that get booked the most.
SELECT q1.Room_Category, q1.num_occurrences
FROM (
SELECT Rooms.Room_Category, COUNT(*) AS num_occurrences
FROM Rooms
GROUP BY Rooms.Room_Category
) q1, (
SELECT MAX(q2.num_occurrences) AS max_occurrences
FROM (
SELECT Rooms.Room_Category, COUNT(*) AS num_occurrences
FROM Rooms
GROUP BY Rooms.Room_Category
) q2
) q3
WHERE q1.num_occurrences = q3.max_occurrences;
-- Q16. List all reservations where the Room Theme Park Combo Discount has been applied and a Mastercard will be used for Payment
SELECT Reservation.Res_No, Guest.F_Name, Guest.L_Name, Reservation.Res_Status, Payment.Type_of_Card, Pricing.Discount_Code
FROM Guest
INNER JOIN Reservation ON Guest.Guest_ID = Reservation.Guest_ID
INNER JOIN Payment ON Reservation.Res_no = Payment.Res_No
INNER JOIN Pricing on Payment.Pricing_ID = Pricing.Pricing_ID
WHERE Payment.Type_Of_Card = 'Mastercard'
AND Pricing.Discount_Code = 'RT'
ORDER BY Res_No;
-- Q17. List all the platinum members who have made reservation for atleast 3 people and have purchased at least 2 Theme Park tickets
Select Guest.Guest_ID, Guest.F_Name, Guest.L_Name, Reservation.No_of_Guests, Reservation.No_of_TP_Tickets, Guest.Platinum_Member
FROM Guest
INNER JOIN Reservation ON Guest.Guest_ID = Reservation.Guest_ID
WHERE Guest.Platinum_Member = 'Yes'
AND Reservation.No_of_Guests >= 3
AND Reservation.No_of_TP_Tickets >= 2
ORDER BY Guest_ID;
-- Q18. Write a query to assist the front desk staff of DBF 12 to calculate room total, theme park total and final amt before and after discount for all the hotel guests.
CREATE TABLE payment_temp AS
SELECT 
    a.*,
    (b.No_of_Nights) * CAST(SUBSTRING(c.Room_Rate, 2, 3) AS DECIMAL) AS room_total,
    (b.No_of_TP_Tickets * d.Theme_Park_Price) AS Theme_park_total
FROM 
    payment a 
    LEFT OUTER JOIN reservation b ON a.RES_NO = b.RES_NO
    LEFT OUTER JOIN rooms c ON b.RES_NO = c.RES_NO
    LEFT OUTER JOIN pricing d ON a.pricing_id = d.pricing_id;

SELECT 
    a.PMT_ID,
    a.RES_NO,
    a.PRICING_ID,
    a.ROOM_TOTAL,
    a.THEME_PARK_TOTAL,
    Room_Tax_Rate,
    TP_Ticket_Tax_Rate,
    (a.room_total * (1 + (b.Room_Tax_Rate / 100))) + (a.Theme_park_total * (1 + (b.TP_Ticket_Tax_Rate / 100))) AS final_amt_bef_disc,
    ((a.room_total * (1 + (b.Room_Tax_Rate / 100))) + (a.Theme_park_total * (1 + (b.TP_Ticket_Tax_Rate / 100)))) * (1 - (b.Discount_percent / 100)) AS final_amt_after_disc
FROM 
    payment_temp a 
    LEFT OUTER JOIN pricing b ON a.pricing_id = b.pricing_id;
-- Q19. One of the hotel guest Mr. Gasan Elkhodari showed up to the hotel front desk with a tax exempt certificate mentioning that the purpose of his stay at the hotel is for attending a conference nearby and as a state employee of University of Texas at Dallas, he should be exempted from taxes. Please write a query to assist the front desk staff for calculating Room total for Mr. Elkhodari and more guests like him in the future who would present a valid tax exempt certificate to the hotel front desk.
SELECT A.res_no, A.f_name, A.l_name, B.discount_code, A.room_rate, B.room_total
FROM (
    SELECT *
    FROM (
        SELECT guest.guest_id AS g1_id, guest.f_name, guest.l_name
        FROM guest
        JOIN reservation ON guest.guest_id = reservation.guest_id
    ) AS A1,
    (
        SELECT reservation.guest_id AS g2_id, reservation.res_no, rooms.room_rate
        FROM reservation
        JOIN rooms ON reservation.res_no = rooms.res_no
    ) AS A2
    WHERE A1.g1_id = A2.g2_id
) AS A,
(
    SELECT T.res_no, pt.room_total, T.discount_code
    FROM payment_temp AS pt,
    (
        SELECT pricing_id, res_no, discount_code
        FROM (
            SELECT res_no, discount_code, pricing_id
            FROM pricing
            JOIN (
                SELECT reservation.res_no, pricing_id AS res_pid
                FROM reservation, payment
                WHERE reservation.res_no = payment.res_no
            ) AS P1 ON res_pid = pricing_id
        ) AS P2
        WHERE discount_code = 'EXEM'
    ) AS T
    WHERE pt.res_no = T.res_no
) AS B
WHERE A.res_no = B.res_no;
-- Q20. For people who availed Room theme park combo, find out how many platinum members are spending more than the average amount
create table payment_temp1 as
select a.*,Room_Tax_Rate,TP_Ticket_Tax_Rate,(a.room_total * (1+(b.Room_Tax_Rate/100)))+(a.Theme_park_total*(1+(b.TP_Ticket_Tax_Rate/100))) as final_amt_bef_disc,
((a.room_total * (1+(b.Room_Tax_Rate/100)))+(a.Theme_park_total*(1+(b.TP_Ticket_Tax_Rate/100))))*(1 - (b.Discount_percent/100)) as final_amt_after_disc
from payment_temp a left outer join pricing b
on a.pricing_id = b.pricing_id;
select a.platinum_member,count(a.guest_id) as COUNT_OF_CUSTOMERS_WHO_SPEND_ABOVE_AVERAGE
from guest a left outer join reservation b
on a.guest_id = b.guest_id
left outer join payment_temp1 c
on b.res_no = c.res_no
left outer join pricing d
on c.pricing_id = d.pricing_id
where d.discount_type = 'Room Theme Park Combo' AND
c.FINAL_AMT_AFTER_DISC > (select avg(FINAL_AMT_AFTER_DISC) from payment_temp1 where pricing_id in (select pricing_id from pricing where discount_type = 'Room Theme Park Combo'))
group by a.platinum_member;
DROP TABLE payment_temp;
DROP TABLE payment_temp1;