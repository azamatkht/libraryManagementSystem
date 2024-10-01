-- Library Management System Project

-- creating branch table

drop table if exists branch;
create table branch(
	branch_id varchar(10) primary key,	
    manager_id	varchar(10),	
    branch_address	varchar(20),	
    contact_no varchar(10)
);
alter table branch modify column contact_no varchar(20);


drop table if exists employees;
create table employees(
	emp_id varchar(10) primary key,	
	emp_name varchar(25),	
    position varchar(15),	
    salary int,	
    branch_id varchar(25)
);

drop table if exists books;
create table books(
	isbn varchar(20) primary key,
	book_title varchar(75),
	category varchar(10),
	rental_price float,
	status varchar(15),
	author varchar(35),
	publisher varchar(55)
);
alter table books modify category varchar(20);

drop table if exists members;
create table members(
	member_id varchar(10) primary key,
	member_name varchar(25),
	member_address varchar(75),
	reg_date date
);

drop table if exists issued_status;
create table issued_status(
	issued_id varchar(10) primary key,
    issued_member_id varchar(10),	-- FK
    issued_book_name varchar(75),	
    issued_date	date,
    issued_book_isbn varchar(25),	-- FK
    issued_emp_id varchar(10)  -- FK
);

drop table if exists return_status;
create table return_status(
	return_id varchar(10) primary key,
    issued_id varchar(10),
    return_book_name varchar(75),	
    return_date	date,
    return_book_isbn varchar(20)
);




-- Foreign key
alter table issued_status
add constraint fk_members
foreign key (issued_member_id)
references members(member_id);

alter table issued_status
add constraint fk_books
foreign key (issued_book_isbn)
references books(isbn);

alter table issued_status
add constraint fk_employees
foreign key (issued_emp_id)
references employees(emp_id);

alter table employees
add constraint fk_branch
foreign key (branch_id)
references branch(branch_id);

alter table return_status
add constraint fk_issued_status
foreign key (issued_id)
references issued_status(issued_id);










select * from books;
select * from branch;
select * from employees;
select * from issued_status;
select * from members;
select * from return_status;







-- -------------------------- CRUD Operations ------------------------------- --
-- Task 1. Create a New Book Record -- "978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.')"
select * from books;

insert into books
values ('978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.');

insert into books
values ('978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.');



-- Task 2: Update an Existing Member's Address
update members 
set member_address = '125 Main St'
where member_id = 'C101';

update members
set member_address = '125 Main Str'
where member_id = 'C101';

select * from members;




-- Task 3: Delete a Record from the Issued Status Table -- Objective: Delete the record with issued_id = 'IS121' from the issued_status table.
select * from issued_status;

delete from issued_status
where issued_id = 'IS121';

delete from issued_status
where issued_id = 'IS121';



-- Task 4: Retrieve All Books Issued by a Specific Employee -- Objective: Select all books issued by the employee with emp_id = 'E101'.
select *
from issued_status
where issued_emp_id = 'E101';

select *
from issued_status
where issued_emp_id = 'E101';



-- Task 5: List Members Who Have Issued More Than One Book -- Objective: Use GROUP BY to find members who have issued more than one book.
select issued_member_id, count(*) books_issued
from issued_status
group by 1
having count(*) > 1;






-- ---------------------------- CTAS (create table as select) ----------------------------------- --
-- Task 6: Create Summary Tables: Used CTAS to generate new tables based on query results - each book and total book_issued_cnt**
create table issued_count as
select b.isbn, b.book_title, count(ist.issued_id) 
from books b
join issued_status ist
on b.isbn = ist.issued_book_isbn
group by 1,2
order by 3;

-- ------------------------------- Data Analysis & Findings ------------------------------------------- --
-- Task 7. Retrieve All Books in a Specific Category:
select * from books
where category = "Children";

select distinct category
from books;


-- Task 8: Find Total Rental Income by Category:
select * from books;

select b.category, count(*), sum(b.rental_price)
from books b
join issued_status ist
on b.isbn = ist.issued_book_isbn
group by 1
order by 3 desc;



-- List Members Who Registered in the Last 180 Days:
select * from issued_status;
select * from issued_status
where issued_date >= curdate() - interval 180 day;



-- List Employees with Their Branch Manager's Name and their branch details:
select * from employees;
select * from branch;

select emp1.emp_id, emp1.emp_name, emp1.position, emp1.salary, emp1.branch_id, br.*, emp2.emp_name manager
from employees emp1
join branch br
on emp1.branch_id = br.branch_id
join employees emp2
on emp2.emp_id = br.manager_id;




-- Task 11. Create a Table of Books with Rental Price Above a Certain Threshold 7USD:
create table expensive_books
as(
select * from books
where rental_price >= 7
);

select * from expensive_books;



-- Task 12: Retrieve the List of Books Not Yet Returned
select * from return_status;
select * from issued_status;

select ist.issued_book_name, ist.issued_date, rst.return_date, datediff(rst.return_date,ist.issued_date) as rent_duration
from issued_status ist
left join return_status rst
on ist.issued_id = rst.issued_id
where rst.return_date is not null;




-- Task 13: Identify Members with Overdue Books
-- Write a query to identify members who have overdue books (assume a 30-day return period). Display the member's_id, member's name, book title, issue date, and days overdue.
select * from members;
select * from issued_status;
select * from return_status;

select mbs.member_id, mbs.member_name, ist.issued_book_name, ist.issued_date, datediff(now(), ist.issued_date) days_overdue
from issued_status ist
left join return_status rst
on ist.issued_id = rst.issued_id
join members mbs
on ist.issued_member_id = mbs.member_id
where rst.return_date is null and (datediff(now(), ist.issued_date) >= 30);



-- Task 14: Update Book Status on Return
-- Write a query to update the status of books in the books table to "Yes" when they are returned (based on entries in the return_status table).

-- -------------------------- Stored Procedures --------------------------- --
select * from books;
select * from issued_status;
select * from return_status;


delimiter //
create procedure update_return_status(in p_return_id varchar(10), in p_issued_id varchar(10), in p_book_quality varchar(10))
begin
	declare v_isbn varchar(50);	
    declare v_book_name varchar(80);
    -- Inserting into returns based on user input
	insert into return_status(return_id, issued_id, return_date, book_quality)
    values (p_return_id, p_issued_id, curdate(), p_book_quality);
    
    select issued_book_isbn, issued_book_name
    into v_isbn, v_book_name
    from issued_status
    where issued_id = p_issued_id;
    
    update books
    set status = 'yes'
    where isbn = v_isbn;
    
    select concat('Thank you for returning the books: ', v_book_name) as message;
    
end//
delimiter ;

-- CHecking result 
select * from books
where isbn = '978-0-307-58837-1';

select * from issued_status
where issued_book_isbn = '978-0-307-58837-1';

select * from return_status
where issued_id = 'IS135';

-- calling function
call update_return_status('RS138', 'IS135', 'Good');

alter table return_status add column book_quality varchar(10);


-- test 2
select * from issued_status;

select * from books
where isbn = '978-0-330-25864-8';

update books
set status = 'no'
where isbn = '978-0-330-25864-8';

-- IS140
select * from return_status 
where issued_id = 'IS140';

-- Calling function
call update_return_status('RS148', 'IS140', 'Good');









-- Task 15: Branch Performance Report
-- Create a query that generates a performance report for each branch, showing the number of books issued, the number of books returned, and the total revenue generated from book rentals.
select * from branch;
select * from employees;
select * from issued_status;
select * from return_status;
select * from books;

drop table if exists branch_reports;
create table branch_reports
as(
select emp.branch_id, count(emp_id) books_issued, count(rst.return_id) books_returned, sum(bk.rental_price) revenue 
from issued_status ist
join employees emp
on ist.issued_emp_id = emp.emp_id
left join return_status rst
on ist.issued_id = rst.issued_id
left join books bk
on bk.isbn = ist.issued_book_isbn
group by 1
order by 2 desc)
;

select * from branch_reports;








-- Task 16: CTAS: Create a Table of Active Members
-- Use the CREATE TABLE AS (CTAS) statement to create a new table active_members containing members who have issued at least one book in the last 5 months.

drop table if exists active_members;

create table active_members
as
(
	select * 
	from members mbr
	inner join issued_status ist
	on mbr.member_id = ist.issued_member_id
	where datediff(curdate(), ist.issued_date) <= 153
    );
    
    
    
    
    
    
    
    
-- Task 17: Find Employees with the Most Book Issues Processed
-- Write a query to find the top 3 employees who have processed the most book issues. Display the employee name, number of books processed, and their branch.

select issued_emp_id, emp.emp_name employee_name, count(*) books_processed, emp.branch_id
from issued_status ist
join employees emp
on ist.issued_emp_id = emp.emp_id
group by 1
order by 3 desc
limit 3; 

select issued_emp_id, emp.emp_name employee_name, emp.branch_id, rank() over(partition by issued_emp_id order by count(*) desc) books_processed
from issued_status ist
join employees emp
on ist.issued_emp_id = emp.emp_id;


-- Task 18: Identify Members Issuing High-Risk Books
-- Write a query to identify members who have issued books more than twice with the status "damaged" in the books table. Display the member name, book title, and the number of times they've issued damaged books.



/*
Task 19: Stored Procedure Objective: 

Create a stored procedure to manage the status of books in a library system. 

Description: Write a stored procedure that updates the status of a book in the library based on its issuance. 

The procedure should function as follows: The stored procedure should take the book_id as an input parameter. 

The procedure should first check if the book is available (status = 'yes'). 

If the book is available, it should be issued, and the status in the books table should be updated to 'no'. 

If the book is not available (status = 'no'), the procedure should return an error message indicating that the book is currently not available.
*/

select * from books;
select * from issued_status;

drop procedure if exists issue_book;

delimiter //

create procedure issue_book(p_issued_id varchar(10), p_issued_member_id varchar(10), p_issued_book_isbn varchar(25), p_issued_emp_id varchar(10))
begin
	declare v_status varchar(10);

	select status
    into v_status
    from books 
    where isbn = p_issued_book_isbn;
    
    if v_status = 'yes' then
		insert into issued_status(issued_id, issued_member_id, issued_date, issued_book_isbn, issued_emp_id) 
		values (p_issued_id, p_issued_member_id, curdate(), p_issued_book_isbn, p_issued_emp_id);
		
		update books
		set status = 'no'
		where isbn = p_issued_book_isbn;
        
        select concat('Book records added successfully for book isbn :', p_issued_book_isbn) successful;
	
    else 
		 select concat('Sorry to inform you the book you have requested is unavailable book_isbn:', p_issued_book_isbn) error_occured;
	end if;
end//

delimiter ;

-- Testing

-- issuing book that already exists
call issue_book('IS150', 'C107', '978-0-375-41398-8', 'E106');

-- issuing available book
call issue_book('IS150', 'C107', '978-0-06-025492-6', 'E106');


