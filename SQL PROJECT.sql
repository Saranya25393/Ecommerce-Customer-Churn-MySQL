USE ecomm;

SET SQL_SAFE_UPDATES = 0;

-- Data Cleaning:
-- Handling Missing Values and Outliers:
-- IMPUTE MEAN
SELECT ROUND(AVG(WarehouseToHome)) FROM customer_churn;
SELECT ROUND(AVG(HourSpendOnApp)) FROM customer_churn;
SELECT ROUND(AVG(OrderAmountHikeFromlastYear)) FROM customer_churn;
SELECT ROUND(AVG(DaySinceLastOrder)) FROM customer_churn;

UPDATE customer_churn AS c
JOIN (
    SELECT ROUND(AVG(WarehouseToHome), 0) AS MeanWarehouseToHome
    FROM customer_churn
    WHERE WarehouseToHome IS NOT NULL
) AS avg_table ON 1=1
SET c.WarehouseToHome = avg_table.MeanWarehouseToHome
WHERE c.WarehouseToHome IS NULL;

UPDATE customer_churn AS c
JOIN (
    SELECT ROUND(AVG(HourSpendOnApp), 0) AS HourSpendOnApp
    FROM customer_churn
    WHERE HourSpendOnApp IS NOT NULL
) AS avg_table ON 1=1
SET c.HourSpendOnApp = avg_table.HourSpendOnApp
WHERE c.HourSpendOnApp IS NULL;

UPDATE customer_churn AS c
JOIN (
    SELECT ROUND(AVG(OrderAmountHikeFromlastYear), 0) AS OrderAmountHikeFromlastYear
    FROM customer_churn
    WHERE OrderAmountHikeFromlastYear IS NOT NULL
) AS avg_table ON 1=1
SET c.OrderAmountHikeFromlastYear = avg_table.OrderAmountHikeFromlastYear
WHERE c.OrderAmountHikeFromlastYear IS NULL;


UPDATE customer_churn AS c
JOIN (
    SELECT ROUND(AVG(DaySinceLastOrder), 0) AS DaySinceLastOrder
    FROM customer_churn
    WHERE DaySinceLastOrder IS NOT NULL
) AS avg_table ON 1=1
SET c.DaySinceLastOrder = avg_table.DaySinceLastOrder
WHERE c.DaySinceLastOrder IS NULL;

-- IMPUTE MODE
CREATE TEMPORARY TABLE TempTenureMode AS
SELECT Tenure
FROM customer_churn
WHERE Tenure IS NOT NULL
GROUP BY Tenure
ORDER BY COUNT(Tenure) DESC
LIMIT 1;

CREATE TEMPORARY TABLE TempCouponUsedMode AS
SELECT CouponUsed
FROM customer_churn
WHERE CouponUsed IS NOT NULL
GROUP BY CouponUsed
ORDER BY COUNT(CouponUsed) DESC
LIMIT 1;

CREATE TEMPORARY TABLE TempOrderCountMode AS
SELECT OrderCount
FROM customer_churn
WHERE OrderCount IS NOT NULL
GROUP BY OrderCount
ORDER BY COUNT(OrderCount) DESC
LIMIT 1;

UPDATE customer_churn
SET Tenure = (SELECT Tenure FROM TempTenureMode)
WHERE Tenure IS NULL;

UPDATE customer_churn
SET CouponUsed = (SELECT CouponUsed FROM TempCouponUsedMode)
WHERE CouponUsed IS NULL;

UPDATE customer_churn
SET OrderCount = (SELECT OrderCount FROM TempOrderCountMode)
WHERE OrderCount IS NULL;

DROP TEMPORARY TABLE IF EXISTS TempTenureMode;
DROP TEMPORARY TABLE IF EXISTS TempCouponUsedMode;
DROP TEMPORARY TABLE IF EXISTS TempOrderCountMode;

-- Dealing with Inconsistencies:
-- DELETE > 100
DELETE FROM customer_churn
WHERE WarehouseToHome > 100;

-- Update column
UPDATE customer_churn
SET PreferredLoginDevice = 'Mobile Phone'
WHERE PreferredLoginDevice = 'Phone';

UPDATE customer_churn
SET PreferedOrderCat = 'Mobile Phone'
WHERE PreferedOrderCat = 'Mobile';

UPDATE customer_churn
SET PreferredPaymentMode = 'Cash on Delivery'
WHERE PreferredPaymentMode = 'COD';

UPDATE customer_churn
SET PreferredPaymentMode = 'Credit Card'
WHERE PreferredPaymentMode = 'CC';

-- Data Transformation:
-- Column Renaming:
ALTER TABLE customer_churn
RENAME COLUMN PreferedOrderCat TO PreferredOrderCat;

ALTER TABLE customer_churn
RENAME COLUMN HourSpendOnApp TO HoursSpentOnApp;

-- Creating New Columns:
ALTER TABLE customer_churn
ADD ComplaintReceived VARCHAR(3);

UPDATE customer_churn
SET ComplaintReceived = CASE
    WHEN Complain = 1 THEN 'Yes'
    ELSE 'No'
END;

ALTER TABLE customer_churn
ADD COLUMN ChurnStatus VARCHAR(7);

UPDATE customer_churn
SET ChurnStatus = CASE
    WHEN Churn = 1 THEN 'Churned'
    ELSE 'Active'
END;

-- Column Dropping:
ALTER TABLE customer_churn
DROP COLUMN Churn,
DROP COLUMN Complain;

-- Data Exploration and Analysis:
SELECT ChurnStatus, COUNT(*) as CustomerCount
FROM customer_churn
GROUP BY ChurnStatus;

SELECT AVG(Tenure) as AverageTenure
FROM customer_churn
WHERE ChurnStatus = 'Churned';

SELECT SUM(CashbackAmount) AS TotalCashbackEarned
FROM customer_churn
WHERE 'Churn' = 1;

SELECT COUNT(*) AS TotalChurned,
SUM('Complain') AS ComplainedCount,
(SUM('Complain') / COUNT(*) * 100) AS PercentageComplained
FROM customer_churn
WHERE 'Churn' = 1;

SELECT gender, COUNT(*) AS number_of_complaints
FROM customer_churn
WHERE ComplaintReceived = 1
GROUP BY gender;

SELECT CityTier, COUNT(*) AS number_of_churned_customers
FROM customer_churn
WHERE ChurnStatus = 1
  AND PreferredOrderCat = 'Laptop & Accessory'
GROUP BY CityTier
ORDER BY number_of_churned_customers DESC
LIMIT 1;

SELECT PreferredPaymentMode, COUNT(*) AS number_of_active_customers
FROM customer_churn
WHERE ChurnStatus = 0
GROUP BY PreferredPaymentMode
ORDER BY number_of_active_customers DESC
LIMIT 1;

SELECT DISTINCT PreferredLoginDevice
FROM customer_churn
WHERE DaySinceLastOrder > 10;

SELECT COUNT(*) AS num_of_active_customers
FROM customer_churn
WHERE HoursSpentOnApp = 1
AND HoursSpentOnApp > 3;  

SELECT AVG(CashbackAmount) AS average_cashback
FROM customer_churn
WHERE HoursSpentOnApp >= 2;  

SELECT PreferredOrderCat, MAX(HoursSpentOnApp) AS max_hours_spent
FROM customer_churn
GROUP BY PreferredOrderCat;

SELECT MaritalStatus, AVG(OrderAmountHikeFromlastYear) AS AvgOrderAmountHike
FROM customer_churn
GROUP BY MaritalStatus;

SELECT SUM(OrderAmountHikeFromlastYear) AS Total_Order_Amount_Hike
FROM customer_churn
WHERE MaritalStatus = 'Single'
AND PreferredLoginDevice LIKE '%Mobile%';

SELECT AVG(NumberOfDeviceRegistered) AS avg_number_of_devices
FROM customer_churn
WHERE PreferredPaymentMode = 'UPI';

SELECT CityTier, COUNT(*) AS number_of_customers
FROM customer_churn
GROUP BY CityTier
ORDER BY number_of_customers DESC
LIMIT 1;

SELECT MaritalStatus
FROM customer_churn
ORDER BY NumberOfAddress DESC
LIMIT 1;

SELECT gender, SUM(CouponUsed) AS total_coupons
FROM customer_churn
GROUP BY gender
ORDER BY total_coupons DESC
LIMIT 1;

SELECT PreferredOrderCat, AVG(SatisfactionScore) AS average_satisfaction_score
FROM customer_churn
GROUP BY PreferredOrderCat;

SELECT SUM(OrderCount) AS Total_Order_Count
FROM customer_churn
WHERE PreferredPaymentMode = 'Credit Card'
  AND SatisfactionScore = (SELECT MAX(SatisfactionScore) FROM customer_churn);

SELECT COUNT(*) AS number_of_customers
FROM customer_churn
WHERE HoursSpentOnApp = 60
  AND DATEDIFF(CURDATE(), DaySinceLastOrder) > 5;
  
SELECT AVG(SatisfactionScore) AS average_satisfaction_score
FROM customer_churn
WHERE ComplaintReceived = 1;  

SELECT PreferredOrderCat, COUNT(*) AS number_of_customers
FROM customer_churn
GROUP BY PreferredOrderCat;

SELECT AVG(CashbackAmount) AS average_cashback
FROM customer_churn
WHERE MaritalStatus = 'Married';  
  
SELECT AVG(NumberOfDeviceRegistered) AS avg_number_of_devices
FROM customer_churn
WHERE PreferredLoginDevice <> 'Mobile Phone'; 

SELECT PreferredOrderCat
FROM customer_churn
WHERE CouponUsed > 5
GROUP BY PreferredOrderCat;
 
SELECT PreferredOrderCat, AVG(CashbackAmount) AS average_cashback
FROM customer_churn
GROUP BY PreferredOrderCat
ORDER BY average_cashback DESC;

SELECT PreferredPaymentMode
FROM customer_churn
GROUP BY PreferredPaymentMode
HAVING AVG(Tenure) = 10 AND SUM(OrderCount) > 500; 

SELECT
    CASE
        WHEN WarehouseToHome <= 5 THEN 'Very Close Distance'
        WHEN WarehouseToHome <= 10 THEN 'Close Distance'
        WHEN WarehouseToHome <= 15 THEN 'Moderate Distance'
        ELSE 'Far Distance'
    END AS distance_category,
    ChurnStatus,
    COUNT(*) AS count
FROM customer_churn
GROUP BY distance_category, ChurnStatus
ORDER BY distance_category, ChurnStatus;

SET @avg_order_count = (
    SELECT AVG(OrderCount) 
    FROM customer_churn
);
SELECT *
FROM customer_churn
WHERE MaritalStatus = 'Married'
  AND CityTier = '1'  
  AND OrderCount > @avg_order_count;

-- Create table
CREATE TABLE customer_returns (
    ReturnID INT PRIMARY KEY,
    CustomerID INT,
    ReturnDate DATE,
    RefundAmount DECIMAL(10, 2)
);

-- Insert table
INSERT INTO customer_returns (ReturnID, CustomerID, ReturnDate, RefundAmount)
VALUES
(1001, 50022, '2023-01-01', 2130.00),
(1002, 50316, '2023-01-23', 2000.00),
(1003, 51099, '2023-02-14', 2290.00),
(1004, 52321, '2023-03-08', 2510.00),
(1005, 52928, '2023-03-20', 3000.00),
(1006, 53749, '2023-04-17', 1740.00),
(1007, 54206, '2023-04-21', 3250.00),
(1008, 54838, '2023-04-30', 1990.00);

SELECT 
	cr.*,
    cc.Tenure,
    cc.PreferredLoginDevice,
    cc.CityTier,
    cc.WarehouseToHome,
    cc.PreferredPaymentMode,
    cc.Gender,
    cc.HoursSpentOnApp,
    cc.NumberOfDeviceRegistered,
    cc.PreferredOrderCat,
    cc.SatisfactionScore,
    cc.MaritalStatus,
    cc.NumberOfAddress,
    cc.OrderAmountHikeFromlastYear,
    cc.CouponUsed,
    cc.OrderCount,
    cc.DaySinceLastOrder,
    cc.CashbackAmount
FROM customer_returns cr
JOIN customer_churn cc
ON cc.CustomerID = cr.CustomerID
WHERE cc.ChurnStatus = 'Churned' AND cc.ComplaintReceived = 'Yes';

   

  
  














