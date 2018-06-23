use master
go
if not exists (select * from sys.databases where name = 'Bookstore')
   create database Bookstore
else  PRINT N'Database already exists' 
go
 
use Bookstore
go
 
create table Author(
   Id int primary key identity,
   Name nvarchar(80) not null
)
go
 
create table Books(
   Id int primary key identity,
   Title nvarchar(50) not null,
   EntryDate smalldatetime not null,
   DateOfrelease smalldatetime not null,
   Price money not null,
   Quantity  int not null default(1),
   AuthorId int not null
)
go
 
create table Seller(
   Id int primary key identity,
   Name nvarchar(80)
)
go
 
create table Customer(
   Id int primary key identity,
   Name nvarchar(80),
   Discount float not null default(0),
   [Sum] money not null default(0)
)
go
 
create table Selling(
   Id int primary key identity,
   BookId int not null,
   TimeSell smalldatetime not null,
   QuantitySelling int not null,
   SellerId int not null,
   CustomerId int not null
)
go
 
create table Bonus(
   Id int primary key identity,
   SellerId int not null,
   [Sum] money not null default(0)
)
go

INSERT INTO Author (Name)
VALUES 
('Taras Shevchenko'),
('Averchenko Arkadiy'),
('Brusilovskiy Rafail'),
('Gurlyand Ilya'),
('Gadan Sergey'),
('Zvonickiy Eduard'),
('Aleksandr Zorik'),
('Kvitka Ilya'),
('Kopilenko Aleksandr'),
('Sergienko Oksana')
go

select * from Books

INSERT INTO Books (Title, DateOfrelease, AuthorId, Quantity, EntryDate, Price)
VALUES 
('Одесские рассказы', 1911-06-06, 2, 15, getdate(), 85),
('Люди и грузы', 1935-03-03, 3, 20, getdate(), 90),
('Повесть в стихах «На кресте»', 1921-08-08, 4, 40, getdate(), 95),
('Генерал Юда', 1995-10-10, 5, 30, getdate(), 100),
('Наш Харьков', 2009-02-02, 6, 5, getdate(), 150),
('В тылу врага', 2004-02-04, 7, 35, getdate(), 200),
('Энциклопедический словарь Брокгауза и Ефрона ', 1809-02-12, 8, 35, getdate(), 250),
('Кара-Круча', 1923-03-08, 9, 25, getdate(), 300),
('Бруківка', 2008-09-02, 9, 25, getdate(), 350),
('Букварь', 1840-09-02, 1, 100, getdate(), 400),
('Про это', 1904-09-02, 2, 5, getdate(), 10)
go
insert into Books (Title, DateOfrelease, AuthorId, Quantity, EntryDate, Price)
VALUES ('Про это 2', 2016-09-09, 1, 1, getdate(), 1000) --для триггера
go

select * from Seller

INSERT INTO Seller (Name)
VALUES
('Винни-пух'),
('Пятачок'),
('Кролик'),
('Пинокио'),
('Ляшко')
go

select * from Customer

INSERT INTO Customer (Name, Discount, [Sum])
VALUES
('Супер покупатель', 0, 0),
('Так себе покупатель', 0, 0),
('Ни фига себе покупатель', 0, 0),
('Нормальный покупатель', 0, 0)
go

select * from Selling

INSERT INTO Selling(BookId, TimeSell, QuantitySelling, SellerId, CustomerId)
VALUES
(1, getdate(), 7, 3, 1),
(2, getdate() - 13, 3, 1, 2),
(3, getdate() - 26, 5, 4, 3),
(4, getdate() - 23, 2, 5, 2),
(5, getdate() - 23, 10, 2, 1),
(6, getdate() - 23, 5, 4, 3),
(7, getdate() - 22, 3, 3, 4),
(8, getdate() - 22, 8, 4, 2),
(9, getdate() - 15, 7, 2, 4),
(10, getdate() - 20, 2, 5, 2),
(11, getdate() - 20, 4, 4, 3),
(12, getdate() - 8, 1, 1, 3)
go

select * from Bonus

INSERT INTO Bonus (SellerId, [Sum])
VALUES
(1, 0),
(2, 0),
(3, 0),
(4, 0),
(5, 0)
go
------------------------------------
create procedure TopFivePopularBooks
as
begin
select top 5 Books.Title
from  Selling join Books
on Selling.BookId = Books.Id
order by Selling.QuantitySelling desc
end 
go

exec TopFivePopularBooks
go
------------------------------
create procedure TopAuthors
as
begin
select top 2 Author.Name
from Selling join Books
on Selling.Id = Books.Id join Author
on Books.AuthorId = Author.Id
order by Selling.QuantitySelling desc
end
go

exec TopAuthors
go
-----------------------------------------------

create procedure MinMaxPriceBoks
as
begin
select MAX(Books.Price) [Максимальная цена], MIN(Books.Price) [Минимальная цена] from Books 
end
go

exec MinMaxPriceBoks
go
-------------------------------------------------

create procedure TimeStatistics
as
begin
select top 3  TimeSell, COUNT(TimeSell) [Количество выполненных операций за время]
from Selling 
group by TimeSell
order by COUNT(TimeSell) desc
end
go

exec TimeStatistics
go
--------------------------------------------------

alter procedure TheBestSeller @startTime smalldatetime , @endTime smalldatetime
as
begin
select top 3 Seller.Name [Имя продавца], Selling.QuantitySelling [Проданные Книги]
from Selling join Seller
On Seller.Id = Selling.Id
where Selling.TimeSell between @startTime and @endTime
order by Selling.QuantitySelling desc
end
go

declare @startDate smalldatetime = '2016-10-16'
declare @endDate smalldatetime = '2016-12-16'
exec TheBestSeller @startDate, @endDate
go

-------------------------------------------------

--•	Сумму премий каждого продавца. Предположим, что премия рассчитывается по следующему алгоритму: 
--o	1000-1299 грн премия 10% от закупочной стоимости книг
--o	1300-1499 грн премия 15% от закупочной стоимости книг
--o	1500-1999 грн премия 25% от закупочной стоимости книг
--o	2000-3000 грн премия 40% от закупочной стоимости книг

create procedure Countbonus
as
begin
update Bonus
set [Sum] = (
select sum(Price * QuantitySelling)
from Selling join Books
on Selling.Id = Books.Id
where Bonus.SellerId = Selling.SellerId
)

update Bonus 
set [Sum] = 0
where [Sum] < 1000

update Bonus
set [Sum] = [Sum] * 0.1
where [Sum] between 1000 and 1299

update Bonus
set [Sum] = [Sum] * 0.15
where [Sum] between 1300 and 1499

update Bonus
set [Sum] = [Sum] * 0.25
where [Sum] between 1500 and 1999

update Bonus
set [Sum] = [Sum] * 0.4
where [Sum] >= 2000 and [Sum] <= 3000
end
go

------------------------------------------------
--Реализовать триггеры выполняющие следующие задачи:
--•	Возможность добавления новый книги только в 
--том случае если остаток на складе не превышает 25 штук.

create trigger CheckStorage
on Books
for insert
as
begin
if (select sum(Quantity)from Books) >= 25
begin
print ('There are more than 25 books in the storage')
rollback transaction
end
end
go

-----------------------------------------------------
--Реализовать триггеры выполняющие следующие задачи:
--•	Удалить (списать) книги только тогда, когда срок хранение на скале превысил 1 год.

create trigger SelfAfterOneYear
on Books
for delete 
as
begin
if (select count(EntryDate) from deleted where datediff(YEAR, EntryDate, getdate()) > 1) <> 0--Возвращает количество пересеченных
begin-- границ (целое число со знаком), указанных аргументом datepart, за период времени, указанный аргументами startdate и enddate
print ('Операция не может быть выполнена так как ни одна книга не превысила срок в один год')
rollback transaction
end
end
go

delete 
from Books 
where id = 1
go
------------------------------------------------------

--Реализовать пользовательскую функцию, которая считает скидку покупателя(по его ID). 
--Предположим: 
--•	покупка на сумму 100-299 гривен скидка составляет 2% 
--•	300-499 гривен скидка 5%
--•	500-999 гривен скидка 7%
--•	1000 и более скидка 10% 

create function DiscountCustomer(@customerId int)
returns float
as
begin
declare @result float
set @result = (select sum(Price * QuantitySelling)
from Selling join Books
on Selling.Id = Books.Id
where CustomerId = @customerId
)
if @result < 100
		set @result = 0;
	else if @result BETWEEN 100 AND 299
		set @result = @result * 0.02
	else if @result BETWEEN 300 AND 499
		set @result = @result * 0.05
	else if @result BETWEEN 500 AND 999
		set @result = @result * 0.07
	else
		set @result = @result * 0.1

	return @result
	end
	go

PRINT dbo.DiscountCustomer(1)
-----------------------------------------------------
--С помощью индексов выполнить индексирование необходимых полей в таблице «Книги». 
--Вам необходимо самостоятельно принять решение по каким полям делать индексы.

CREATE NONCLUSTERED INDEX index_for_ID_autor
ON dbo.Books(AuthorId)

-------------------------------------------------------
--Для доступа к  серверу БД создать 2 пользователей 
--с правами(админа) для руководителя магазина и 
--обычного пользователя(продавцов). 
--Вам необходимо самостоятельно выбрать, какими ролями уровня 
--БД будет наделен каждый из этих пользователей.

CREATE LOGIN admin_
    WITH PASSWORD = '123456789'
CREATE LOGIN seller
    WITH PASSWORD = '123456789' 
CREATE USER [Admin] FOR LOGIN admin_
CREATE USER seller FOR LOGIN seller
CREATE SERVER ROLE customers AUTHORIZATION securityadmin

----------------------------------------------------------
--Создать схему(например: выборка всех книг, 
--добавление новых книг, редактирование информации о книге ) 
--для назначения ее зарегистрированным продавцам.

CREATE SCHEMA SellerActions AUTHORIZATION MainAdmin  
    CREATE Table BooksForAdding (
		[Id] INT PRIMARY KEY IDENTITY,
		[Title] NVARCHAR(50) NOT NULL,
		[Price] MONEY NOT NULL,
		[Quantity] INT NOT NULL DEFAULT(1),
	) 
    GRANT SELECT ON SCHEMA::SellerActions TO Sellers
	GRANT INSERT ON SCHEMA::SellerActions TO Sellers
	GRANT DELETE ON SCHEMA::SellerActions TO Sellers
	DENY DELETE ON SCHEMA::SellerActions TO MainAdmin
GO  