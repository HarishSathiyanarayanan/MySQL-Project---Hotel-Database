CREATE TABLE Guest
(
Guest_ID INTEGER AUTO_INCREMENT NOT NULL,
F_Name VARCHAR(25) NOT NULL,
L_Name VARCHAR(25) NOT NULL,
AGE INTEGER NOT NULL,
Email_ID VARCHAR(40) NOT NULL,
Phone VARCHAR(20) NOT NULL,
Platinum_Member VARCHAR(3) NOT NULL,
CONSTRAINT PK_Guest PRIMARY KEY (Guest_ID)
)AUTO_INCREMENT = 101;

CREATE TABLE Reservation
(
    Res_no INTEGER AUTO_INCREMENT NOT NULL,
    Guest_ID INTEGER NOT NULL,
    Checkin_Dt DATE NOT NULL,
    Checkout_Dt DATE NOT NULL,
    No_of_Nights INTEGER GENERATED ALWAYS AS (DATEDIFF(Checkout_Dt, Checkin_Dt)) STORED,
    Res_Status VARCHAR(50) NOT NULL,
    No_of_Guests INTEGER NOT NULL,
    No_of_TP_Tickets INTEGER NOT NULL,
    Res_Date DATE NOT NULL,
    CONSTRAINT PK_Reservation PRIMARY KEY (Res_no),
    CONSTRAINT FK_Reservation FOREIGN KEY (Guest_ID) REFERENCES Guest(Guest_ID)
) AUTO_INCREMENT = 10025;


Create TABLE Rooms
(
Room_No INTEGER NOT NULL,
Res_No INTEGER NOT NULL,
Room_Category VARCHAR(30) NOT NULL,
Room_Type VARCHAR(30) NOT NULL,
Room_View VARCHAR(30) NOT NULL,
Breakfast VARCHAR(5) NOT NULL,
Room_Rate VARCHAR(15) NOT NULL,
CONSTRAINT PK_Rooms PRIMARY KEY (Room_No),
CONSTRAINT FK_Rooms FOREIGN KEY (Res_No) REFERENCES Reservation (Res_No)
);

CREATE TABLE Pricing
(
Pricing_ID INTEGER AUTO_INCREMENT NOT NULL,
Discount_Code VARCHAR(4) NOT NULL,
Discount_Type VARCHAR(35) NOT NULL,
Discount_percent INTEGER NOT NULL,
Theme_Park_Price INTEGER NOT NULL,
Room_Tax_Rate INTEGER NOT NULL,
TP_Ticket_Tax_Rate INTEGER NOT NULL,
CONSTRAINT PK_Pricing PRIMARY KEY (Pricing_ID)
)AUTO_INCREMENT = 1;

CREATE TABLE Payment
(
Pmt_ID INTEGER AUTO_INCREMENT NOT NULL,
Res_No INTEGER NOT NULL,
Pricing_ID INTEGER NOT NULL,
Pmt_Method VARCHAR(35) NOT NULL,
Card_Number VARCHAR(16) NOT NULL,
Type_of_Card VARCHAR(16) NOT NULL,
Name_on_Card VARCHAR(50) NOT NULL,
Exp_Date VARCHAR(7) NOT NULL,
Pmt_Status VARCHAR(20) NOT NULL,
CONSTRAINT PK_Payment PRIMARY KEY (Pmt_ID),
CONSTRAINT FK_Payment FOREIGN KEY (Res_No) REFERENCES Reservation (Res_No),
CONSTRAINT FK2_Payment FOREIGN KEY (Pricing_ID) REFERENCES Pricing (Pricing_ID)
)AUTO_INCREMENT = 130045;



/* Create indices for natural keys, foreign keys, and frequently-queried columns */
-- Guest
-- Natural keys
CREATE INDEX IDX_Guest_FName ON Guest (F_Name);
-- Frequently-queried columns
CREATE INDEX IDX_Guest_Age ON Guest (Age);
CREATE INDEX IDX_Guest_Platinum_Membership ON Guest (Platinum_Member);
-- Reservation
-- Frequently-queried columns
CREATE INDEX IDX_Reservation_No_of_Nights ON Reservation (No_of_Nights);
CREATE INDEX IDX_Reservation_No_of_TP_Tickets ON Reservation (No_of_TP_Tickets);
-- Foreign Key
CREATE INDEX IDX_Guest_ID ON Reservation (Guest_ID);
-- Rooms
-- Frequently-queried columns
CREATE INDEX IDX_Room_View ON Rooms (Room_View);
CREATE INDEX IDX_Room_Rate ON Rooms (Room_Rate);
-- Pricing
-- Frequently-queried columns
CREATE INDEX IDX_Pricing_Discount ON Pricing (Discount_percent);
CREATE INDEX IDX_Pricing_Discount_Type ON Pricing (Discount_Type);
-- Payment
-- Natural keys
CREATE INDEX IDX_Payment_Name_on_Card ON Payment (Name_on_Card);
-- Frequently-queried columns
CREATE INDEX IDX_Payment_Card_number ON Payment (Card_Number);
-- Foreign Keys
CREATE INDEX IDX_Payment_Res_No ON Payment (Res_No);
CREATE INDEX IDX_Paymnet_Pricing_ID ON Payment (Pricing_ID);

/* Alter Tables by adding Audit Columns */

ALTER TABLE Guest
ADD (
created_by VARCHAR(30), date_created DATE, modified_by VARCHAR(30), date_modified DATE
);

ALTER TABLE Reservation
ADD (
created_by VARCHAR(30), date_created DATE, modified_by VARCHAR(30), date_modified DATE
);

ALTER TABLE Rooms
ADD (
created_by VARCHAR(30), date_created DATE, modified_by VARCHAR(30), date_modified DATE
);

ALTER TABLE Pricing
ADD (
created_by VARCHAR(30), date_created DATE, modified_by VARCHAR(30), date_modified DATE
);

ALTER TABLE Payment
ADD (
created_by VARCHAR(30), date_created DATE, modified_by VARCHAR(30), date_modified DATE
);

/* Create Views */
-- Business purpose: The GuestInfo view will be used primarily for quickly searching information about individual guests for populating their Age and whether they are a Platinum member or not for computing discounts.
CREATE OR REPLACE VIEW GuestInfo AS
SELECT Guest_ID, F_Name, L_Name, Age, Platinum_Member
FROM Guest;
-- Business purpose: The ReservationInfo view will be used primarily for quickly searching information about individual guests for populating the number of theme park tickets they purchased and the number of nights they would be staying at the hotel to compute the payment amount for them
CREATE OR REPLACE VIEW ReservationInfo AS
SELECT Res_no, Guest_ID, No_of_Nights,No_of_TP_Tickets
FROM Reservation;
-- Business purpose: The RoomsInfo view will be used primarily for quickly searching about individual guests for populating the room type and room view and the price of the room
CREATE OR REPLACE VIEW RoomsInfo AS
SELECT Room_No, Room_Category, Room_Type, Room_View, Room_Rate
FROM Rooms;
-- Business purpose: The PricingInfo view will be used primarily for quickly searching information about the Discount Code and Discount Type to derive the Pricing_ID.
CREATE OR REPLACE VIEW PricingInfo AS
SELECT Pricing_ID, Discount_Type, Discount_percent
FROM Pricing;
-- Business purpose: The PaymentInfo view will be used primarily for quickly searching information about the name of card holder and respective Pmt_ID and Res_No associated with it.
CREATE OR REPLACE VIEW PaymentInfo AS
SELECT Pmt_ID, Res_No, Name_on_Card
FROM Payment;
/* Create Triggers */
-- Business purpose: The TR_Guest trigger automatically assigns a sequential Guest ID to a newly-inserted row in the Guest table, assigning appropriate values to the created_by and date_created fields. If the record is being inserted or updated, appropriate values are assigned to the modified_by and modified_date fields.
DELIMITER //
CREATE TRIGGER TR_Guest BEFORE INSERT ON Guest
FOR EACH ROW
BEGIN
    IF NEW.Guest_ID IS NULL THEN
        SET NEW.Guest_ID = (SELECT AUTO_INCREMENT FROM information_schema.TABLES WHERE TABLE_NAME = 'Guest' AND TABLE_SCHEMA = DATABASE()) + 1;
    END IF;
    
    IF NEW.created_by IS NULL THEN
        SET NEW.created_by = USER();
    END IF;
    
    IF NEW.date_created IS NULL THEN
        SET NEW.date_created = NOW();
    END IF;

    SET NEW.modified_by = USER();
    SET NEW.date_modified = NOW();
END;
//
DELIMITER ;
-- Business purpose: The TR_Res trigger automatically assigns a sequential Reservation Number to a newly-inserted row in the Reservation table, assigning appropriate values to the created_by and date_created fields. If the record is being inserted or updated, appropriate values are assigned to the modified_by and modified_date fields.
DELIMITER //

CREATE TRIGGER TR_Res
BEFORE INSERT ON Reservation FOR EACH ROW
BEGIN
    IF NEW.Res_No IS NULL THEN
        SET NEW.Res_No = (SELECT NEXTVAL('SEQ_Res_No'));
    END IF;
    
    IF NEW.created_by IS NULL THEN
        SET NEW.created_by = CURRENT_USER();
    END IF;
    
    IF NEW.date_created IS NULL THEN
        SET NEW.date_created = NOW();
    END IF;

    SET NEW.modified_by = CURRENT_USER();
    SET NEW.date_modified = NOW();
END;
//

DELIMITER ;
-- Business purpose: The TR_Rooms trigger automatically assigns appropriate values to the created_by and date_created fields. If the record is being inserted or updated, appropriate values are assigned to the modified_by and modified_date fields.
DELIMITER //

CREATE TRIGGER TR_Rooms
BEFORE INSERT ON Rooms FOR EACH ROW
BEGIN
    IF NEW.created_by IS NULL THEN
        SET NEW.created_by = CURRENT_USER();
    END IF;
    
    IF NEW.date_created IS NULL THEN
        SET NEW.date_created = NOW();
    END IF;

    SET NEW.modified_by = CURRENT_USER();
    SET NEW.date_modified = NOW();
END;
//

DELIMITER ;
-- Business purpose: The TR_Pricing trigger automatically assigns a sequential Pricing ID to a newly-inserted row in the Pricing table, assigning appropriate values to the created_by and date_created fields. If the record is being inserted or updated, appropriate values are assigned to the modified_by and modified_date fields.
DELIMITER //

CREATE TRIGGER TR_Pricing
BEFORE INSERT ON Pricing FOR EACH ROW
BEGIN
    IF NEW.Pricing_ID IS NULL THEN
        SET NEW.Pricing_ID = (SELECT NEXTVAL('SEQ_Pricing_ID'));
    END IF;
    
    IF NEW.created_by IS NULL THEN
        SET NEW.created_by = CURRENT_USER();
    END IF;
    
    IF NEW.date_created IS NULL THEN
        SET NEW.date_created = NOW();
    END IF;

    SET NEW.modified_by = CURRENT_USER();
    SET NEW.date_modified = NOW();
END;
//

DELIMITER ;

-- Business purpose: The TR_Payment trigger automatically assigns a sequential Pmt ID to a newly-inserted row in the Payment table, assigning appropriate values to the created_by and date_created fields. If the record is being inserted or updated, appropriate values are assigned to the modified_by and modified_date fields.
DELIMITER //

CREATE TRIGGER TR_Payment
BEFORE INSERT ON Payment FOR EACH ROW
BEGIN
    IF NEW.Pmt_ID IS NULL THEN
        SET NEW.Pmt_ID = (SELECT NEXTVAL('SEQ_Pmt_ID'));
    END IF;
    
    IF NEW.created_by IS NULL THEN
        SET NEW.created_by = CURRENT_USER();
    END IF;
    
    IF NEW.date_created IS NULL THEN
        SET NEW.date_created = NOW();
    END IF;

    SET NEW.modified_by = CURRENT_USER();
    SET NEW.date_modified = NOW();
END;
//

DELIMITER ;

/* Populate all tables */
-- Guest table
INSERT INTO Guest (F_Name, L_Name, Age, Email_ID, Phone, Platinum_Member)
VALUES ('Gasan', 'Elkhodari', 42, 'gasan.elkhodari@utdallas.edu', '(972)883-4779', 'Yes');
INSERT INTO Guest (F_Name, L_Name, Age, Email_ID, Phone, Platinum_Member)
VALUES ('Sai Suma', 'Maguluri', 24, 'saisuma.maguluri@utdallas.edu', '(972)883-2705', 'Yes');
INSERT INTO Guest (F_Name, L_Name, Age, Email_ID, Phone, Platinum_Member)
VALUES ('John', 'Doe', 69, 'john.doe@gmail.com', '(469)850-5189', 'No');
INSERT INTO Guest (F_Name, L_Name, Age, Email_ID, Phone, Platinum_Member)
VALUES ('Jacob', 'Foster', 31, 'jacob.foster@gmail.com', '(214)573-7890', 'Yes');
INSERT INTO Guest (F_Name, L_Name, Age, Email_ID, Phone, Platinum_Member)
VALUES ('John', 'Smith', 26,'john.smith@yahoo.com', '(469)650-9879', 'No');
INSERT INTO Guest (F_Name, L_Name, Age, Email_ID, Phone, Platinum_Member)
VALUES ('Andrea', 'Jones', 55, 'andreajones@hotmail.com', '(630)639-2914', 'No');
INSERT INTO Guest (F_Name, L_Name, Age, Email_ID, Phone, Platinum_Member)
VALUES ('Taylor', 'Anderson', 74,'taylor.anderson@gmail.com', '(469)879-0770', 'No');
INSERT INTO Guest (F_Name, L_Name, Age, Email_ID, Phone, Platinum_Member)
VALUES ('Aman', 'Sharma', 23,'sharmaaman@yahoo.com', '(847)245-0990', 'Yes');
INSERT INTO Guest (F_Name, L_Name, Age, Email_ID, Phone, Platinum_Member)
VALUES ('Kyle', 'Cunningham', 45,'cunninghamk@gmail.com', '(202)230-8970', 'Yes');
INSERT INTO Guest (F_Name, L_Name, Age, Email_ID, Phone, Platinum_Member)
VALUES ('Mehnaz', 'Mahmood', 51, 'mmahmood@yahoo.com', '(449)517-9809', 'No');

-- Reservation table
INSERT INTO Reservation (Guest_ID, Checkin_Dt, Checkout_Dt, Res_Status, No_of_Guests, No_of_TP_Tickets, Res_Date)
VALUES (101, '2022-10-24', '2022-10-27', 'Confirmed', 1, 0, '2022-10-14');
INSERT INTO Reservation (Guest_ID, Checkin_Dt, Checkout_Dt, Res_Status, No_of_Guests, No_of_TP_Tickets, Res_Date)
VALUES (102, '2022-09-29', '2022-10-03', 'Confirmed', 5, 5, '2022-09-10');
INSERT INTO Reservation (Guest_ID, Checkin_Dt, Checkout_Dt, Res_Status, No_of_Guests, No_of_TP_Tickets, Res_Date)
VALUES (103, '2022-10-21', '2022-10-26', 'Confirmed', 4, 4, '2022-10-11');
INSERT INTO Reservation (Guest_ID, Checkin_Dt, Checkout_Dt, Res_Status, No_of_Guests, No_of_TP_Tickets, Res_Date)
VALUES (104, '2022-11-14', '2022-11-19', 'Confirmed', 2, 2, '2022-10-30');
INSERT INTO Reservation (Guest_ID, Checkin_Dt, Checkout_Dt, Res_Status, No_of_Guests, No_of_TP_Tickets, Res_Date)
VALUES (105, '2022-11-27', '2022-12-01', 'Confirmed', 2, 2, '2022-11-20');
INSERT INTO Reservation (Guest_ID, Checkin_Dt, Checkout_Dt, Res_Status, No_of_Guests, No_of_TP_Tickets, Res_Date)
VALUES (106, '2022-12-08', '2022-12-12', 'Confirmed', 2, 2, '2022-11-15');
INSERT INTO Reservation (Guest_ID, Checkin_Dt, Checkout_Dt, Res_Status, No_of_Guests, No_of_TP_Tickets, Res_Date)
VALUES (107, '2022-12-12', '2022-12-15', 'Confirmed', 3, 2, '2022-11-10');
INSERT INTO Reservation (Guest_ID, Checkin_Dt, Checkout_Dt, Res_Status, No_of_Guests, No_of_TP_Tickets, Res_Date)
VALUES (108, '2022-12-15', '2022-12-18', 'Waiting_for_Room Availability', 4, 3, '2022-11-14');
INSERT INTO Reservation (Guest_ID, Checkin_Dt, Checkout_Dt, Res_Status, No_of_Guests, No_of_TP_Tickets, Res_Date)
VALUES (109, '2022-12-23', '2022-12-25', 'Waiting_for_Room Availability', 3, 3, '2022-11-22');
INSERT INTO Reservation (Guest_ID, Checkin_Dt, Checkout_Dt, Res_Status, No_of_Guests, No_of_TP_Tickets, Res_Date)
VALUES (110, '2022-12-25', '2022-12-30', 'Waiting_for_Room Availability', 2, 2, '2022-12-15');

-- Rooms Table
INSERT INTO Rooms (Room_No, Res_No, Room_Category, Room_Type, Room_View, Breakfast, Room_Rate)
VALUES ('401', '10025', 'Standard King', 'Non-Smoking', 'Street View', 'No', '$160');
INSERT INTO Rooms(Room_No, Res_No, Room_Category, Room_Type, Room_View, Breakfast, Room_Rate)
VALUES('302', '10026', 'Standard Queen', 'Smoking', 'Themepark View', 'Yes', '$170');
INSERT INTO Rooms(Room_No, Res_No, Room_Category, Room_Type, Room_View, Breakfast, Room_Rate)
VALUES('203', '10027', 'Standard Twin', 'Non-Smoking', 'Pool View', 'Yes', '$140');
INSERT INTO Rooms(Room_No, Res_No, Room_Category, Room_Type, Room_View, Breakfast, Room_Rate)
VALUES('504', '10028', 'Executive Suite', 'Smoking', 'Pool View', 'Yes', '$225');
INSERT INTO Rooms(Room_No, Res_No, Room_Category, Room_Type, Room_View, Breakfast, Room_Rate)
VALUES('305', '10029', 'Standard Queen', 'Smoking', 'Pool View', 'Yes', '$165');
INSERT INTO Rooms(Room_No, Res_No, Room_Category, Room_Type, Room_View, Breakfast, Room_Rate)
VALUES('206', '10030', 'Standard Twin', 'Non-Smoking', 'Themepark View', 'No', '$135');
INSERT INTO Rooms(Room_No, Res_No, Room_Category, Room_Type, Room_View, Breakfast, Room_Rate)
VALUES('507', '10031', 'Executive Suite', 'Smoking', 'Themepark View', 'Yes', '$230');
INSERT INTO Rooms(Room_No, Res_No, Room_Category, Room_Type, Room_View, Breakfast, Room_Rate)
VALUES('408', '10032', 'Standard King', 'Smoking', 'Garden View', 'Yes', '$180');
INSERT INTO Rooms(Room_No, Res_No, Room_Category, Room_Type, Room_View, Breakfast, Room_Rate)
VALUES('209', '10033', 'Standard Twin', 'Non-Smoking', 'Pool View', 'Yes', '$140');
INSERT INTO Rooms(Room_No, Res_No, Room_Category, Room_Type, Room_View, Breakfast, Room_Rate)
VALUES('510', '10034', 'Executive Suite', 'Smoking', 'Themepark View', 'Yes', '$230');

-- Pricing Table
INSERT INTO Pricing (Discount_Code, Discount_Type, Discount_percent, Theme_Park_Price, Room_Tax_Rate, TP_Ticket_Tax_Rate)
VALUES ('EB', 'Early Bird', 10, 55, 13, 8.25);
INSERT INTO Pricing (Discount_Code, Discount_Type, Discount_percent, Theme_Park_Price, Room_Tax_Rate, TP_Ticket_Tax_Rate)
VALUES ('RT', 'Room Theme Park Combo', 20, 55, 13, 8.25);
INSERT INTO Pricing (Discount_Code, Discount_Type, Discount_percent, Theme_Park_Price, Room_Tax_Rate, TP_Ticket_Tax_Rate)
VALUES ('SC', 'Senior Citizen Discount', 10, 55, 13, 8.25);
INSERT INTO Pricing (Discount_Code, Discount_Type, Discount_percent, Theme_Park_Price, Room_Tax_Rate, TP_Ticket_Tax_Rate)
VALUES ('PM', 'Platinum Member', 15, 55, 13, 8.25);
INSERT INTO Pricing (Discount_Code, Discount_Type, Discount_percent, Theme_Park_Price, Room_Tax_Rate, TP_Ticket_Tax_Rate)
VALUES ('T3', 'More than 2 Theme Park Tickets', 5, 55, 13, 8.25);
INSERT INTO Pricing (Discount_Code, Discount_Type, Discount_percent, Theme_Park_Price, Room_Tax_Rate, TP_Ticket_Tax_Rate)
VALUES ('EXEM', 'Tax Exempt', 0, 55, 0, 0);
INSERT INTO Pricing (Discount_Code, Discount_Type, Discount_percent, Theme_Park_Price, Room_Tax_Rate, TP_Ticket_Tax_Rate)
VALUES ('VET', 'Veteran', 7, 55, 13, 8.25);
INSERT INTO Pricing (Discount_Code, Discount_Type, Discount_percent, Theme_Park_Price, Room_Tax_Rate, TP_Ticket_Tax_Rate)
VALUES ('RES', 'Local Texas Resident', 2, 55, 13, 8.25);
INSERT INTO Pricing (Discount_Code, Discount_Type, Discount_percent, Theme_Park_Price, Room_Tax_Rate, TP_Ticket_Tax_Rate)
VALUES ('RSF', 'Room Service Food Order', 2, 55, 13, 8.25);
INSERT INTO Pricing (Discount_Code, Discount_Type, Discount_percent, Theme_Park_Price, Room_Tax_Rate, TP_Ticket_Tax_Rate)
VALUES ('CS', 'College Student', 3, 55, 13, 8.25);

-- Payment table
INSERT INTO Payment (Res_No, Pricing_ID, Pmt_Method, Card_Number, Type_of_Card, Name_on_Card, Exp_Date, Pmt_Status)
VALUES (10025,6,'Credit Card','4044120045673450','Visa','Gasan Elkhodari','04/2026','Paid');
INSERT INTO Payment (Res_No, Pricing_ID, Pmt_Method, Card_Number, Type_of_Card, Name_on_Card, Exp_Date, Pmt_Status)
VALUES (10026,2,'Debit Card','5002341245783458','Mastercard','Sai Suma Maguluri','05/2025','Paid');
INSERT INTO Payment (Res_No, Pricing_ID, Pmt_Method, Card_Number, Type_of_Card, Name_on_Card, Exp_Date, Pmt_Status)
VALUES (10027,2,'Credit Card','4232456789762345','Visa','John Doe','04/2023','Paid');
INSERT INTO Payment (Res_No, Pricing_ID, Pmt_Method, Card_Number, Type_of_Card, Name_on_Card, Exp_Date, Pmt_Status)
VALUES (10028,2,'Credit Card','4908789067534573','Visa','Jacob Foster','09/2026','Balance Due');
INSERT INTO Payment (Res_No, Pricing_ID, Pmt_Method, Card_Number, Type_of_Card, Name_on_Card, Exp_Date, Pmt_Status)
VALUES (10029,2,'Credit Card','5590898765456723','Mastercard','John Smith','07/2025','Balance Due');
INSERT INTO Payment (Res_No, Pricing_ID, Pmt_Method, Card_Number, Type_of_Card, Name_on_Card, Exp_Date, Pmt_Status)
VALUES (10030,2,'Credit Card','4890654323455789','Visa','Andrea Jones','12/2026','Balance Due');
INSERT INTO Payment (Res_No, Pricing_ID, Pmt_Method, Card_Number, Type_of_Card, Name_on_Card, Exp_Date, Pmt_Status)
VALUES (10031,2,'Credit Card','4509897654231257','Visa','Taylor Anderson','11/2025','Balance Due');
INSERT INTO Payment (Res_No, Pricing_ID, Pmt_Method, Card_Number, Type_of_Card, Name_on_Card, Exp_Date, Pmt_Status)
VALUES (10032,2,'Credit Card','4123578974562345','Visa','Aman Sharma','03/2024','Balance Due');
INSERT INTO Payment (Res_No, Pricing_ID, Pmt_Method, Card_Number, Type_of_Card, Name_on_Card, Exp_Date, Pmt_Status)
VALUES (10033,2,'Debit Card','4678657089234452','Visa','Kyle Cunningham','05/2024','Balance Due');
INSERT INTO Payment (Res_No, Pricing_ID, Pmt_Method, Card_Number, Type_of_Card, Name_on_Card, Exp_Date, Pmt_Status)
VALUES (10034,2,'Credit Card','5890786543218764','Mastercard','Mehnaz Mahmood','12/2023','Balance Due');
