/*Создать базу данных "ПРОДАЖА_ТОВАРОВ"
- КЛИЕНТЫ — информация о клиентах, которые покупают товары компании (№_Клиента — primary_key, Компания (юридическое название), №_продавца — foreign key к таблице СЛУЖАЩИЕ, Лимит_кредита)
- СЛУЖАЩИЕ — информация о служащих, работающих в компании и продающих товары клиентам (№_служащего(или №_продавца)— primary_key, Фио, Возраст, №_Офиса — foreign key к таблице ОФИСЫ Должность, Дата_найма, План, Продажи)
- ОФИСЫ — офисы компании, в которых работают служащие (№_Офиса — primary_key, Город, Регион, План_офиса, Продажи_офиса)
- ТОВАРЫ — информация о товарах, продаваемых компанией (№_Производителя — primary_key, №_Товара — primary_key, Описание, Цена, Количество_на_складе)
- ЗАКАЗЫ — информация о заказах, сделанных клиентом, ( №_Заказа— primary_key, Дата_Заказа, (№_КЛИЕНТА — foreign key к таблице КЛИЕНТЫ, №_Служащего — foreign key к таблице СЛУЖАЩИЕ, №_Производитель — foreign key к таблице ТОВАРЫ, №_Товара — foreign key к таблице ПРОДУКТЫ, Количество, Стоимость), необходимое количество атрибутов, входящих в составной ключ определить и обосновать самостоятельно.
Создание БД:*/
use master;
create database sellingDB
on (name= sellingDB_dat,
filename='d:\sellingDB.mdf',
size=10,
maxsize=100,
filegrowth=5)
log on
(name=sellingDB_log,
filename='d:\sellingDB.ldf',
size=40,
maxsize=100,
filegrowth=10)
/*Создание таблиц:
Офис:*/
use sellingDB;
create table Офис
(Номер_офиса int not null primary key,
Город varchar(50),
Регион varchar(50),
План_офиса int,
Продажи_офиса int);
/*Продавцы:*/
use sellingDB;
create table Продавцы
(Номер_продавца int not null primary key,
ФИО varchar(100),
Должность varchar(50),
План int,
Продажи int,
Дата_найма date,
Номер_офиса int foreign key references Офис(Номер_офиса));
/*Товары:*/
use sellingDB;
create table Товары
(Номер_производителя int not null,
Номер_товара int not null,
Описание varchar(50),
Цена int,
Количество int,
primary key (Номер_производителя, Номер_товара));
/*Клиенты:*/
use sellingDB;
create table Клиент
(Номер_клиента int not null primary key ,
Номер_продавца int foreign key references Продавцы(Номер_продавца),
Компания varchar(50),
Лимит_кредита int,);
/*Заказы:*/
use sellingDB;
create table Заказы
(Номер_заказа int,
Номер_продавца int foreign key references Продавцы(Номер_продавца)
on delete cascade
on update cascade,
Номер_товара int,
Номер_производителя int,
Номер_клиента int foreign key references Клиент(Номер_клиента)
on delete cascade
on update cascade,
Количество int,
Стоимость int,
Дата_заказа date,
primary key (Номер_заказа, Номер_товара, Номер_производителя)
);

/*Создать хранимую процедуру, выводящую общую стоимость и общее число заказов клиентов ;*/
use sellingDB;
Go
CREATE PROCEDURE TotCoast
AS
select Номер_клиента, Sum(Стоимость*Количество) as 'Общая стоимость', Count(Distinct Номер_заказа) as 'Количество заказов' from Заказы
group by Номер_клиента 

/*Создать хранимую процедуру, выводящую общую стоимость и общее число заказов клиентов по каждому офису.*/
Go
CREATE PROCEDURE TotCoastOf
AS
select Номер_клиента, Sum(Стоимость*Количество) as 'Общая стоимость', 
Count(Distinct Номер_заказа) as 'Количество заказов', Номер_офиса from Заказы, Продавцы
where Заказы.Номер_продавца=Продавцы.Номер_продавца
group by Номер_клиента, Номер_офиса

/*Создать хранимую процедуру, выводящую общее количество заказов, каждое из которых превышает среднюю стоимость заказа по всей базе данных.*/
Go
CREATE PROCEDURE CountSr
AS
select count(Distinct Номер_заказа) as 'Количество' from Заказы 
where Номер_заказа = any(select Номер_заказа from Заказы
where (Стоимость*Количество)>(Select AVG(Стоимость*Количество) from Заказы)
group by Номер_заказа)

/*Создадим процедуру, которая будет принимать несколько параметров(по Фамилии, Должности, Дата_найма) и при этом использовать логику. Процедура будет заключаться в том, чтобы добавить Служащего, но учитывать то,  его фамилия должна отличаться от других.*/
go
create procedure new_seller
@num int,
@fio varchar(100),
@dol varchar(50),
@date date
as
begin
if not exists (select ФИО from Продавцы where ФИО=@fio)
begin
insert into Продавцы(Номер_продавца, ФИО, Должность, Дата_найма)
values(@num, @fio, @dol, @date)
end
else
begin print 'ошибка фио уже присутствует'
end
end;

/*Изменить предыдущую процедуру, в результате чего план по умолчанию будет 2000.*/
go
alter procedure new_seller
@num int,
@fio varchar(100),
@dol varchar(50),
@date date,
@plan int = 2000
as
begin
if not exists (select ФИО from Продавцы where ФИО=@fio)
begin
insert into Продавцы(Номер_продавца, ФИО, Должность, Дата_найма)
values(@num, @fio, @dol, @date)
end
else
begin print 'ошибка фио уже присутствует'
end
end;

/*Создать следующие таблицы: КЛИЕНТ (№_клиента, ФИО, адрес), СДЕЛКА (№_клиента, №_товара, количество, дата_заказа), ТОВАР(№_товара, наименование_товара), СКЛАД(№_товара, количество). Создать триггер для реализации ограничений на значение, а именно:  количество проданного товара в добавляемой в таблицу СДЕЛКА не должно быть больше, чем его остаток в таблице СКЛАД.
Создание БД:*/

create database saleDB
ON (NAME= saleDB_dat,
FILENAME = 'C:\sale.mdf',
SIZE = 10,
MAXSIZE = 100,
FILEGROWTH = 5)
LOG ON
(NAME= saleDB_log,
FILENAME = 'C:\sale.ldf',
SIZE = 40,
MAXSIZE = 100,
FILEGROWTH = 10);
 
create table Заказчик(
	Номер_заказчика int,
	ФИО varchar(100),
	Адрес varchar(100)
 
	primary key(Номер_заказчика));
 
create table Товар(
	Номер_товара int,
	Наименование_товара varchar(100)
	
	primary key(Номер_товара));
 
create table Склад(
	Номер_товара int foreign key references Товар(Номер_товара),
	Количество int,
	
	primary key (Номер_товара));
 
create table Сделка(
	Номер_заказчика int foreign key references Заказчик(Номер_заказчика)
	on delete cascade
	on update cascade,
	Номер_товара int foreign key references Товар(Номер_товара)
	on delete cascade
	on update cascade,
	Количество int,
	Дата_заказа date,
	primary key (Номер_заказчика, Номер_товара, Дата_заказа));

/*Триггер:*/
go
create trigger trig_6
on Сделка
for insert
as
begin
	if exists(select * from inserted, Склад where inserted.Количество>Склад.Количество and inserted.Номер_товара=Склад.Номер_товара)
	begin
		rollback transaction
		print 'Количество на складе недостаточно'
	end
end
