--Вывести к каждому самолету класс обслуживания и количество мест этого класса

SELECT ad.aircraft_code,
       ad.model,
       s.fare_conditions,
       COUNT(s.fare_conditions) AS number_seats
FROM aircrafts_data AS ad
INNER JOIN seats AS s ON ad.aircraft_code = s.aircraft_code
GROUP BY ad.aircraft_code,
         ad.model,
         s.fare_conditions
ORDER BY ad.aircraft_code;

--Найти 3 самых вместительных самолета (модель + кол-во мест)

SELECT ad.model,
       COUNT(s.seat_no) AS number_seats
FROM aircrafts_data AS ad
INNER JOIN seats AS s ON ad.aircraft_code = s.aircraft_code
GROUP BY ad.model
ORDER BY number_seats DESC
LIMIT 3;

--Вывести код, модель самолета и места не эконом класса для самолета 'Аэробус A321-200' с сортировкой по местам

SELECT ad.aircraft_code,
       ad.model,
       s.seat_no
FROM aircrafts_data AS ad
INNER JOIN seats AS s ON ad.aircraft_code = s.aircraft_code
WHERE ad.model ->> 'ru' = 'Аэробус A321-200'
  AND s.fare_conditions != 'Economy'
ORDER BY s.seat_no;

--Вывести города в которых больше 1 аэропорта (код аэропорта, аэропорт, город)

SELECT airport_code,
       airport_name,
       city
FROM airports_data
WHERE city IN
      (SELECT city
       FROM airports_data
       GROUP BY city
       HAVING COUNT(city) > 1);

--Найти ближайший вылетающий рейс из Екатеринбурга в Москву, на который еще не завершилась регистрация

--Способ №1

SELECT f.*,
       d.city AS departure_city,
       a.city AS arrival_city
FROM flights AS f
INNER JOIN airports_data AS d ON f.departure_airport = d.airport_code
INNER JOIN airports_data AS a ON f.arrival_airport = a.airport_code
WHERE d.city ->> 'ru' = 'Екатеринбург'
  AND a.city ->> 'ru' = 'Москва'
  AND f.status IN ('Scheduled',
                   'On Time',
                   'Delayed')
  AND f.scheduled_departure > bookings.now()
ORDER BY f.scheduled_departure
LIMIT 1;

--Способ №2 (через представление)

SELECT * FROM flights_v
WHERE departure_city = 'Екатеринбург'
  AND arrival_city = 'Москва'
  AND status IN ('Scheduled',
                 'On Time',
                 'Delayed')
  AND scheduled_departure > bookings.now()
ORDER BY scheduled_departure
LIMIT 1;

--Вывести самый дешевый и дорогой билет и стоимость (в одном результирующем ответе)

--Способ №1

(SELECT * FROM ticket_flights
 ORDER BY amount
 LIMIT 1)
UNION
(SELECT * FROM ticket_flights
 ORDER BY amount DESC
 LIMIT 1);

--Способ №2

(SELECT * FROM ticket_flights
 WHERE amount =
       (SELECT MIN(amount)
        FROM ticket_flights)
 LIMIT 1)
UNION
(SELECT * FROM ticket_flights
 WHERE amount =
       (SELECT MAX(amount)
        FROM ticket_flights)
 LIMIT 1);

--Написать DDL таблицы Customers, должны быть поля id, firstName, LastName, email, phone. Добавить ограничения на поля (constraints).

CREATE TABLE IF NOT EXISTS customers (
    id         BIGSERIAL PRIMARY KEY,
    first_name VARCHAR(255) NOT NULL,
    last_name  VARCHAR(255) NOT NULL,
    email      VARCHAR(255) NOT NULL UNIQUE,
    phone      VARCHAR(255) NOT NULL UNIQUE
);

--Написать DDL таблицы Orders, должен быть id, customerId, quantity. Должен быть внешний ключ на таблицу customers + ограничения

CREATE TABLE IF NOT EXISTS orders (
    id          BIGSERIAL PRIMARY KEY,
    customer_id BIGINT NOT NULL,
    quantity    BIGINT NOT NULL CHECK (quantity > 0),
    FOREIGN KEY (customer_id) REFERENCES customers (id)
);

--Написать 5 insert в эти таблицы

INSERT INTO customers (first_name, last_name, email, phone)
VALUES ('Logan', 'Austin', 'logan.austin@gmail.com', '+1-252-427-9064'),
       ('Juan', 'Carrol', 'juan.carrol@gmail.com', '+1-372-540-1498'),
       ('Edward', 'Green', 'edward.green@gmail.com', '+1-310-765-6185'),
       ('Frank', 'Harris', 'frank.harris@gmail.com', '+1-741-888-2080'),
       ('Connon', 'Gilmore', 'connon.gilmore@gmail.com', '+1-748-684-1050');

INSERT INTO orders (customer_id, quantity)
VALUES (1, 50),
       (2, 27),
       (3, 63),
       (4, 15),
       (5, 128);

--Удалить таблицы

DROP TABLE orders;
DROP TABLE customers;

--Найти 3 самых популярных самолета по общей стоимости билетов на все их завершенные рейсы за август
--Вывести код, модель самолета и общую стоимость билетов

SELECT ad.aircraft_code,
       ad.model ->> 'ru' AS model,
       ta.ticket_amount
FROM aircrafts_data AS ad
INNER JOIN
     (SELECT f.aircraft_code,
             SUM(tf.amount) AS ticket_amount
      FROM flights AS f
      INNER JOIN ticket_flights AS tf ON f.flight_id = tf.flight_id
      WHERE f.status = 'Arrived'
        AND DATE_PART('month', f.actual_departure) = 8
      GROUP BY f.aircraft_code) AS ta ON ad.aircraft_code = ta.aircraft_code
ORDER BY ticket_amount DESC
LIMIT 3;
