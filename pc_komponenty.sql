-- phpMyAdmin SQL Dump
-- version 5.2.2
-- https://www.phpmyadmin.net/
--
-- Host: db:3306
-- Generation Time: Mar 05, 2025 at 10:11 PM
-- Server version: 8.0.41
-- PHP Version: 8.2.27

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `pc_komponenty`
--

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `process_orders` ()   BEGIN
    DECLARE product_updated BOOLEAN;
    DECLARE order_product_updated BOOLEAN;

    START TRANSACTION;

    -- Call update_product_quantity function
    SET product_updated := update_product_quantity();

    -- Call update_order_product_status function
    SET order_product_updated := update_order_product_status();

    -- Check if both updates were successful
    IF product_updated AND order_product_updated THEN
        COMMIT;
    ELSE
        ROLLBACK;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `update_product_pricesv3` (IN `percentage_increase` DECIMAL(5,2))   BEGIN
    DECLARE product_id_val INT;
    DECLARE current_price DECIMAL(10, 2);
    DECLARE done INT DEFAULT 0;

    -- Declare a cursor for selecting product_id and price
    DECLARE product_cursor CURSOR FOR SELECT product_id, price FROM product;

    -- Declare a handler for the cursor
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    -- Open the cursor
    OPEN product_cursor;

    -- Loop through products and update prices
    cursor_loop: LOOP
        FETCH product_cursor INTO product_id_val, current_price;
        IF done THEN
            LEAVE cursor_loop;
        END IF;

        -- Calculate the new price with the specified percentage increase
        SET current_price = current_price * (1 + (percentage_increase / 100));

        -- Update the product table
        UPDATE product SET price = current_price WHERE product_id = product_id_val;
    END LOOP;

    -- Close the cursor
    CLOSE product_cursor;

    -- Optionally, you can add additional error handling logic here
    IF done = 1 THEN
        -- Handle the case when no products are found
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No products found in the product table';
    END IF;
END$$

--
-- Functions
--
CREATE DEFINER=`root`@`localhost` FUNCTION `calculate_average_price` () RETURNS DECIMAL(10,2) DETERMINISTIC BEGIN
    DECLARE avg_price DECIMAL(10, 2);
    
    SELECT AVG(price) INTO avg_price
    FROM product;

    RETURN avg_price;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `update_order_product_status` () RETURNS TINYINT(1) DETERMINISTIC BEGIN
    DECLARE success BOOLEAN DEFAULT FALSE;

    UPDATE order_product
    SET order_status = 'processed'
    WHERE order_status = 'pending';

    IF ROW_COUNT() > 0 THEN -- returns a number of rows affected by the last select, update, delete, replace statements.
        SET success = TRUE;
    END IF;

    RETURN success;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `update_product_quantity` () RETURNS TINYINT(1) DETERMINISTIC BEGIN
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
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `address`
--

CREATE TABLE `address` (
  `adress_id` int NOT NULL,
  `address_line1` varchar(255) DEFAULT NULL,
  `unit_number` varchar(20) DEFAULT NULL,
  `postal_code` varchar(20) DEFAULT NULL,
  `user_id` int DEFAULT NULL,
  `city_id` int DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `address`
--

INSERT INTO `address` (`adress_id`, `address_line1`, `unit_number`, `postal_code`, `user_id`, `city_id`) VALUES
(51, 'Полковая 1', '22', '127018', 1, 1),
(52, '1-й Тихвинский тупик 9', '130', '127055', 2, 1),
(53, '3-й Самотечный переулок 13', '1', '127055', 3, 1),
(54, 'Нижний Сусальный переулок 5', '8', '105064', 4, 1),
(55, 'Карбышева 8, строение 3', '49', '143900', 5, 3),
(56, '8 марта 7', '23', '150002', 6, 6),
(57, 'Бордулина 9', '5', '152934', 7, 7),
(58, 'Прибрежная 105', '302', '158907', 8, 8),
(59, 'Угличевская 90', '77', '153490', 9, 9),
(60, 'Ленина 69', '15', '156784', 10, 10),
(61, 'Kovákú 1192/7', '74', '15000', 11, 11),
(62, 'K nemocnici 2814', '3', '27201', 12, 12),
(63, 'Okružní 204', '101', '26101', 13, 13),
(64, 'Štechova 240', '1', '29301', 14, 14),
(65, 'Jungmannovo nám. 472', '33', '28401', 15, 15),
(66, 'Špitálské nám. 1068/1', '14', '40001', 16, 16),
(67, 'Liberecká 2306/7', '1', '41501', 17, 17),
(68, 'P. Holého 37/35', '304', '40502', 18, 18),
(69, 'Třebízkého 4420', '75', '43003', 19, 19),
(70, 'Pokratická 97/13', '63', '41201', 20, 20),
(71, 'Mírové nám. 971/1', '33', '40001', 20, 16);

-- --------------------------------------------------------

--
-- Table structure for table `audit_log`
--

CREATE TABLE `audit_log` (
  `id` int NOT NULL,
  `operation` varchar(10) NOT NULL,
  `table_name` varchar(255) NOT NULL,
  `record_id` int NOT NULL,
  `old_name` varchar(50) DEFAULT NULL,
  `new_name` varchar(50) DEFAULT NULL,
  `timestamp` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `audit_log`
--

INSERT INTO `audit_log` (`id`, `operation`, `table_name`, `record_id`, `old_name`, `new_name`, `timestamp`) VALUES
(1, 'UPDATE', 'uzivatel', 1, 'John Doe', 'Updated Doe', '2024-01-16 14:31:10'),
(3, 'UPDATE', 'uzivatel', 1, 'Updated Doe', 'Updated Doe', '2024-02-13 10:53:45'),
(5, 'UPDATE', 'uzivatel', 1, 'Updated Doe', 'Updated Doe', '2024-02-13 10:54:42'),
(7, 'INSERT', 'uzivatel', 26, NULL, 'Rafael Gumerov', '2024-02-13 15:37:21');

-- --------------------------------------------------------

--
-- Table structure for table `city`
--

CREATE TABLE `city` (
  `CityID` int NOT NULL,
  `CityName` varchar(255) NOT NULL,
  `RegionID` int DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `city`
--

INSERT INTO `city` (`CityID`, `CityName`, `RegionID`) VALUES
(1, 'Moscow', 1),
(2, 'Krasnogorsk', 1),
(3, 'Balashikha', 1),
(4, 'Korolev', 1),
(5, 'Lyubertsy', 1),
(6, 'Yaroslavl', 2),
(7, 'Rybinsk', 2),
(8, 'Pereslavl-Zalessky', 2),
(9, 'Uglich', 2),
(10, 'Tutayev', 2),
(11, 'Prague', 3),
(12, 'Kladno', 3),
(13, 'Příbram', 3),
(14, 'Mladá Boleslav', 3),
(15, 'Kutná Hora', 3),
(16, 'Ústí nad Labem', 4),
(17, 'Teplice', 4),
(18, 'Děčín', 4),
(19, 'Chomutov', 4),
(20, 'Litoměřice', 4);

-- --------------------------------------------------------

--
-- Table structure for table `country`
--

CREATE TABLE `country` (
  `CountryID` int NOT NULL,
  `CountryName` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `country`
--

INSERT INTO `country` (`CountryID`, `CountryName`) VALUES
(1, 'Russia'),
(2, 'Czech Republic');

-- --------------------------------------------------------

--
-- Stand-in structure for view `expensive_products`
-- (See below for the actual view)
--
CREATE TABLE `expensive_products` (
`price` decimal(10,2)
,`product_name` varchar(255)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `names_of_product_and_customer_name`
-- (See below for the actual view)
--
CREATE TABLE `names_of_product_and_customer_name` (
`email` varchar(50)
,`jmeno_a_prijmeni` varchar(50)
,`price` decimal(10,2)
,`product_name` varchar(255)
);

-- --------------------------------------------------------

--
-- Table structure for table `order_product`
--

CREATE TABLE `order_product` (
  `order_id` int DEFAULT NULL,
  `product_id` int DEFAULT NULL,
  `quantity` int DEFAULT NULL,
  `order_status` varchar(50) DEFAULT 'pending'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `order_product`
--

INSERT INTO `order_product` (`order_id`, `product_id`, `quantity`, `order_status`) VALUES
(12, 50, 1, 'processed'),
(12, 25, 1, 'processed'),
(12, 25, 1, 'processed'),
(13, 157, 3, 'processed'),
(13, 52, 1, 'processed'),
(13, 89, 1, 'processed'),
(13, 191, 1, 'processed'),
(14, 109, 2, 'processed'),
(15, 169, 4, 'processed'),
(15, 120, 1, 'processed'),
(16, 91, 1, 'processed'),
(16, 96, 2, 'processed'),
(16, 5, 1, 'processed'),
(16, 136, 1, 'processed'),
(17, 64, 5, 'processed'),
(18, 112, 3, 'processed'),
(18, 167, 15, 'processed'),
(19, 98, 6, 'processed'),
(12, 50, 1, 'processed'),
(12, 25, 1, 'processed'),
(12, 25, 1, 'processed'),
(13, 157, 3, 'processed'),
(13, 52, 1, 'processed'),
(13, 89, 1, 'processed'),
(13, 31, 1, 'processed'),
(14, 111, 2, 'processed'),
(15, 64, 4, 'processed'),
(15, 188, 1, 'processed'),
(16, 144, 1, 'processed'),
(16, 157, 2, 'processed'),
(16, 153, 1, 'processed'),
(16, 91, 1, 'processed'),
(17, 198, 5, 'processed'),
(18, 116, 3, 'processed'),
(18, 183, 15, 'processed'),
(19, 170, 6, 'processed');

-- --------------------------------------------------------

--
-- Table structure for table `product`
--

CREATE TABLE `product` (
  `product_id` int NOT NULL,
  `category_id` int DEFAULT NULL,
  `price` decimal(10,2) DEFAULT NULL,
  `product_name` varchar(255) DEFAULT NULL,
  `product_description` varchar(10000) DEFAULT NULL,
  `image` blob,
  `qty_in_stock` int DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `product`
--

INSERT INTO `product` (`product_id`, `category_id`, `price`, `product_name`, `product_description`, `image`, `qty_in_stock`) VALUES
(1, 2, 233.98, 'Intel Core i9-11900K', 'Výkonný procesor Intel Core i9-11900K poskytuje vysoký výkon pro náročné úkoly. S 8 jádry a 16 vlákny je ideální pro hraní her a profesionální práci.', NULL, 50),
(2, 2, 187.18, 'AMD Ryzen 7 5800X', 'Procesor AMD Ryzen 7 5800X nabízí výjimečný výkon díky 8 jádrům a 16 vláknům. Je vhodný pro hraní, kreativní práci i multitasking.', NULL, 40),
(3, 2, 152.08, 'Intel Core i7-11700K', 'Moderní procesor Intel Core i7-11700K poskytuje vysoký výkon pro náročné aplikace. S 8 jádry a 16 vlákny zvládá i náročné úkoly.', NULL, 60),
(4, 2, 116.99, 'AMD Ryzen 5 5600X', 'Procesor AMD Ryzen 5 5600X nabízí skvělý výkon pro hraní her a multitasking. S 6 jádry a 12 vlákny je ideální pro moderní aplikace.', NULL, 30),
(5, 2, 93.58, 'Intel Core i5-11400F', 'Procesor Intel Core i5-11400F poskytuje dostatečný výkon pro běžné úkoly a hraní her. S 6 jádry a 12 vlákny je skvělou volbou pro střední třídu.', NULL, 22),
(6, 2, 175.49, 'AMD Ryzen 7 5700G', 'Výkonný procesor AMD Ryzen 7 5700G s integrovanou grafikou nabízí vynikající výkon a možnost hraní her bez dedikované grafické karty.', NULL, 35),
(7, 2, 140.40, 'Intel Core i5-11600K', 'Procesor Intel Core i5-11600K poskytuje výkonný základ pro hraní her a pracovní aplikace. S 6 jádry a 12 vlákny uspokojí náročné uživatele.', NULL, 40),
(8, 2, 105.29, 'AMD Ryzen 5 5500X', 'Procesor AMD Ryzen 5 5500X je ideální volbou pro moderní aplikace a hry. S 6 jádry a 12 vlákny nabízí výborný poměr cena/výkon.', NULL, 30),
(9, 2, 198.89, 'Intel Core i9-10900K', 'Výkonný procesor Intel Core i9-10900K nabízí nejlepší výkon pro náročné uživatele. S 10 jádry a 20 vlákny je ideální pro profesionální práci i hry.', NULL, 50),
(10, 2, 128.69, 'AMD Ryzen 5 5600G', 'Procesor AMD Ryzen 5 5600G s integrovanou grafikou je skvělým řešením pro uživatele, kteří chtějí dobrou herní výkonost bez dedikované GPU.', NULL, 20),
(11, 2, 163.79, 'Intel Core i7-10700K', 'Výkonný procesor Intel Core i7-10700K je vhodný pro náročné aplikace a hraní her. S 8 jádry a 16 vlákny zvládá multitasking i náročné úkoly.', NULL, 45),
(12, 2, 105.29, 'AMD Ryzen 3 5300X', 'Procesor AMD Ryzen 3 5300X nabízí dobrou výkonost pro základní úkoly a hraní her. S 4 jádry a 8 vlákny je ideální pro střední třídu uživatelů.', NULL, 30),
(13, 2, 152.08, 'Intel Core i5-10500F', 'Procesor Intel Core i5-10500F poskytuje solidní výkon pro hraní her a každodenní použití. S 6 jádry a 12 vlákny je skvělou volbou pro střední třídu.', NULL, 40),
(14, 2, 81.89, 'AMD Ryzen 3 5200G', 'Procesor AMD Ryzen 3 5200G s integrovanou grafikou je cenově dostupným řešením pro uživatele, kteří chtějí dobrou herní výkonost.', NULL, 25),
(15, 2, 140.40, 'Intel Core i3-10100', 'Procesor Intel Core i3-10100 je vhodný pro základní aplikace a běžné použití. S 4 jádry a 8 vlákny zvládá běžné úkoly s lehkostí.', NULL, 50),
(16, 2, 292.48, 'AMD Ryzen 9 5900X', 'Výkonný procesor AMD Ryzen 9 5900X nabízí nejlepší výkon pro náročné úkoly. S 12 jádry a 24 vlákny je ideální pro profesionální práci i hraní her.', NULL, 30),
(17, 2, 210.59, 'Intel Core i7-12700K', 'Moderní procesor Intel Core i7-12700K poskytuje výjimečný výkon pro náročné aplikace. S 8 jádry a 16 vlákny je ideální pro profesionální práci a hraní her.', NULL, 40),
(18, 2, 163.79, 'AMD Ryzen 5 5600', 'Procesor AMD Ryzen 5 5600 je skvělou volbou pro všestranné použití. S 6 jádry a 12 vlákny nabízí výborný výkon pro hry i produktivní práci.', NULL, 35),
(19, 2, 116.99, 'Intel Core i5-11600', 'Výkonný procesor Intel Core i5-11600 nabízí dostatečný výkon pro běžné úkoly a hraní her. S 6 jádry a 12 vlákny zvládá multitasking i náročné aplikace.', NULL, 50),
(20, 2, 105.29, 'AMD Ryzen 3 5300', 'Procesor AMD Ryzen 3 5300 je cenově dostupným řešením pro základní aplikace. S 4 jádry a 8 vlákny je vhodný pro každodenní použití a zábavu.', NULL, 60),
(21, 3, 386.09, 'AMD Radeon RX 6700', 'Grafická karta AMD Radeon RX 6700 je ideální volbou pro hráče. S 12 GB paměti GDDR6 nabízí plynulý herní výkon a podporu moderních technologií.', NULL, 30),
(22, 3, 327.59, 'NVIDIA GeForce RTX 3060 Ti', 'Výkonná grafická karta NVIDIA GeForce RTX 3060 Ti je určena pro hráče, kteří chtějí excelentní výkon. S 8 GB paměti GDDR6 je ideální pro hraní v QHD rozlišení.', NULL, 25),
(23, 3, 233.98, 'AMD Radeon RX 6600 XT', 'Grafická karta AMD Radeon RX 6600 XT nabízí skvělý výkon pro hraní ve Full HD rozlišení. S 8 GB paměti GDDR6 si poradí s moderními tituly.', NULL, 40),
(24, 3, 187.18, 'NVIDIA GeForce GTX 1660 Ti', 'Grafická karta NVIDIA GeForce GTX 1660 Ti je cenově dostupnou volbou pro hráče. S 6 GB paměti GDDR6 zvládá mnoho her ve Full HD.', NULL, 35),
(25, 3, 140.40, 'AMD Radeon RX 5500 XT', 'Procesor AMD Radeon RX 5500 XT nabízí dobrý výkon pro hraní ve Full HD rozlišení. S 8 GB paměti GDDR6 je vhodný pro hráče s menším rozpočtem.', NULL, 42),
(26, 3, 467.97, 'NVIDIA GeForce RTX 3090', 'Výkonná grafická karta NVIDIA GeForce RTX 3090 je nejlepší volbou pro náročné hráče a tvůrce obsahu. S 24 GB paměti GDDR6X nabízí excelentní výkon a podporu ray tracingu.', NULL, 20),
(27, 3, 374.39, 'AMD Radeon RX 6900 XT', 'Grafická karta AMD Radeon RX 6900 XT je výjimečně výkonným modelem pro hráče a profesionály. S 16 GB paměti GDDR6 nabízí nejlepší výkon pro moderní aplikace.', NULL, 25),
(28, 3, 280.78, 'NVIDIA GeForce RTX 3080 Ti', 'Grafická karta NVIDIA GeForce RTX 3080 Ti nabízí vynikající výkon pro náročné hráče. S 12 GB paměti GDDR6X je ideální pro hraní ve vysokém rozlišení.', NULL, 30),
(29, 3, 210.59, 'AMD Radeon RX 6800', 'Výkonná grafická karta AMD Radeon RX 6800 poskytuje vynikající výkon pro hráče. S 16 GB paměti GDDR6 je ideální pro hraní ve vysokém rozlišení.', NULL, 40),
(30, 3, 175.49, 'NVIDIA GeForce GTX 1650 Super', 'Grafická karta NVIDIA GeForce GTX 1650 Super je vhodnou volbou pro hráče s menším rozpočtem. S 4 GB paměti GDDR6 nabízí solidní výkon pro hry ve Full HD.', NULL, 45),
(31, 3, 233.98, 'AMD Radeon RX 6700 XT', 'Grafická karta AMD Radeon RX 6700 XT nabízí vynikající herní výkon. S 12 GB paměti GDDR6 je ideální pro hráče, kteří chtějí hrát ve vyšším rozlišení.', NULL, 34),
(32, 3, 304.19, 'NVIDIA GeForce RTX 3070 Ti', 'Grafická karta NVIDIA GeForce RTX 3070 Ti poskytuje skvělý výkon pro hráče. S 8 GB paměti GDDR6X zvládá i náročné hry v rozlišení QHD.', NULL, 30),
(33, 3, 257.39, 'AMD Radeon RX 6600', 'Grafická karta AMD Radeon RX 6600 nabízí plynulý výkon pro hraní ve Full HD rozlišení. S 8 GB paměti GDDR6 si poradí s moderními tituly a hrami.', NULL, 40),
(34, 3, 175.49, 'NVIDIA GeForce GTX 1650', 'Grafická karta NVIDIA GeForce GTX 1650 je cenově dostupnou volbou pro hráče. S 4 GB paměti GDDR5 nabízí solidní výkon pro hry ve Full HD.', NULL, 45),
(35, 3, 210.59, 'AMD Radeon RX 6600', 'Grafická karta AMD Radeon RX 6600 nabízí dobrý výkon pro hraní ve Full HD rozlišení. S 8 GB paměti GDDR6 nabízí vynikající poměr cena/výkon.', NULL, 40),
(36, 3, 152.08, 'NVIDIA GeForce GTX 1050 Ti', 'Grafická karta NVIDIA GeForce GTX 1050 Ti je vhodnou volbou pro hráče se základními nároky. S 4 GB paměti GDDR5 zvládá hraní ve Full HD rozlišení.', NULL, 55),
(37, 3, 526.48, 'NVIDIA GeForce RTX 3080', 'Výkonná grafická karta NVIDIA GeForce RTX 3080 nabízí nejlepší herní výkon. S architekturou Ampere a 10 GB paměti GDDR6X zvládá náročné hry v ultra kvalitě.', NULL, 25),
(38, 3, 432.88, 'AMD Radeon RX 6800 XT', 'Grafická karta AMD Radeon RX 6800 XT poskytuje vynikající výkon pro hráče. S 16 GB paměti GDDR6 je ideální pro hraní ve vysokém rozlišení.', NULL, 30),
(39, 3, 304.19, 'NVIDIA GeForce RTX 3070', 'Grafická karta NVIDIA GeForce RTX 3070 nabízí skvělý herní výkon pro většinu her. S 8 GB paměti GDDR6 zvládá i náročné tituly ve Full HD a QHD.', NULL, 40),
(40, 3, 210.59, 'AMD Radeon RX 6700 XT', 'Pro hráče, kteří chtějí vynikající výkon, je tady grafická karta AMD Radeon RX 6700 XT. S 12 GB paměti GDDR6 si poradí i s moderními hrami.', NULL, 35),
(41, 3, 175.49, 'NVIDIA GeForce GTX 1660 Super', 'Grafická karta NVIDIA GeForce GTX 1660 Super je skvělou volbou pro hráče s menším rozpočtem. S 6 GB paměti GDDR5 zvládá mnoho her ve Full HD.', NULL, 50),
(42, 4, 105.29, 'Crucial Ballistix 16GB DDR4', '16GB paměťový modul Crucial Ballistix nabízí rychlý výkon pro hraní a multitasking. DDR4 standard a frekvence 3200 MHz zaručují plynulý chod aplikací.', NULL, 50),
(43, 4, 58.49, 'Kingston HyperX Fury 8GB DDR4', '8GB paměťový modul Kingston HyperX Fury je vhodný pro běžné úkoly a hraní her. DDR4 standard a frekvence 2666 MHz poskytují spolehlivý výkon.', NULL, 60),
(44, 4, 187.18, 'Corsair Vengeance RGB Pro 32GB DDR4', '32GB paměťový modul Corsair Vengeance RGB Pro je ideální pro náročnou práci i hraní her. DDR4 standard a frekvence 3600 MHz zaručují vynikající výkon.', NULL, 40),
(45, 4, 81.89, 'G.Skill Ripjaws V 16GB DDR4', '16GB paměťový modul G.Skill Ripjaws V nabízí výjimečný výkon pro hráče a kreativní práci. DDR4 standard a frekvence 3000 MHz zlepšují rychlost systému.', NULL, 55),
(46, 4, 140.40, 'Crucial Ballistix 32GB DDR4', '32GB paměťový modul Crucial Ballistix je vhodný pro profesionální práci i hraní her. DDR4 standard a frekvence 3600 MHz zaručují rychlý a plynulý provoz.', NULL, 40),
(47, 4, 116.99, 'Corsair Vengeance LPX 16GB DDR4', '16GB paměťový modul Corsair Vengeance LPX je skvělým řešením pro hráče a běžné uživatele. DDR4 standard a frekvence 3200 MHz zaručují spolehlivost.', NULL, 50),
(48, 4, 46.79, 'Kingston ValueRAM 8GB DDR4', '8GB paměťový modul Kingston ValueRAM nabízí základní výkon pro běžné úkoly. DDR4 standard a frekvence 2400 MHz zajišťují spolehlivý chod systému.', NULL, 70),
(49, 4, 163.79, 'G.Skill Trident Z RGB 32GB DDR4', '32GB paměťový modul G.Skill Trident Z RGB nabízí vynikající výkon a stylový design. DDR4 standard a frekvence 3600 MHz jsou ideální pro náročné úkoly.', NULL, 30),
(50, 4, 70.18, 'Corsair Vengeance LPX 8GB DDR4', '8GB paměťový modul Corsair Vengeance LPX je vhodný pro hráče a běžné úkoly. DDR4 standard a frekvence 3000 MHz zaručují spolehlivost a rychlost.', NULL, 61),
(51, 4, 198.89, 'G.Skill Ripjaws V 64GB DDR4', '64GB paměťový modul G.Skill Ripjaws V je ideální pro náročnou kreativní práci. DDR4 standard a frekvence 3600 MHz zajišťují dostatečnou výkonnost.', NULL, 20),
(52, 4, 93.58, 'HyperX Predator RGB 16GB DDR4', '16GB paměťový modul HyperX Predator RGB nabízí výjimečný výkon a oslnivé RGB osvětlení. DDR4 standard a frekvence 3200 MHz jsou ideální pro hráče.', NULL, 36),
(53, 4, 152.08, 'Crucial Ballistix 64GB DDR4', '64GB paměťový modul Crucial Ballistix je vhodný pro profesionály a náročnou práci. DDR4 standard a frekvence 3600 MHz zajišťují výjimečný výkon a stabilitu.', NULL, 25),
(54, 4, 105.29, 'Corsair Vengeance RGB Pro 16GB DDR4', '16GB paměťový modul Corsair Vengeance RGB Pro nabízí skvělý výkon a efektní RGB osvětlení. DDR4 standard a frekvence 3200 MHz jsou ideální pro hráče.', NULL, 45),
(55, 4, 58.49, 'G.Skill Aegis 8GB DDR4', '8GB paměťový modul G.Skill Aegis poskytuje základní výkon pro běžné úkoly. DDR4 standard a frekvence 3000 MHz zaručují spolehlivý provoz systému.', NULL, 60),
(56, 4, 210.59, 'Corsair Dominator Platinum RGB 32GB DDR4', '32GB paměťový modul Corsair Dominator Platinum RGB nabízí luxusní výkon a eleganci. DDR4 standard a frekvence 3600 MHz zaručují plynulý chod aplikací.', NULL, 35),
(57, 4, 70.18, 'Kingston HyperX Fury 16GB DDR4', '16GB paměťový modul Kingston HyperX Fury je vhodný pro hraní her a multitasking. DDR4 standard a frekvence 3200 MHz zajišťují plynulý výkon systému.', NULL, 50),
(58, 4, 152.08, 'G.Skill Trident Z Neo 32GB DDR4', '32GB paměťový modul G.Skill Trident Z Neo nabízí výjimečný výkon a kompatibilitu se systémy AMD. DDR4 standard a frekvence 3600 MHz jsou ideální pro náročné aplikace.', NULL, 40),
(59, 4, 81.89, 'Crucial Ballistix 8GB DDR4', '8GB paměťový modul Crucial Ballistix nabízí spolehlivý výkon pro běžné úkoly. DDR4 standard a frekvence 2666 MHz jsou ideální pro kancelářské aplikace.', NULL, 55),
(60, 4, 175.49, 'Corsair Vengeance LPX 32GB DDR4', '32GB paměťový modul Corsair Vengeance LPX je ideální pro výkonné aplikace i hraní her. DDR4 standard a frekvence 3200 MHz zajišťují plynulý chod systému.', NULL, 30),
(61, 4, 93.58, 'G.Skill Ripjaws V 8GB DDR4', '8GB paměťový modul G.Skill Ripjaws V nabízí spolehlivý výkon pro běžné úkoly. DDR4 standard a frekvence 3000 MHz jsou vhodné pro multitasking.', NULL, 60),
(62, 4, 233.98, 'Kingston HyperX Predator 64GB DDR4', '64GB paměťový modul Kingston HyperX Predator nabízí výjimečnou kapacitu a výkon. DDR4 standard a frekvence 3200 MHz jsou ideální pro náročné úkoly.', NULL, 25),
(63, 5, 93.58, 'EVGA 600 W1', 'Napájecí zdroj EVGA 600 W1 nabízí spolehlivý výkon pro běžné počítačové systémy. S výkonem 600W je ideální pro kancelářské a multimediální účely.', NULL, 50),
(64, 5, 128.69, 'Corsair CV550', 'Napájecí zdroj Corsair CV550 je vhodný pro středně výkonné počítačové sestavy. S výkonem 550W a 80 PLUS Bronze certifikací nabízí úsporný provoz.', NULL, 21),
(65, 5, 152.08, 'Seasonic S12III 650', 'Napájecí zdroj Seasonic S12III 650 poskytuje spolehlivý výkon pro středně náročné sestavy. S výkonem 650W je ideální pro hraní a kreativní práci.', NULL, 35),
(66, 5, 105.29, 'Cooler Master MWE 550', 'Napájecí zdroj Cooler Master MWE 550 je cenově dostupnou volbou pro běžné počítačové systémy. S výkonem 550W a 80 PLUS certifikací je spolehlivým řešením.', NULL, 55),
(67, 5, 163.79, 'be quiet! System Power 9 700', 'Napájecí zdroj be quiet! System Power 9 700 je vhodný pro středně výkonné sestavy. S výkonem 700W a nízkým hlukem je ideální pro hraní a pracovní úkoly.', NULL, 30),
(68, 5, 116.99, 'Thermaltake Smart RGB 600W', 'Napájecí zdroj Thermaltake Smart RGB 600W nabízí solidní výkon a atraktivní RGB osvětlení. S výkonem 600W je ideální pro hráče a moderní sestavy.', NULL, 40),
(69, 5, 140.40, 'NZXT C650', 'Napájecí zdroj NZXT C650 je výkonným modelem pro náročné sestavy. S výkonem 650W a 80 PLUS Gold certifikací nabízí spolehlivý a úsporný provoz.', NULL, 35),
(70, 5, 81.89, 'Fractal Design Ion+ 560P', 'Napájecí zdroj Fractal Design Ion+ 560P poskytuje spolehlivý výkon pro středně náročné sestavy. S výkonem 560W a platinovou certifikací je energeticky úsporným řešením.', NULL, 45),
(71, 5, 187.18, 'Seasonic Focus GX-750', 'Napájecí zdroj Seasonic Focus GX-750 je výkonným modelem pro herní sestavy. S výkonem 750W a 80 PLUS Gold certifikací nabízí vynikající efektivitu a stabilitu.', NULL, 30),
(72, 5, 105.29, 'EVGA 700 BR', 'Napájecí zdroj EVGA 700 BR nabízí spolehlivý výkon a efektivitu pro středně výkonné počítače. S výkonem 700W je ideální pro hraní a běžné úkoly.', NULL, 50),
(73, 5, 210.59, 'Corsair RM750x', 'Napájecí zdroj Corsair RM750x je výkonným modelem s modulárním provedením. S výkonem 750W a 80 PLUS Gold certifikací nabízí spolehlivý a úsporný provoz.', NULL, 25),
(74, 5, 116.99, 'be quiet! Straight Power 11 550W', 'Napájecí zdroj be quiet! Straight Power 11 550W je vysoce kvalitní volbou pro náročné sestavy. S výkonem 550W a platinovou certifikací nabízí nízký hluk a úsporný provoz.', NULL, 40),
(75, 5, 152.08, 'Cooler Master MWE Gold 750', 'Napájecí zdroj Cooler Master MWE Gold 750 poskytuje vynikající efektivitu a výkon pro moderní sestavy. S výkonem 750W a 80 PLUS Gold certifikací je ideální pro hráče a tvůrce obsahu.', NULL, 35),
(76, 5, 93.58, 'Thermaltake Toughpower GX1 500W', 'Napájecí zdroj Thermaltake Toughpower GX1 500W nabízí spolehlivý výkon pro středně výkonné sestavy. S výkonem 500W a 80 PLUS Gold certifikací je úspornou volbou.', NULL, 55),
(77, 5, 175.49, 'NZXT C750', 'Napájecí zdroj NZXT C750 je výkonným modelem pro herní a náročné sestavy. S výkonem 750W a 80 PLUS Gold certifikací nabízí spolehlivý a efektivní provoz.', NULL, 30),
(78, 5, 128.69, 'Fractal Design Ion+ 660P', 'Napájecí zdroj Fractal Design Ion+ 660P je vysoce výkonným modelem pro hráče a tvůrce obsahu. S výkonem 660W a platinovou certifikací nabízí energetickou efektivitu.', NULL, 35),
(79, 5, 222.29, 'Seasonic Focus PX-850', 'Napájecí zdroj Seasonic Focus PX-850 je výkonným modelem s plně modulárním provedením. S výkonem 850W a 80 PLUS Platinum certifikací nabízí vynikající výkon a úspornost.', NULL, 25),
(80, 5, 116.99, 'EVGA SuperNOVA 650 G5', 'Napájecí zdroj EVGA SuperNOVA 650 G5 nabízí spolehlivý výkon pro herní a kreativní sestavy. S výkonem 650W a 80 PLUS Gold certifikací je ideální volbou.', NULL, 45),
(81, 5, 163.79, 'Corsair RM850x', 'Napájecí zdroj Corsair RM850x je výkonným modelem s modulárním provedením. S výkonem 850W a 80 PLUS Gold certifikací nabízí spolehlivý a efektivní provoz.', NULL, 30),
(82, 5, 105.29, 'be quiet! Pure Power 11 700W', 'Napájecí zdroj be quiet! Pure Power 11 700W nabízí spolehlivý výkon a nízký hluk pro středně náročné sestavy. S výkonem 700W je ideální pro hraní a pracovní úkoly.', NULL, 40),
(83, 6, 233.98, 'Dell S2419HGF', 'Monitor Dell S2419HGF nabízí Full HD rozlišení a 24 palců úhlopříčky. S rychlou obnovovací frekvencí 144 Hz je ideální pro hráče.', NULL, 50),
(84, 6, 409.48, 'LG 27GL83A-B', 'Monitor LG 27GL83A-B poskytuje QHD rozlišení a 27 palců úhlopříčky. S rychlou odezvou 1 ms a obnovovací frekvencí 144 Hz je vhodný pro náročné hráče.', NULL, 40),
(85, 6, 304.19, 'Acer R240HY', 'Monitor Acer R240HY nabízí Full HD rozlišení a 23.8 palce úhlopříčky. S IPS panelem poskytuje živé barvy a široké pozorovací úhly.', NULL, 35),
(86, 6, 327.59, 'ASUS VG279Q', 'Monitor ASUS VG279Q má Full HD rozlišení a 27 palců úhlopříčky. S rychlou obnovovací frekvencí 144 Hz a technologií Adaptive-Sync je ideální pro hráče.', NULL, 45),
(87, 6, 526.48, 'Dell Alienware AW3420DW', 'Ultraširoký monitor Dell Alienware AW3420DW nabízí QHD rozlišení a úhlopříčku 34 palců. S křivým panelem a obnovovací frekvencí 120 Hz je skvělým řešením pro hráče.', NULL, 30),
(88, 6, 233.98, 'Samsung Odyssey G3', 'Monitor Samsung Odyssey G3 má Full HD rozlišení a 27 palců úhlopříčky. S rychlou obnovovací frekvencí 144 Hz a technologií FreeSync je ideální pro hráče.', NULL, 50),
(89, 6, 444.58, 'LG 34GN850-B', 'Ultraširoký monitor LG 34GN850-B nabízí QHD rozlišení a úhlopříčku 34 palců. S rychlou obnovovací frekvencí 160 Hz je vhodný pro hráče i kreativní práci.', NULL, 36),
(90, 6, 222.29, 'AOC C24G1', 'Zahnutý monitor AOC C24G1 má Full HD rozlišení a 24 palců úhlopříčky. S obnovovací frekvencí 144 Hz a technologií FreeSync je ideální pro hráče.', NULL, 35),
(91, 6, 350.98, 'ASUS TUF VG27AQ', 'Monitor ASUS TUF VG27AQ poskytuje QHD rozlišení a 27 palců úhlopříčky. S rychlou obnovovací frekvencí 165 Hz a technologií G-Sync je vhodný pro náročné hráče.', NULL, 41),
(92, 6, 701.98, 'Acer Predator X27', 'Monitor Acer Predator X27 nabízí 4K UHD rozlišení a 27 palců úhlopříčky. S technologií G-Sync Ultimate a vysokým jasem je ideální pro herní nadšence.', NULL, 30),
(93, 6, 292.48, 'MSI Optix MAG241C', 'Zahnutý monitor MSI Optix MAG241C nabízí Full HD rozlišení a 24 palců úhlopříčky. S rychlou obnovovací frekvencí 144 Hz a technologií FreeSync je ideální pro hráče.', NULL, 50),
(94, 6, 386.09, 'Samsung Odyssey G5', 'Monitor Samsung Odyssey G5 má QHD rozlišení a 32 palců úhlopříčky. S rychlou obnovovací frekvencí 165 Hz a technologií FreeSync je vhodný pro hráče a kreativní práci.', NULL, 40),
(95, 6, 327.59, 'LG 24MK400H', 'Monitor LG 24MK400H nabízí HD rozlišení a 23.6 palce úhlopříčky. S rychlou odezvou 2 ms je ideální pro hráče s menším rozpočtem.', NULL, 35),
(96, 6, 467.97, 'AOC CU34G2X', 'Ultraširoký monitor AOC CU34G2X nabízí QHD rozlišení a úhlopříčku 34 palců. S obnovovací frekvencí 144 Hz a technologií FreeSync je vhodný pro hráče i pracovní úkoly.', NULL, 24),
(97, 6, 257.39, 'ViewSonic VX2458-MHD', 'Monitor ViewSonic VX2458-MHD nabízí Full HD rozlišení a 24 palců úhlopříčky. S rychlou obnovovací frekvencí 144 Hz a technologií FreeSync je ideální pro hráče.', NULL, 45),
(98, 6, 444.58, 'ASUS ROG Swift PG279Q', 'Monitor ASUS ROG Swift PG279Q poskytuje QHD rozlišení a 27 palců úhlopříčky. S rychlou obnovovací frekvencí 165 Hz a technologií G-Sync je ideální pro náročné hráče.', NULL, 22),
(99, 6, 315.89, 'MSI Optix G241', 'Monitor MSI Optix G241 nabízí Full HD rozlišení a 23.8 palce úhlopříčky. S rychlou obnovovací frekvencí 144 Hz a technologií FreeSync je ideální pro hráče.', NULL, 35),
(100, 6, 584.98, 'LG 32GK850F-B', 'Monitor LG 32GK850F-B má QHD rozlišení a 31.5 palce úhlopříčky. S rychlou obnovovací frekvencí 144 Hz a technologií FreeSync je vhodný pro hráče i pracovní úkoly.', NULL, 30),
(101, 6, 280.78, 'Acer Nitro VG240YB', 'Monitor Acer Nitro VG240YB nabízí Full HD rozlišení a 23.8 palce úhlopříčky. S rychlou odezvou 1 ms a technologií FreeSync je vhodný pro hráče.', NULL, 45),
(102, 7, 58.49, 'Logitech K480', 'Klávesnice Logitech K480 je kompaktním modelem s podporou pro více zařízení. Bezdrátové připojení a integrovaný stojánek zajišťují pohodlné používání.', NULL, 50),
(103, 7, 81.89, 'Corsair K55 RGB', 'Herní klávesnice Corsair K55 RGB nabízí programovatelné klávesy a RGB podsvícení. Anti-ghosting technologie a multimediální ovládání zlepšují herní zážitek.', NULL, 40),
(104, 7, 140.40, 'Razer Huntsman Elite', 'Herní klávesnice Razer Huntsman Elite je vybavena opto-mechanickými spínači pro rychlou odezvu. RGB podsvícení a programovatelné klávesy jsou ideální pro hráče.', NULL, 35),
(105, 7, 105.29, 'SteelSeries Apex Pro', 'Herní klávesnice SteelSeries Apex Pro nabízí programovatelné spínače s nastavitelnou odezvou. RGB podsvícení a podpora pro zápěstí zvyšují komfort hráčů.', NULL, 45),
(106, 7, 46.79, 'HP Slim 450', 'Klávesnice HP Slim 450 je tenkým modelem pro běžné uživatele. Tiché klávesy a kompaktní design jsou vhodné pro práci i domácí použití.', NULL, 55),
(107, 7, 70.18, 'Logitech G Pro X', 'Herní klávesnice Logitech G Pro X nabízí vyměnitelné spínače pro přizpůsobení. Kompaktní design a RGB podsvícení jsou ideální pro profesionální hráče.', NULL, 40),
(108, 7, 152.08, 'HyperX Alloy FPS RGB', 'Herní klávesnice HyperX Alloy FPS RGB nabízí lineární mechanické spínače pro rychlou odezvu. RGB podsvícení a odolná konstrukce jsou vhodné pro hráče.', NULL, 35),
(109, 7, 93.58, 'Cooler Master CK550', 'Herní klávesnice Cooler Master CK550 poskytuje spolehlivé mechanické spínače pro hráče. RGB podsvícení a odolná konstrukce zlepšují herní výkon.', NULL, 39),
(110, 7, 52.65, 'Dell KB216', 'Klávesnice Dell KB216 je jednoduchým modelem pro každodenní použití. Tiché klávesy a standardní rozložení zajišťují komfortní psaní.', NULL, 60),
(111, 7, 81.89, 'Logitech G Pro', 'Herní klávesnice Logitech G Pro je kompaktním modelem pro hráče. Tiché mechanické spínače a odolný design jsou ideální pro turnaje a závody.', NULL, 48),
(112, 8, 35.08, 'Logitech M185', 'Myš Logitech M185 nabízí spolehlivý a bezdrátový způsob ovládání. Kompaktní design a tříletá výdrž baterie jsou vhodné pro každodenní použití.', NULL, 61),
(113, 8, 70.18, 'Razer DeathAdder Elite', 'Herní myš Razer DeathAdder Elite nabízí optický senzor s vysokou přesností. Ergonomický tvar a programovatelná tlačítka jsou vhodné pro hráče.', NULL, 40),
(114, 8, 116.99, 'SteelSeries Rival 600', 'Herní myš SteelSeries Rival 600 je vybavena dvěma senzory pro precizní sledování pohybu. Váhový systém a odolná konstrukce jsou vhodné pro hráče.', NULL, 35),
(115, 8, 46.79, 'HP X500', 'Myš HP X500 nabízí spolehlivý a pohodlný způsob ovládání. Optický senzor a ergonomický tvar jsou vhodné pro práci i každodenní použití.', NULL, 50),
(116, 8, 93.58, 'Logitech G Pro Wireless', 'Herní myš Logitech G Pro Wireless je bezdrátovým modelem s vysokou přesností. Kompaktní design a nízká hmotnost jsou ideální pro profesionální hráče.', NULL, 37),
(117, 8, 58.49, 'Corsair Harpoon RGB', 'Herní myš Corsair Harpoon RGB nabízí optický senzor s rychlou odezvou. Lehký design a programovatelná tlačítka jsou ideální pro hráče.', NULL, 45),
(118, 8, 29.24, 'Dell MS116', 'Myš Dell MS116 je jednoduchým modelem pro každodenní použití. Optický senzor a standardní design zajišťují spolehlivý výkon.', NULL, 60),
(119, 8, 64.33, 'Logitech G502 Hero', 'Herní myš Logitech G502 Hero nabízí vysokou přesnost a programovatelná tlačítka. Ergonomický design a RGB podsvícení jsou ideální pro hráče.', NULL, 40),
(120, 8, 105.29, 'Razer Naga X', 'Herní myš Razer Naga X nabízí mnoho programovatelných tlačítek pro MMO hráče. Optický senzor a odolná konstrukce jsou vhodné pro náročné hráče.', NULL, 32),
(121, 8, 40.94, 'HP Z3700', 'Myš HP Z3700 nabízí bezdrátový způsob ovládání a kompaktní design. Optický senzor a tiché tlačítka jsou vhodné pro každodenní použití.', NULL, 50),
(122, 9, 11.69, 'AmazonBasics HDMI Cable', 'HDMI cable from AmazonBasics with high-speed performance. Supports 4K resolution and is suitable for connecting devices to TVs and monitors.', NULL, 100),
(123, 9, 15.20, 'Anker USB-C to USB-A Adapter', 'Adapter from Anker for converting USB-C to USB-A. Allows you to connect USB-A devices to USB-C ports.', NULL, 80),
(124, 9, 9.35, 'UGREEN 3.5mm Audio Cable', 'Audio cable from UGREEN with 3.5mm connectors. Ideal for connecting smartphones or laptops to speakers or headphones.', NULL, 120),
(125, 9, 23.39, 'Cable Matters DisplayPort to HDMI Adapter', 'DisplayPort to HDMI adapter from Cable Matters. Enables you to connect a DisplayPort source to an HDMI display.', NULL, 60),
(126, 9, 17.55, 'Apple Lightning to USB Cable', 'Apple Lightning to USB cable for charging and syncing iOS devices. Genuine Apple product for reliable performance.', NULL, 100),
(127, 9, 10.52, 'UGREEN USB 3.0 Extension Cable', 'USB 3.0 extension cable from UGREEN. Extends the reach of your USB devices and supports high-speed data transfer.', NULL, 150),
(128, 9, 14.03, 'AmazonBasics USB-C to USB-A Cable', 'USB-C to USB-A cable from AmazonBasics. Suitable for charging and data transfer between USB-C and USB-A devices.', NULL, 120),
(129, 9, 8.18, 'Belkin Ethernet Cable', 'Ethernet cable from Belkin for reliable wired network connections. Available in various lengths for different setups.', NULL, 200),
(130, 9, 29.24, 'Dell USB-C to HDMI/VGA/Ethernet/USB Adapter', 'Multi-port adapter from Dell with USB-C interface. Provides HDMI, VGA, Ethernet, and USB connections in one compact device.', NULL, 40),
(131, 9, 19.88, 'CableCreation USB-C to USB-C Cable', 'USB-C to USB-C cable from CableCreation. Supports fast charging and data transfer between USB-C devices.', NULL, 100),
(132, 9, 16.37, 'UGREEN USB-C to HDMI Adapter', 'USB-C to HDMI adapter from UGREEN. Allows you to connect USB-C devices to HDMI displays or projectors.', NULL, 80),
(133, 9, 12.85, 'AmazonBasics USB 3.0 Cable', 'USB 3.0 cable from AmazonBasics for high-speed data transfer and device charging. Available in various lengths.', NULL, 150),
(134, 9, 22.23, 'Anker Powerline+ Lightning Cable', 'Durable Lightning cable from Anker with reinforced connectors. Supports fast charging and data syncing.', NULL, 100),
(135, 9, 25.74, 'Cable Matters USB-C to DisplayPort Cable', 'USB-C to DisplayPort cable from Cable Matters. Connects USB-C devices to DisplayPort monitors or projectors.', NULL, 70),
(136, 9, 7.00, 'UGREEN USB-C to USB 3.0 Adapter', 'USB-C to USB 3.0 adapter from UGREEN. Allows you to connect USB 3.0 devices to USB-C ports.', NULL, 117),
(137, 9, 18.71, 'Apple USB-C to 3.5mm Headphone Jack Adapter', 'Apple USB-C to 3.5mm headphone jack adapter. Enables you to connect standard headphones to USB-C devices.', NULL, 90),
(138, 9, 11.69, 'AmazonBasics Mini DisplayPort to HDMI Cable', 'Mini DisplayPort to HDMI cable from AmazonBasics. Connects Mini DisplayPort devices to HDMI displays.', NULL, 110),
(139, 9, 26.90, 'Belkin USB-C to Gigabit Ethernet Adapter', 'USB-C to Gigabit Ethernet adapter from Belkin. Provides a reliable wired network connection for USB-C devices.', NULL, 50),
(140, 9, 10.52, 'UGREEN HDMI to VGA Adapter', 'HDMI to VGA adapter from UGREEN. Converts HDMI signals to VGA for connecting modern devices to VGA displays.', NULL, 80),
(141, 9, 14.03, 'Cable Matters USB 2.0 Printer Cable', 'USB 2.0 printer cable from Cable Matters. Connects printers and other USB devices to computers for data transfer and printing.', NULL, 140),
(142, 10, 35.08, 'Cooler Master Hyper 212 RGB', 'Cooler Master Hyper 212 RGB is a popular air cooler for CPUs. It offers efficient cooling and features RGB lighting for customization.', NULL, 80),
(143, 10, 70.18, 'NZXT Kraken X53', 'NZXT Kraken X53 is a liquid CPU cooler with a 240mm radiator. It provides excellent cooling performance and features customizable RGB lighting.', NULL, 60),
(144, 10, 52.65, 'Corsair H100i RGB Platinum', 'Corsair H100i RGB Platinum is a liquid CPU cooler with a 240mm radiator. It features RGB lighting and offers efficient cooling for high-performance CPUs.', NULL, 69),
(145, 10, 46.79, 'be quiet! Dark Rock Pro 4', 'be quiet! Dark Rock Pro 4 is a high-end air cooler for CPUs. It offers silent and effective cooling with a dual-tower design.', NULL, 50),
(146, 10, 81.89, 'Noctua NH-D15', 'Noctua NH-D15 is a premium air cooler known for its excellent cooling performance and quiet operation. It features dual fans and a large heatsink.', NULL, 40),
(147, 10, 58.49, 'Arctic Liquid Freezer II 240', 'Arctic Liquid Freezer II 240 is a liquid CPU cooler with a 240mm radiator. It provides strong cooling performance and comes with efficient fans.', NULL, 60),
(148, 10, 40.94, 'Cooler Master Hyper 212 Black Edition', 'Cooler Master Hyper 212 Black Edition is an updated version of the popular air cooler. It offers effective cooling and a sleek black design.', NULL, 90),
(149, 10, 93.58, 'NZXT Kraken X73', 'NZXT Kraken X73 is a liquid CPU cooler with a 360mm radiator. It provides powerful cooling and features a customizable LCD display.', NULL, 40),
(150, 10, 64.33, 'Corsair H115i RGB Platinum', 'Corsair H115i RGB Platinum is a liquid CPU cooler with a 280mm radiator. It offers efficient cooling and features RGB lighting for aesthetics.', NULL, 50),
(151, 10, 58.49, 'Deepcool Gammaxx GT', 'Deepcool Gammaxx GT is an air cooler with RGB lighting. It provides good cooling performance and adds visual flair to your system.', NULL, 70),
(152, 10, 70.18, 'Arctic Liquid Freezer II 280', 'Arctic Liquid Freezer II 280 is a liquid CPU cooler with a 280mm radiator. It offers strong cooling performance and efficient fans.', NULL, 60),
(153, 10, 105.29, 'Noctua NH-D15S', 'Noctua NH-D15S is a variation of the NH-D15 air cooler. It offers the same performance but with better compatibility for RAM and PCIe slots.', NULL, 39),
(154, 10, 76.04, 'Cooler Master MasterLiquid ML240L', 'Cooler Master MasterLiquid ML240L is a liquid CPU cooler with a 240mm radiator. It features RGB lighting and offers good cooling performance.', NULL, 80),
(155, 10, 46.79, 'be quiet! Pure Rock 2', 'be quiet! Pure Rock 2 is an affordable air cooler for CPUs. It provides solid cooling performance and low noise levels.', NULL, 100),
(156, 10, 87.74, 'Corsair iCUE H150i Elite Capellix', 'Corsair iCUE H150i Elite Capellix is a liquid CPU cooler with a 360mm radiator. It features customizable RGB lighting and powerful cooling.', NULL, 50),
(157, 10, 64.33, 'Scythe Mugen 5 Rev.B', 'Scythe Mugen 5 Rev.B is an air cooler known for its performance and quiet operation. It offers a compact design and efficient cooling.', NULL, 46),
(158, 10, 81.89, 'Fractal Design Celsius S24', 'Fractal Design Celsius S24 is a liquid CPU cooler with a 240mm radiator. It offers good cooling performance and a sleek design.', NULL, 70),
(159, 10, 70.18, 'ID-COOLING SE-224-XT RGB', 'ID-COOLING SE-224-XT RGB is an air cooler with RGB lighting. It provides decent cooling performance and adds visual effects to your system.', NULL, 80),
(160, 10, 99.44, 'Cooler Master MasterLiquid ML360R', 'Cooler Master MasterLiquid ML360R is a liquid CPU cooler with a 360mm radiator. It features RGB lighting and offers efficient cooling.', NULL, 40),
(161, 10, 58.49, 'Arctic Freezer 34 eSports DUO', 'Arctic Freezer 34 eSports DUO is an air cooler with dual fans and a stylish design. It offers good cooling performance and low noise.', NULL, 70),
(162, 11, 935.98, 'Dell XPS 13', 'Dell XPS 13 is a premium ultrabook with a sleek design and powerful performance. Features a high-resolution display and long battery life.', NULL, 50),
(163, 11, 1169.97, 'Apple MacBook Air', 'Apple MacBook Air is a lightweight laptop known for its build quality and integration with macOS. Offers a Retina display and fast SSD.', NULL, 40),
(164, 11, 1052.97, 'HP Spectre x360', 'HP Spectre x360 is a versatile 2-in-1 laptop with a convertible design. It features a touchscreen display, powerful internals, and premium build.', NULL, 60),
(165, 11, 818.98, 'Acer Swift 3', 'Acer Swift 3 is a budget-friendly ultrabook with solid performance and a thin profile. Suitable for everyday tasks and productivity.', NULL, 80),
(166, 11, 1520.97, 'Lenovo ThinkPad X1 Carbon', 'Lenovo ThinkPad X1 Carbon is a business-focused laptop with a durable build and security features. Offers a comfortable keyboard and high-resolution display.', NULL, 30),
(167, 11, 1403.97, 'Asus ROG Zephyrus G14', 'Asus ROG Zephyrus G14 is a gaming laptop with a compact design and powerful hardware. Features a high-refresh-rate display and AMD Ryzen processor.', NULL, -5),
(168, 11, 935.98, 'Microsoft Surface Laptop 4', 'Microsoft Surface Laptop 4 is a stylish laptop with a touchscreen display. Offers good performance and the familiarity of Windows 10.', NULL, 50),
(169, 11, 1286.97, 'Dell Inspiron 15 7000', 'Dell Inspiron 15 7000 is a mid-range laptop with a balance of performance and affordability. Suitable for multitasking and entertainment.', NULL, 48),
(170, 11, 1169.97, 'HP Envy x360', 'HP Envy x360 is a 2-in-1 laptop with an AMD Ryzen processor. Features a touchscreen display and versatile design for both work and play.', NULL, 44),
(171, 11, 1754.96, 'Apple MacBook Pro', 'Apple MacBook Pro is a professional-grade laptop with powerful hardware and a Retina display. Suitable for content creation and demanding tasks.', NULL, 40),
(172, 11, 701.98, 'Acer Aspire 5', 'Acer Aspire 5 is a budget laptop with a larger display and decent performance for everyday computing. Offers a good value for its price.', NULL, 70),
(173, 11, 1052.97, 'Lenovo Yoga C740', 'Lenovo Yoga C740 is a 2-in-1 laptop with a flexible hinge design. Features a touchscreen display and a slim profile for on-the-go use.', NULL, 60),
(174, 11, 1520.97, 'Razer Blade 15', 'Razer Blade 15 is a gaming laptop with a sleek design and powerful graphics. Offers high-refresh-rate display options and customizable RGB lighting.', NULL, 30),
(175, 11, 818.98, 'Asus VivoBook S14', 'Asus VivoBook S14 is a stylish laptop with modern aesthetics. Offers a good balance of performance and portability for students and professionals.', NULL, 70),
(176, 11, 1403.97, 'HP Omen 15', 'HP Omen 15 is a gaming laptop with a bold design and performance-focused hardware. Offers high-refresh-rate display options and RGB lighting.', NULL, 40),
(177, 11, 935.98, 'Dell Inspiron 14', 'Dell Inspiron 14 is a budget-friendly laptop with a compact design. Suitable for basic tasks and entertainment on the go.', NULL, 80),
(178, 11, 1286.97, 'Lenovo IdeaPad Flex 5', 'Lenovo IdeaPad Flex 5 is a 2-in-1 laptop with a flexible hinge. Offers good performance and versatile design for various usage scenarios.', NULL, 60),
(179, 11, 1052.97, 'Microsoft Surface Laptop Go', 'Microsoft Surface Laptop Go is a lightweight and compact laptop with a focus on portability. Offers a touchscreen display and Windows 10 experience.', NULL, 70),
(180, 11, 1520.97, 'Acer Predator Helios 300', 'Acer Predator Helios 300 is a gaming laptop with powerful graphics and cooling. Offers a high-refresh-rate display for smooth gaming performance.', NULL, 30),
(181, 11, 1169.97, 'Asus ZenBook 14', 'Asus ZenBook 14 is a sleek and compact laptop with a focus on portability. Offers a thin profile and good performance for professionals.', NULL, 50),
(182, 12, 1169.97, 'Dell XPS Tower', 'Dell XPS Tower is a high-performance desktop computer with powerful hardware for various tasks. Offers a sleek design and ample connectivity options.', NULL, 40),
(183, 12, 1520.97, 'HP Pavilion Gaming Desktop', 'HP Pavilion Gaming Desktop is a mid-range gaming PC with balanced performance. Suitable for gaming and entertainment.', NULL, 35),
(184, 12, 935.98, 'Acer Aspire TC', 'Acer Aspire TC is a budget-friendly desktop computer for everyday computing tasks. Offers a reliable performance for home and office use.', NULL, 70),
(185, 12, 1754.96, 'Lenovo ThinkCentre M920', 'Lenovo ThinkCentre M920 is a business-oriented desktop computer with security features and performance for professional use.', NULL, 30),
(186, 12, 1286.97, 'Asus ROG Strix G15', 'Asus ROG Strix G15 is a gaming desktop with powerful hardware for smooth gameplay. Features a bold design and customizable RGB lighting.', NULL, 40),
(187, 12, 818.98, 'Dell Inspiron 3880', 'Dell Inspiron 3880 is a compact desktop computer with reliable performance for everyday tasks. Suitable for home and office use.', NULL, 60),
(188, 12, 1403.97, 'HP Envy Desktop', 'HP Envy Desktop is a stylish desktop computer with modern aesthetics and solid performance. Suitable for multitasking and entertainment.', NULL, 49),
(189, 12, 1052.97, 'Lenovo IdeaCentre 5', 'Lenovo IdeaCentre 5 is a versatile desktop computer for a range of tasks. Offers a balance of performance and value for everyday use.', NULL, 60),
(190, 12, 1988.95, 'Alienware Aurora R10', 'Alienware Aurora R10 is a gaming desktop with high-performance hardware and a distinctive design. Offers powerful gaming capabilities.', NULL, 30),
(191, 12, 1520.97, 'MSI Trident 3', 'MSI Trident 3 is a compact gaming desktop with a small form factor. Offers a balance of performance and space-saving design.', NULL, 37),
(192, 12, 935.98, 'CyberPowerPC Gamer Xtreme', 'CyberPowerPC Gamer Xtreme is a gaming desktop with customizable components for different gaming needs. Offers good value for performance.', NULL, 50),
(193, 12, 1286.97, 'HP Slim Desktop', 'HP Slim Desktop is a budget-friendly and compact desktop computer for basic computing tasks. Suitable for small spaces and limited budgets.', NULL, 70),
(194, 12, 1754.96, 'Lenovo Legion Tower 5', 'Lenovo Legion Tower 5 is a gaming desktop with performance-focused hardware. Features a bold design and customizable RGB lighting.', NULL, 40),
(195, 12, 1052.97, 'Dell Inspiron 5000', 'Dell Inspiron 5000 is a mid-range desktop computer with a balance of performance and affordability. Suitable for a range of tasks.', NULL, 60),
(196, 12, 1520.97, 'Acer Predator Orion 9000', 'Acer Predator Orion 9000 is a high-end gaming desktop with powerful hardware for demanding games. Offers a distinctive design.', NULL, 30),
(197, 12, 818.98, 'HP Pavilion Desktop', 'HP Pavilion Desktop is a versatile desktop computer with good performance for everyday tasks and entertainment. Suitable for home use.', NULL, 80),
(198, 12, 1403.97, 'Asus VivoPC X', 'Asus VivoPC X is a compact gaming desktop with VR-ready hardware. Offers a small footprint and powerful performance for gaming and content creation.', NULL, 35),
(199, 12, 1169.97, 'Lenovo IdeaCentre AIO 3', 'Lenovo IdeaCentre AIO 3 is an all-in-one desktop computer with a space-saving design. Offers a balance of performance and simplicity.', NULL, 50),
(200, 12, 1988.95, 'Corsair One i160', 'Corsair One i160 is a compact and powerful gaming desktop with high-performance components. Suitable for enthusiasts and gamers.', NULL, 30),
(201, 12, 1520.97, 'HP EliteDesk 800 G6', 'HP EliteDesk 800 G6 is a business-oriented desktop computer with security features and professional performance. Suitable for office use.', NULL, 40);

-- --------------------------------------------------------

--
-- Table structure for table `product_category`
--

CREATE TABLE `product_category` (
  `category_id` int NOT NULL,
  `parent_category_id` int DEFAULT NULL,
  `category_name` varchar(100) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `product_category`
--

INSERT INTO `product_category` (`category_id`, `parent_category_id`, `category_name`) VALUES
(1, NULL, 'PC Komponenty'),
(2, 1, 'Procesory'),
(3, 1, 'Grafické Karty'),
(4, 1, 'Paměti a Úložiště'),
(5, 1, 'Napájecí Zdroje'),
(6, NULL, 'Periferie'),
(7, 6, 'Monitory'),
(8, 6, 'Klávesnice a Myši'),
(9, NULL, 'Příslušenství'),
(10, 9, 'Kabely a Adaptéry'),
(11, 9, 'Chladící Řešení'),
(12, NULL, 'Notebooky a Stolní Počítače'),
(13, 12, 'Notebooky'),
(14, 12, 'Stolní Počítače');

-- --------------------------------------------------------

--
-- Table structure for table `region`
--

CREATE TABLE `region` (
  `RegionID` int NOT NULL,
  `RegionName` varchar(255) NOT NULL,
  `CountryID` int DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `region`
--

INSERT INTO `region` (`RegionID`, `RegionName`, `CountryID`) VALUES
(1, 'Moskovskaya oblast', 1),
(2, 'Yaroslavkaya oblast', 1),
(3, 'Středočeský kraj', 2),
(4, 'ústecký kraj', 2);

-- --------------------------------------------------------

--
-- Table structure for table `shopping_cart`
--

CREATE TABLE `shopping_cart` (
  `id` int NOT NULL,
  `user_id` int DEFAULT NULL,
  `id_if_ordered` int DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `shopping_cart`
--

INSERT INTO `shopping_cart` (`id`, `user_id`, `id_if_ordered`) VALUES
(1, 1, NULL),
(2, 2, NULL),
(3, 3, NULL),
(4, 4, NULL),
(5, 5, NULL),
(6, 6, NULL),
(7, 7, NULL),
(8, 8, NULL),
(9, 9, NULL),
(10, 10, NULL),
(11, 11, NULL),
(12, 12, NULL),
(13, 13, NULL),
(14, 14, NULL),
(15, 15, NULL),
(16, 16, NULL),
(17, 17, NULL),
(18, 18, NULL),
(19, 19, NULL),
(20, 20, NULL),
(21, 1, NULL),
(22, 2, NULL),
(23, 3, NULL),
(24, 4, NULL),
(25, 5, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `shopping_cart_item`
--

CREATE TABLE `shopping_cart_item` (
  `id` int NOT NULL,
  `product_id` int DEFAULT NULL,
  `shopping_cart_id` int DEFAULT NULL,
  `qty` int DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `shopping_cart_item`
--

INSERT INTO `shopping_cart_item` (`id`, `product_id`, `shopping_cart_id`, `qty`) VALUES
(1, 1, 1, 1),
(2, 2, 1, 1),
(3, 3, 2, 1),
(4, 4, 2, 1),
(5, 5, 3, 1),
(6, 6, 3, 1),
(7, 7, 4, 1),
(8, 8, 4, 1),
(9, 9, 5, 1),
(10, 10, 5, 1),
(11, 11, 6, 1),
(12, 12, 6, 1),
(13, 13, 7, 1),
(14, 14, 7, 1),
(15, 15, 8, 1),
(16, 16, 8, 1),
(17, 17, 9, 1),
(18, 18, 9, 1),
(19, 19, 10, 1),
(20, 20, 10, 1);

-- --------------------------------------------------------

--
-- Table structure for table `shop_order`
--

CREATE TABLE `shop_order` (
  `id` int NOT NULL,
  `user_id` int DEFAULT NULL,
  `order_date` date DEFAULT NULL,
  `shopping_adress` int DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `shop_order`
--

INSERT INTO `shop_order` (`id`, `user_id`, `order_date`, `shopping_adress`) VALUES
(12, 1, '2023-09-10', 52),
(13, 2, '2023-09-05', 52),
(14, 3, '2023-09-06', 53),
(15, 4, '2023-08-29', 54),
(16, 5, '2023-09-11', 55),
(17, 6, '2023-09-13', 56),
(18, 7, '2023-09-11', 57),
(19, 8, '2023-08-27', 58);

-- --------------------------------------------------------

--
-- Table structure for table `uzivatel`
--

CREATE TABLE `uzivatel` (
  `user_id` int NOT NULL,
  `jmeno_a_prijmeni` varchar(50) DEFAULT NULL,
  `email` varchar(50) DEFAULT NULL,
  `cislo_telefonu` varchar(15) DEFAULT NULL,
  `Heslo` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `uzivatel`
--

INSERT INTO `uzivatel` (`user_id`, `jmeno_a_prijmeni`, `email`, `cislo_telefonu`, `Heslo`) VALUES
(1, 'Updated Doe', 'john@example.com', '1234567890', 'password123'),
(2, 'Jane Smith', 'jane@example.com', '9876543210', 'mypassword'),
(3, 'Alice Johnson', 'alice@example.com', '5555555555', 'securepass'),
(4, 'Michael Brown', 'michael@example.com', '1112223333', 'userpass'),
(5, 'Emily Williams', 'emily@example.com', '4445556666', 'letmein'),
(6, 'Daniel Miller', 'daniel@example.com', '7778889999', 'mypassword123'),
(7, 'Olivia Davis', 'olivia@example.com', '3334445555', 'oliviapass'),
(8, 'David Jones', 'david@example.com', '6667778888', 'david123'),
(9, 'Sophia Taylor', 'sophia@example.com', '9990001111', '123456789'),
(10, 'Joseph Anderson', 'joseph@example.com', '2223334444', 'andersonpass'),
(11, 'William Thomas', 'william@example.com', '5556667777', 'thomas123'),
(12, 'Ava Lee', 'ava@example.com', '8889990000', 'avapass'),
(13, 'James White', 'james@example.com', '4445556666', 'white123'),
(14, 'Ella Hall', 'ella@example.com', '7778889999', 'hallpass'),
(15, 'Benjamin King', 'benjamin@example.com', '3334445555', 'benjaminpass'),
(16, 'Mia Scott', 'mia@example.com', '6667778888', 'scottpass'),
(17, 'Logan Green', 'logan@example.com', '9990001111', 'green123'),
(18, 'Emma Adams', 'emma@example.com', '2223334444', 'adams123'),
(19, 'Alexander Wright', 'alexander@example.com', '5556667777', 'wrightpass'),
(20, 'Sophia Robinson', 'sophia@example.com', '8889990000', 'sophiarobinson'),
(21, 'Petr Novák', 'petr.novak@gmail.com', '420123456789', 'password1'),
(22, 'Jana Svobodová', 'jana.svobodova@gmail.com', '420234567890', 'password2'),
(23, 'Lukáš Dvořák', 'lukas.dvorak@gmail.com', '420345678901', 'password3'),
(24, 'Eva Marešová', 'eva.maresova@gmail.com', '420456789012', 'password4'),
(25, 'Tomáš Procházka', 'tomas.prochazka@gmail.com', '420567890123', 'password5'),
(26, 'Rafael Gumerov', 'gumer@emample.com', '3324234', 'fsadlkfjsld');

--
-- Triggers `uzivatel`
--
DELIMITER $$
CREATE TRIGGER `uzivatel_delete_trigger` BEFORE DELETE ON `uzivatel` FOR EACH ROW BEGIN
    INSERT INTO audit_log (operation, table_name, record_id, old_name)
    VALUES ('DELETE', 'uzivatel', OLD.user_id, OLD.jmeno_a_prijmeni);
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `uzivatel_insert_trigger` AFTER INSERT ON `uzivatel` FOR EACH ROW BEGIN
    INSERT INTO audit_log (operation, table_name, record_id, new_name)
    VALUES ('INSERT', 'uzivatel', NEW.user_id, NEW.jmeno_a_prijmeni);
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `uzivatel_update_trigger` AFTER UPDATE ON `uzivatel` FOR EACH ROW BEGIN
    INSERT INTO audit_log (operation, table_name, record_id, old_name, new_name)
    VALUES ('UPDATE', 'uzivatel', NEW.user_id, OLD.jmeno_a_prijmeni, NEW.jmeno_a_prijmeni);
END
$$
DELIMITER ;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `address`
--
ALTER TABLE `address`
  ADD PRIMARY KEY (`adress_id`),
  ADD KEY `user_id` (`user_id`),
  ADD KEY `city_id` (`city_id`);

--
-- Indexes for table `audit_log`
--
ALTER TABLE `audit_log`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `city`
--
ALTER TABLE `city`
  ADD PRIMARY KEY (`CityID`),
  ADD KEY `RegionID` (`RegionID`);

--
-- Indexes for table `country`
--
ALTER TABLE `country`
  ADD PRIMARY KEY (`CountryID`);

--
-- Indexes for table `order_product`
--
ALTER TABLE `order_product`
  ADD KEY `product_id` (`product_id`),
  ADD KEY `order_id` (`order_id`);

--
-- Indexes for table `product`
--
ALTER TABLE `product`
  ADD PRIMARY KEY (`product_id`),
  ADD KEY `category_id` (`category_id`);
ALTER TABLE `product` ADD FULLTEXT KEY `indx` (`product_name`);

--
-- Indexes for table `product_category`
--
ALTER TABLE `product_category`
  ADD PRIMARY KEY (`category_id`),
  ADD KEY `parent_category_id` (`parent_category_id`);

--
-- Indexes for table `region`
--
ALTER TABLE `region`
  ADD PRIMARY KEY (`RegionID`),
  ADD KEY `CountryID` (`CountryID`);

--
-- Indexes for table `shopping_cart`
--
ALTER TABLE `shopping_cart`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_cart_user` (`user_id`),
  ADD KEY `id_if_ordered` (`id_if_ordered`);

--
-- Indexes for table `shopping_cart_item`
--
ALTER TABLE `shopping_cart_item`
  ADD PRIMARY KEY (`id`),
  ADD KEY `shopping_cart_id` (`shopping_cart_id`),
  ADD KEY `product_id` (`product_id`);

--
-- Indexes for table `shop_order`
--
ALTER TABLE `shop_order`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_order_adress` (`user_id`),
  ADD KEY `fk_shop_orders_adress` (`shopping_adress`);

--
-- Indexes for table `uzivatel`
--
ALTER TABLE `uzivatel`
  ADD PRIMARY KEY (`user_id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `address`
--
ALTER TABLE `address`
  MODIFY `adress_id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=72;

--
-- AUTO_INCREMENT for table `audit_log`
--
ALTER TABLE `audit_log`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT for table `product`
--
ALTER TABLE `product`
  MODIFY `product_id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=202;

--
-- AUTO_INCREMENT for table `product_category`
--
ALTER TABLE `product_category`
  MODIFY `category_id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=15;

--
-- AUTO_INCREMENT for table `shopping_cart`
--
ALTER TABLE `shopping_cart`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=26;

--
-- AUTO_INCREMENT for table `shopping_cart_item`
--
ALTER TABLE `shopping_cart_item`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=21;

--
-- AUTO_INCREMENT for table `shop_order`
--
ALTER TABLE `shop_order`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=20;

--
-- AUTO_INCREMENT for table `uzivatel`
--
ALTER TABLE `uzivatel`
  MODIFY `user_id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=27;

-- --------------------------------------------------------

--
-- Structure for view `expensive_products`
--
DROP TABLE IF EXISTS `expensive_products`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `expensive_products`  AS SELECT `product`.`product_name` AS `product_name`, `product`.`price` AS `price` FROM `product` WHERE (`product`.`price` > 100) ;

-- --------------------------------------------------------

--
-- Structure for view `names_of_product_and_customer_name`
--
DROP TABLE IF EXISTS `names_of_product_and_customer_name`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `names_of_product_and_customer_name`  AS SELECT `u`.`jmeno_a_prijmeni` AS `jmeno_a_prijmeni`, `u`.`email` AS `email`, `p`.`product_name` AS `product_name`, `p`.`price` AS `price` FROM (((`uzivatel` `u` join `shopping_cart` `sh` on((`u`.`user_id` = `sh`.`user_id`))) join `shopping_cart_item` `shi` on((`sh`.`id` = `shi`.`shopping_cart_id`))) join `product` `p` on((`shi`.`product_id` = `p`.`product_id`))) ;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `address`
--
ALTER TABLE `address`
  ADD CONSTRAINT `address_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `uzivatel` (`user_id`),
  ADD CONSTRAINT `address_ibfk_2` FOREIGN KEY (`city_id`) REFERENCES `city` (`CityID`),
  ADD CONSTRAINT `address_ibfk_3` FOREIGN KEY (`city_id`) REFERENCES `city` (`CityID`);

--
-- Constraints for table `city`
--
ALTER TABLE `city`
  ADD CONSTRAINT `city_ibfk_1` FOREIGN KEY (`RegionID`) REFERENCES `region` (`RegionID`);

--
-- Constraints for table `order_product`
--
ALTER TABLE `order_product`
  ADD CONSTRAINT `order_product_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `product` (`product_id`),
  ADD CONSTRAINT `order_product_ibfk_2` FOREIGN KEY (`order_id`) REFERENCES `shop_order` (`id`);

--
-- Constraints for table `product`
--
ALTER TABLE `product`
  ADD CONSTRAINT `product_ibfk_1` FOREIGN KEY (`category_id`) REFERENCES `product_category` (`category_id`);

--
-- Constraints for table `product_category`
--
ALTER TABLE `product_category`
  ADD CONSTRAINT `product_category_ibfk_1` FOREIGN KEY (`parent_category_id`) REFERENCES `product_category` (`category_id`);

--
-- Constraints for table `region`
--
ALTER TABLE `region`
  ADD CONSTRAINT `region_ibfk_1` FOREIGN KEY (`CountryID`) REFERENCES `country` (`CountryID`);

--
-- Constraints for table `shopping_cart`
--
ALTER TABLE `shopping_cart`
  ADD CONSTRAINT `fk_cart_user` FOREIGN KEY (`user_id`) REFERENCES `uzivatel` (`user_id`),
  ADD CONSTRAINT `shopping_cart_ibfk_1` FOREIGN KEY (`id_if_ordered`) REFERENCES `shop_order` (`id`);

--
-- Constraints for table `shopping_cart_item`
--
ALTER TABLE `shopping_cart_item`
  ADD CONSTRAINT `shopping_cart_item_ibfk_1` FOREIGN KEY (`shopping_cart_id`) REFERENCES `shopping_cart` (`id`),
  ADD CONSTRAINT `shopping_cart_item_ibfk_2` FOREIGN KEY (`product_id`) REFERENCES `product` (`product_id`);

--
-- Constraints for table `shop_order`
--
ALTER TABLE `shop_order`
  ADD CONSTRAINT `fk_order_user` FOREIGN KEY (`user_id`) REFERENCES `uzivatel` (`user_id`),
  ADD CONSTRAINT `fk_shop_orders_adress` FOREIGN KEY (`shopping_adress`) REFERENCES `address` (`adress_id`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
