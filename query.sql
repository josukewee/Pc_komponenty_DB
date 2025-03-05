# uvod do relacnich databazi
use pc_komponenty;

select * from country;






select * from shopping_cart_item;

SELECT uzivatel.jmeno_a_prijmeni, uzivatel.email, shopping_cart.id
FROM uzivatel left JOIN shopping_cart 
ON uzivatel.user_id = shopping_cart.user_id;




SELECT
    Country.CountryName,
    Region.RegionName,
    City.CityName
FROM
    City
INNER JOIN Region ON City.RegionID = Region.RegionID
INNER JOIN Country ON Region.CountryID = Country.CountryID;



SELECT product_name, price
FROM product
ORDER BY price DESC;

SELECT category_id, AVG(price) AS avg_price
FROM product
GROUP BY category_id
HAVING avg_price > 100;

SELECT product_name, price
FROM product
WHERE price <= 50;

CREATE VIEW expensive_products AS
SELECT product_name, price
FROM product
WHERE price > 100;

select * from expensive_products;

select * from shopping_cart_item;
select * from product_category;
select * from product;


--



use pc_komponenty;

select * from shopping_cart;

-- Avarage count of records from every table using meta information.
select AVG(table_rows) as avarage_rows
from information_schema.tables
where table_schema = "pc_komponenty" ;

select product_name, price 
from product
where product.product_id in (
	select shopping_cart_item.product_id
    from shopping_cart_item
    where shopping_cart_id = 1
);

select * from shopping_cart;
# select that will show count of product in each category and avarage price in this category 

select 
	c.category_id, c.category_name, count(p.product_id) as product_count, avg(p.price) as avarage_price
from
	product_category c
left join 
	product p on c.category_id = p.category_id
group by
	c.category_id, c.category_name;

# recursive query

with recursive category_hierarchy as
	(select category_id, category_name, parent_category_id, 1 as lvl
	from product_category where category_name = 'PC Komponenty'
	union
	select E.category_id, E.category_name, E.parent_category_id, lvl + 1 as lvl
	from category_hierarchy H
	join product_category E on H.category_id = E.parent_category_id
    )

select * from category_hierarchy;


select * from shopping_cart;
select * from shopping_cart_item;

-- Creating view with multiple joints
create view names_of_product_and_customer_name as
select U.jmeno_a_prijmeni, U.email, p.product_name, p.price
from uzivatel U
	inner join 
	shopping_cart sh
    on U.user_id = sh.user_id
    inner join
    shopping_cart_item shi
    on sh.id = shi.shopping_cart_id
    inner join
    product p
    on shi.product_id = p.product_id;

create fulltext index indx on product(product_name);

DROP FUNCTION IF EXISTS calculate_average_price;

-- Function that will count an avarage price based on the records at the product table.
DELIMITER //
CREATE FUNCTION calculate_average_price()
RETURNS DECIMAL(10, 2)
DETERMINISTIC
BEGIN
    DECLARE avg_price DECIMAL(10, 2);
    
    SELECT AVG(price) INTO avg_price
    FROM product;

    RETURN avg_price;
END //
DELIMITER ;


SELECT calculate_average_price();


select update_product_quantity();
select * from product;
drop function update_order_product_status;
DELIMITER //

select * from order_product;
select * from product;
-- Function to update product quantity
CREATE FUNCTION update_product_quantity() RETURNS BOOLEAN
DETERMINISTIC
BEGIN
    DECLARE success BOOLEAN DEFAULT FALSE;

    UPDATE product p
    JOIN (
        SELECT product_id, SUM(quantity) AS total_quantity
        FROM order_product
        WHERE order_status = 'pending'
        GROUP BY product_id
    ) AS op ON p.product_id = op.product_id
    SET p.qty_in_stock = p.qty_in_stock - op.total_quantity;

    -- Check if update was successful
    IF ROW_COUNT() > 0 THEN
        SET success = TRUE;
    END IF;

    RETURN success;
END //


DELIMITER //

CREATE FUNCTION update_order_product_status() RETURNS BOOLEAN
DETERMINISTIC
BEGIN
    DECLARE success BOOLEAN DEFAULT FALSE;

    UPDATE order_product
    SET order_status = 'processed'
    WHERE order_status = 'pending';

    IF ROW_COUNT() > 0 THEN -- returns a number of rows affected by the last select, update, delete, replace statements.
        SET success = TRUE;
    END IF;

    RETURN success;
END //

DELIMITER ;

select * from order_product;
select * from product;
select * from shop_order;
select * from address;
-- id(1-12), user_id(1-8), 


insert into  order_product(order_id, product_id, quantity, order_status)
	values (12, 50, 1, "pending"),
		    (12, 25, 1, "pending"),
            (12, 25, 1, "pending"),
            (13, 157, 3, "pending"),
            (13, 52, 1, "pending"),
            (13, 89, 1, "pending"),
            (13, floor(1 + rand() * 200), 1, "pending"),
            (14, floor(1 + rand() * 200), 2, "pending"),
            (15, floor(1 + rand() * 200), 4, "pending"),
            (15, floor(1 + rand() * 200), 1, "pending"),
            (16, floor(1 + rand() * 200), 1, "pending"),
            (16, floor(1 + rand() * 200), 2, "pending"),
            (16, floor(1 + rand() * 200), 1, "pending"),
            (16, floor(1 + rand() * 200), 1, "pending"),
            (17, floor(1 + rand() * 200), 5, "pending"),
            (18, floor(1 + rand() * 200), 3, "pending"),
            (18, floor(1 + rand() * 200), 15, "pending"),
            (19, floor(1 + rand() * 200), 6, "pending");
		
	select * from order_product;

-- Procedure that will increace price of all products by procentage, that is passsed as an attribute.
DELIMITER //

CREATE PROCEDURE update_product_pricesv3(IN percentage_increase DECIMAL(5, 2))
BEGIN
    DECLARE product_id_val INT;
    DECLARE current_price DECIMAL(10, 2);
    DECLARE done INT DEFAULT 0;

    DECLARE product_cursor CURSOR FOR SELECT product_id, price FROM product;

    DECLARE EXIT HANDLER FOR NOT FOUND SET done = 1;

    OPEN product_cursor;

    cursor_loop: LOOP
        FETCH product_cursor INTO product_id_val, current_price;
        IF done THEN
            LEAVE cursor_loop;
        END IF;

        SET current_price = current_price * (1 + (percentage_increase / 100));

        UPDATE product SET price = current_price WHERE product_id = product_id_val;
    END LOOP;

    CLOSE product_cursor;

END //

DELIMITER ;

DELIMITER //



describe uzivatel;

select * from product;

call update_product_pricesv3(5);

select * from update_product_pricesv3;

-- Table that records any changes(caused by trigger) at the uzivatel table.
CREATE TABLE IF NOT EXISTS audit_log (
    id INT AUTO_INCREMENT PRIMARY KEY,
    operation VARCHAR(10) NOT NULL,
    table_name VARCHAR(255) NOT NULL,
    record_id INT NOT NULL,
    old_name varchar(50),
    new_name varchar(50),
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

select * from audit_log;
-- Triggers for inserting, updating and deleting users in uzivatel table.
DELIMITER //

CREATE TRIGGER uzivatel_insert_trigger
AFTER INSERT ON uzivatel
FOR EACH ROW
BEGIN
    INSERT INTO audit_log (operation, table_name, record_id, new_name)
    VALUES ('INSERT', 'uzivatel', NEW.user_id, NEW.jmeno_a_prijmeni);
END;

//

DELIMITER ;

select * from uzivatel;

insert into uzivatel
	values(26, "Rafael Gumerov", "gumer@emample.com", 3324234, "fsadlkfjsld");


DELIMITER //

CREATE TRIGGER uzivatel_update_trigger
AFTER UPDATE ON uzivatel
FOR EACH ROW
BEGIN
    INSERT INTO audit_log (operation, table_name, record_id, old_name, new_name)
    VALUES ('UPDATE', 'uzivatel', NEW.user_id, OLD.jmeno_a_prijmeni, NEW.jmeno_a_prijmeni);
END;

//


DELIMITER //

CREATE TRIGGER uzivatel_delete_trigger
BEFORE DELETE ON uzivatel
FOR EACH ROW
BEGIN
    INSERT INTO audit_log (operation, table_name, record_id, old_name)
    VALUES ('DELETE', 'uzivatel', OLD.user_id, OLD.jmeno_a_prijmeni);
END;

//


select * from uzivatel;

UPDATE uzivatel SET jmeno_a_prijmeni = 'Updated Doe' WHERE user_id = 1;

DELETE FROM uzivatel WHERE user_id = 2;

select * from audit_log;

select * from pc_komponenty.shop_order;	

select * from pc_komponenty.address;


SELECT CONSTRAINT_NAME, CONSTRAINT_TYPE
FROM information_schema.TABLE_CONSTRAINTS
WHERE TABLE_SCHEMA = 'pc_komponenty' AND TABLE_NAME = 'shop_order';

use pc_komponenty;

-- Creating new columns in shop_order table so it will be more realistic.
ALTER TABLE shop_order
ADD CONSTRAINT fk_shop_orders_adress
FOREIGN KEY (shopping_adress)
REFERENCES address(adress_id);

# transaction that will reduce quantity of ordered products from product table.


DELIMITER //

CREATE PROCEDURE process_orders()
BEGIN
    DECLARE product_updated BOOLEAN;
    DECLARE order_product_updated BOOLEAN;

    START TRANSACTION;

    SET product_updated := update_product_quantity();

    SET order_product_updated := update_order_product_status();

    IF product_updated AND order_product_updated THEN
        COMMIT;
    ELSE
        ROLLBACK;
    END IF;
END//

DELIMITER ;

-- 198 -5 35

select * from order_product;
select * from product;

CALL process_orders();

select * from product;
select * from order_product;

CREATE USER 'rafael'@'localhost' IDENTIFIED BY '1234';
CREATE USER 'michel'@'localhost' IDENTIFIED BY '321';
DROP USER 'rafael'@'localhost';

-- mysql -u username -p -- "1234"
CREATE ROLE simple_user;
GRANT SELECT ON pc_komponenty.product TO simple_user;
GRANT simple_user TO 'rafael'@'localhost';

REVOKE SELECT ON pc_komponenty.product FROM 'rafael'@'localhost';



LOCK TABLES product WRITE;
-- READ UPDATE
UNLOCK TABLES;
SELECT * FROM product WHERE id = 1 FOR UPDATE;
-- allow session only read all the tabels in database	
FLUSH TABLES WITH READ LOCK;
UNLOCK TABLES;



