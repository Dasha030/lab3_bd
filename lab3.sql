-- ЧАСТИНА 1: SELECT запити --

SELECT book_id, title, year_published, genre
FROM Book
ORDER BY title;

SELECT title, year_published, pages
FROM Book
WHERE genre = 'Fantasy'
ORDER BY year_published;

SELECT title, year_published
FROM Book
WHERE year_published BETWEEN 1950 AND 2000
ORDER BY year_published DESC;

SELECT title, genre, year_published
FROM Book
WHERE title LIKE '%Harry%'
   OR title LIKE '%Pride%';

SELECT c.copy_id, b.title, c.condition, c.location
FROM Copy c
JOIN Book b ON c.book_id = b.book_id
WHERE c.is_available = TRUE
ORDER BY b.title;

SELECT full_name, email, member_type, join_date
FROM Member
WHERE is_active = TRUE
ORDER BY join_date DESC;

SELECT b.title, a.full_name AS author, b.year_published, b.genre
FROM Book b
JOIN BookAuthor ba ON b.book_id = ba.book_id
JOIN Author a ON ba.author_id = a.author_id
ORDER BY b.title;

SELECT 
    l.loan_id,
    m.full_name AS member_name,
    b.title AS book_title,
    l.loan_date,
    l.due_date,
    CASE 
        WHEN l.due_date < CURRENT_DATE THEN 'Overdue'
        ELSE 'On Time'
    END AS loan_status
FROM Loan l
JOIN Member m ON l.member_id = m.member_id
JOIN Copy c ON l.copy_id = c.copy_id
JOIN Book b ON c.book_id = b.book_id
WHERE l.return_date IS NULL
ORDER BY l.due_date;

SELECT 
    full_name,
    email,
    member_type,
    join_date,
    CURRENT_DATE - join_date AS days_as_member
FROM Member
WHERE is_active = TRUE
ORDER BY days_as_member DESC;

SELECT title, year_published, genre
FROM Book
WHERE publisher_id = (
    SELECT publisher_id 
    FROM Publisher 
    WHERE name_and_surname = 'Penguin Random House'
);

-- ЧАСТИНА 2: INSERT операції --

BEGIN;

INSERT INTO Publisher (name_and_surname, address, phone, email, website)
VALUES ('Oxford University Press', 'Oxford, UK', '+44-18-6556-7000', 'contact@oup.com', 'www.oup.com');

INSERT INTO Author (full_name, birth_date, nationality, biography)
VALUES ('Ernest Hemingway', '1899-07-21', 'American', 'American novelist, short-story writer, and journalist');

INSERT INTO Book (isbn, title, year_published, genre, pages, language, publisher_id)
VALUES (
    '978-0-684-80122-3',
    'The Old Man and the Sea',
    1952,
    'Fiction',
    127,
    'English',
    (SELECT publisher_id FROM Publisher WHERE name_and_surname = 'Simon & Schuster')
);

INSERT INTO BookAuthor (book_id, author_id)
VALUES (
    (SELECT book_id FROM Book WHERE isbn = '978-0-684-80122-3'),
    (SELECT author_id FROM Author WHERE full_name = 'Ernest Hemingway')
);

INSERT INTO Copy (book_id, condition, is_available, location)
SELECT 
    book_id,
    'New',
    TRUE,
    'Shelf H-01'
FROM Book
WHERE isbn = '978-0-684-80122-3'
UNION ALL
SELECT 
    book_id,
    'Excellent',
    TRUE,
    'Shelf H-01'
FROM Book
WHERE isbn = '978-0-684-80122-3';

INSERT INTO Member (full_name, email, phone, address, member_type, expiry_date)
VALUES (
    'Emily Brown',
    'emily.brown@example.com',
    '+380-67-789-0123',
    'Kyiv, Shevchenko Blvd. 14',
    'Student',
    CURRENT_DATE + INTERVAL '1 year'
);

INSERT INTO Loan (copy_id, member_id, loan_date, due_date, status)
VALUES (
    (SELECT copy_id FROM Copy WHERE book_id = (SELECT book_id FROM Book WHERE isbn = '978-0-684-80122-3') LIMIT 1),
    (SELECT member_id FROM Member WHERE email = 'emily.brown@example.com'),
    CURRENT_DATE,
    CURRENT_DATE + INTERVAL '14 days',
    'Active'
);

COMMIT;

SELECT 'Newly added book:' AS info;
SELECT b.title, a.full_name AS author, p.name_and_surname AS publisher
FROM Book b
LEFT JOIN BookAuthor ba ON b.book_id = ba.book_id
LEFT JOIN Author a ON ba.author_id = a.author_id
LEFT JOIN Publisher p ON b.publisher_id = p.publisher_id
WHERE b.isbn = '978-0-684-80122-3';

-- ЧАСТИНА 3: UPDATE операції --

BEGIN;

UPDATE Member
SET email = 'anna.leus@example.com',
    phone = '+380-99-999-9999'
WHERE full_name = 'Anna Leus';

SELECT full_name, email, phone FROM Member WHERE full_name = 'Anna Leus';

UPDATE Copy
SET is_available = TRUE
WHERE copy_id IN (
    SELECT copy_id 
    FROM Loan 
    WHERE return_date IS NOT NULL AND copy_id = 3
);

UPDATE Loan
SET return_date = CURRENT_DATE,
    status = 'Returned'
WHERE loan_id = 1 AND return_date IS NULL;

SELECT loan_id, return_date, status FROM Loan WHERE loan_id = 1;

UPDATE Loan
SET fine_amount = GREATEST(0, (CURRENT_DATE - due_date) * 2.50),
    status = CASE 
        WHEN CURRENT_DATE > due_date THEN 'Overdue'
        ELSE status
    END
WHERE return_date IS NULL AND due_date < CURRENT_DATE;

SELECT loan_id, due_date, fine_amount, status
FROM Loan
WHERE status = 'Overdue';

UPDATE Member
SET expiry_date = expiry_date + INTERVAL '1 year'
WHERE member_type = 'Premium' 
  AND expiry_date < CURRENT_DATE + INTERVAL '30 days';

SELECT full_name, member_type, expiry_date
FROM Member
WHERE member_type = 'Premium';

COMMIT;

-- ЧАСТИНА 4: DELETE операції --

BEGIN;

SELECT loan_id, member_id, loan_date, return_date
FROM Loan
WHERE return_date IS NOT NULL AND loan_date < CURRENT_DATE - INTERVAL '6 months';

DELETE FROM Loan
WHERE return_date IS NOT NULL 
  AND loan_date < CURRENT_DATE - INTERVAL '6 months';

DELETE FROM Loan
WHERE member_id = (SELECT member_id FROM Member WHERE email = 'carol.davis@example.com');

DELETE FROM Member
WHERE email = 'carol.davis@example.com';

SELECT * FROM Member WHERE email = 'carol.davis@example.com';

DELETE FROM Copy
WHERE condition = 'Damaged' 
  AND is_available = TRUE
  AND copy_id NOT IN (SELECT copy_id FROM Loan WHERE return_date IS NULL);

DELETE FROM Author
WHERE author_id NOT IN (SELECT DISTINCT author_id FROM BookAuthor)
  AND full_name = 'Test Author';

DELETE FROM Copy
WHERE book_id IN (
    SELECT b.book_id
    FROM Book b
    LEFT JOIN Copy c ON b.book_id = c.book_id
    LEFT JOIN Loan l ON c.copy_id = l.copy_id
    WHERE l.loan_id IS NULL
)
AND condition = 'Damaged';

COMMIT;

-- ЧАСТИНА 5: Складніші запити для демонстрації --

SELECT 
    title,
    year_published,
    CASE 
        WHEN year_published < 1900 THEN 'Classic'
        WHEN year_published BETWEEN 1900 AND 1950 THEN 'Modern Classic'
        WHEN year_published BETWEEN 1951 AND 2000 THEN 'Contemporary'
        ELSE 'Recent'
    END AS book_era
FROM Book
ORDER BY year_published;

SELECT 
    b.title,
    COUNT(c.copy_id) AS total_copies,
    SUM(CASE WHEN c.is_available = TRUE THEN 1 ELSE 0 END) AS available_copies,
    SUM(CASE WHEN c.is_available = FALSE THEN 1 ELSE 0 END) AS loaned_copies
FROM Book b
LEFT JOIN Copy c ON b.book_id = c.book_id
GROUP BY b.book_id, b.title
ORDER BY total_copies DESC;

SELECT 
    m.full_name,
    b.title,
    l.loan_date,
    l.due_date,
    l.return_date,
    CASE 
        WHEN l.return_date IS NULL THEN 'Currently Borrowed'
        WHEN l.return_date > l.due_date THEN 'Returned Late'
        ELSE 'Returned On Time'
    END AS return_status,
    l.fine_amount
FROM Member m
JOIN Loan l ON m.member_id = l.member_id
JOIN Copy c ON l.copy_id = c.copy_id
JOIN Book b ON c.book_id = b.book_id
WHERE m.full_name = 'Diana Oleynikova'
ORDER BY l.loan_date DESC;


SELECT 
    'Total Books' AS metric, COUNT(*)::TEXT AS value FROM Book
UNION ALL
SELECT 'Total Copies', COUNT(*)::TEXT FROM Copy
UNION ALL
SELECT 'Available Copies', COUNT(*)::TEXT FROM Copy WHERE is_available = TRUE
UNION ALL
SELECT 'Active Members', COUNT(*)::TEXT FROM Member WHERE is_active = TRUE
UNION ALL
SELECT 'Active Loans', COUNT(*)::TEXT FROM Loan WHERE return_date IS NULL;
