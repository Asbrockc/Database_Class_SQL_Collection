--CHRISTOPHER ASBROCK
--DATABASE PROJECT PART 6


--LOOKS FOR THE CURRENT INFORMATION ON THE GAME 'Five Nights At Freddys' and 'Dark souls'
--SHOW AVALABLE ONES, EXPIRED ONES, AND SOLD ONES
--IF SOLD, SHOW WHO BAUGHT IT AND THE CODE
SELECT game_title AS TITLE,  cust_first_name|| ' ' || cust_last_name as PURCHASER,
    CASE	
    WHEN count(trans_id) = 1
        THEN red_code_id
        ELSE 
            CASE
            WHEN (sysdate - red_code_active_date < 30)
                THEN 'AVALABLE FOR PURCHASE'
                ELSE 'EXPIRED'
            END 
    END GAME_CODE
FROM REDEEMABLE_CODE red
    LEFT OUTER JOIN TRANSACTION trans ON red.red_code_id = trans.trans_code_id
    LEFT OUTER JOIN GAME game ON game.game_id = red.red_code_game_id
    LEFT OUTER JOIN CUSTOMER cust ON cust.cust_id = trans.trans_cust_id
WHERE game.game_title IN ('Five Nights At Freddys', 'Dark Souls')
GROUP BY game_title, red_code_id,  cust_first_name, cust_last_name, red_code_active_date
ORDER BY game_title;


--Looks for a list of customers, how many games they baught and what they spent total
SELECT CONCAT(CONCAT(cust_first_name, ' '), cust_last_name) as CUSTOMER , 
COUNT(TRANS_cust_Id) as GAMES_BOUGHT,
'$'|| TO_CHAR(SUM(game_base_cost) 
- SUM(game_base_cost) * SUM( developer_discount)/100
- SUM(game_base_cost) * SUM( dev.developer_fee_deduction)/100, 'FM9999999.90') as TOTAL_SPENT
FROM TRANSACTION trn
    LEFT JOIN CUSTOMER cus ON trn.trans_cust_id = cus.cust_id
    JOIN REDEEMABLE_CODE red ON red.red_code_id = trn.trans_code_id
    JOIN GAME game ON game.game_id = red.red_code_game_id
    JOIN DEVELOPER dev ON dev.developer_id = game.game_developer_id
GROUP BY cust_first_name, cust_last_name
ORDER BY cust_last_name;


--GET AVALABLE GAMES
/*Gets every game currently avalble to purchase, 
shows its base price discount, 
and discounted price*/
SELECT game_title, CONCAT(COUNT(RED_CODE_ID), ' COPY(S) AVALABLE') AS AVALABE,
    '$'|| TO_CHAR(SUM(game_base_cost)/COUNT(red_code_id), 'FM9999999.90') as BASE_PRICE,  
    SUM(developer_discount)/COUNT(red_code_id) || '%' as DISCOUNT,
    '$'|| TO_CHAR(SUM(game_base_cost)/COUNT(red_code_id) - (SUM(game_base_cost)/COUNT(red_code_id) * SUM(developer_discount)/COUNT(red_code_id)/100), 'FM9999999.90') as COST
FROM GAME
    JOIN REDEEMABLE_CODE ON game.game_id = redeemable_code.red_code_game_id
    LEFT join TRANSACTION ON TRANSACTION.trans_code_id = redeemable_code.red_code_id
    JOIN DEVELOPER DEV ON game.game_developer_id = dev.developer_id
WHERE trans_code_id IS NULL AND (sysdate - red_code_active_date) < 30
GROUP BY game_title
ORDER BY AVALABE,game_title;


--AFTER GET AVALABLE GAMES IS RUN, LOOKS SPECIFICALLY FOR 'ARMA 3' 
--AND GET WHAT CODES ARE AVALABLE FOR PURCHASE
SELECT game_title || ' - ' || red_code_id  as GAME, 
red_code_active_date as DATE_ACTIVATED, 
sysdate as CURRENT_DATE, 
ROUND(sysdate - red_code_active_date, 0) as DAYS_ACTIVE,  
    CASE	
    WHEN tran.trans_id IS NULL
        THEN 'AVALABLE'
        ELSE 'SOLD'
    END BOUGHT,
    CASE	
    WHEN sysdate - red_code_active_date < 30 
        THEN 'ACTIVE'
        ELSE 'EXPIRED'
    END EXPIRED,
    CASE	
    WHEN sysdate - red_code_active_date < 30 and tran.trans_id IS NULL
        THEN 'YES'
        ELSE 'NO'
    END AVALABLE
FROM redeemable_code red 
LEFT JOIN TRANSACTION tran ON tran.trans_code_id = red.red_code_id
LEFT JOIN GAME gam ON red.red_code_game_id = gam.game_id
WHERE gam.game_title = 'ARMA 3'
ORDER BY game_title;


--Get games sold, and total sales for the developer
SELECT game_title as DEVELOPER_NAME, 
CONCAT(COUNT(GAME_ID), ' GAMES SOLD') as TOTAL_SOLD, 
'$' || TO_CHAR(
    SUM(GAME_BASE_COST)/COUNT(GAME_ID), 'FM9999999.90') as GAME_BASE_PRICE, 
'$'|| TO_CHAR(
    SUM(GAME_BASE_COST), 'FM9999999.90') as GAME_TOTAL_SALES, 
    SUM(DEVELOPER_DISCOUNT)/COUNT(DEVELOPER_DISCOUNT) || '%' as DEV_DISCOUNT,
    SUM(DEVELOPER_FEE_DEDUCTION)/COUNT(DEVELOPER_FEE_DEDUCTION) || '%' as SERVICE_FEE,
'$'|| TO_CHAR(
    SUM(GAME_BASE_COST) 
        - SUM(GAME_BASE_COST) * (SUM(DEVELOPER_FEE_DEDUCTION)/COUNT(DEVELOPER_FEE_DEDUCTION))/100
        - SUM(GAME_BASE_COST) * (SUM(DEVELOPER_DISCOUNT)/COUNT(DEVELOPER_DISCOUNT))/100, 'FM9999999.90') as TOTAL_PROFIT_FOR_DEVELOPER
FROM DEVELOPER dev
    JOIN GAME game ON game.game_developer_id = dev.developer_id
    JOIN REDEEMABLE_CODE red ON red.red_code_game_id = game.game_id
    JOIN TRANSACTION trans ON trans.trans_code_id = red.red_code_id
GROUP BY game_title;


--FIND THE COMPANIES TOTAL PROFITS BY FEE, ALSO SHOWS THE TOTAL SALES
SELECT DISTINCT 'COMPANY TOTAL ' || developer_fee_deduction ||'% FEE PROFIT) : $' || 
TO_CHAR(
    SUM(game_base_cost)  * (SUM(developer_fee_deduction)/COUNT(developer_fee_deduction) / 100), 'FM9999999.90') AS TOTAL_PROFITS_BY_PERCENT,
    '$' || TO_CHAR(SUM(game_base_cost), 'FM9999999.90') as TOTAL_SALES
FROM TRANSACTION trans 
    INNER JOIN REDEEMABLE_CODE red ON trans.trans_code_id = red.red_code_id
    INNER JOIN GAME game ON game.game_id = red.red_code_game_id
    INNER JOIN DEVELOPER dev ON dev.developer_id = game.game_developer_id
GROUP BY developer_fee_deduction;

--Looks for games baught by 'ida daniels'
SELECT UPPER(cust_first_name || ' ' || cust_last_name) as CUSTOMER, game_title 
FROM CUSTOMER cust
    JOIN TRANSACTION trans ON trans.trans_cust_id = cust.cust_id
    JOIN REDEEMABLE_CODE red ON red.red_code_id = trans.trans_code_id
    JOIN GAME game ON game.game_id = red.red_code_game_id
WHERE cust_first_name = 'Ida' and cust_last_name = 'Daniels';


--TOTALS BY GAME, TOTAL_FEE is company profits, TOTAL_profit is developer profits
SELECT game_title, 
COUNT(*),
CONCAT('$', TO_CHAR((SUM(game_base_cost)/COUNT(*)), 'FM9999999.90')) as BASE_COST,
CONCAT('$', TO_CHAR(SUM(game_base_cost), 'FM9999999.90')) as TOTAL_SALE,
CONCAT('$', TO_CHAR(SUM(game_base_cost * developer_fee_deduction/100), 'FM9999999.90')) as TOTAL_FEE,
CONCAT('$', TO_CHAR(SUM(game_base_cost * developer_discount/100), 'FM9999999.90')) as TOTAL_DISCOUNT,
CONCAT('$', TO_CHAR(SUM(game_base_cost - game_base_cost * developer_discount/100 - game_base_cost * developer_fee_deduction/100), 'FM9999999.90')) as TOTAL_PROFIT
FROM TRANSACTION tran
    JOIN REDEEMABLE_CODE code ON code.red_code_id = tran.trans_code_id
    JOIN GAME game ON game.game_id = code.red_code_game_id
    JOIN DEVELOPER develop ON develop.developer_id = game.game_developer_id
GROUP BY game_title
ORDER BY COUNT(*);


--LIST OF EVERY GAME AND THEIR GENRES (MAIN GENRE MARKED)
SELECT game_title, genre_name || ' - (MAIN GENRE)' as GENRE
FROM GAME game
    JOIN GENRE gen ON gen.genre_id = game.game_main_genre
UNION
SELECT game_title, genre_name as GENRE
FROM GAME game
    JOIN GENRE_GAME_PAIR pair ON pair.ggp_game_id = game.game_id
    JOIN GENRE gen ON gen.genre_id = pair.ggp_genre_id
ORDER BY game_title;


--LIST OF EVERY GAME THAT HAS MORE THEN 3 GENRES ASSOCIATED WITH IT
SELECT game_title, COUNT(genre_name) as GENRE
FROM GAME game
    JOIN GENRE gen ON gen.genre_id = game.game_main_genre
GROUP BY game_title HAVING COUNT(genre_name) > 3
UNION
SELECT game_title, COUNT(genre_name) as GENRE
FROM GAME game
    JOIN GENRE_GAME_PAIR pair ON pair.ggp_game_id = game.game_id
    JOIN GENRE gen ON gen.genre_id = pair.ggp_genre_id
GROUP BY game_title HAVING COUNT(genre_name) > 3
ORDER BY game_title;

--LOOKS FOR DEVELOPERS WHO HAVE NO GAMES LISTED YET
SELECT developer_name, COUNT(trans_id)
FROM DEVELOPER dev 
    LEFT JOIN GAME game ON dev.developer_id = game.game_id
    LEFT JOIN REDEEMABLE_CODE red ON red.red_code_game_id = game.game_id
    LEFT OUTER JOIN TRANSACTION trans ON trans.trans_code_id = red.red_code_id
GROUP BY developer_name HAVING COUNT(trans_id) = 0;


--GET HOW MANY OF EACH GAME ARE EXPIRED OR ACTIVE 
--(ACTIVE means it has not been 30 days yet it does not mean it was not sold yet)
SELECT DISTINCT game_title,  
    (SELECT COUNT(red_code_active_date) 
    FROM redeemable_code red
    WHERE sysdate - red_code_active_date > 30  and red_code_game_id = game_id) as AMOUNT_EXPIRED,  
    (SELECT COUNT(red_code_active_date) 
    FROM redeemable_code red
    WHERE sysdate - red_code_active_date < 30 and red_code_game_id = game_id) as AMOUNT_ACTIVE
FROM GAME game
    LEFT OUTER JOIN REDEEMABLE_CODE red ON red.red_code_game_id = game.game_id
GROUP BY game_title, red_code_active_date, red_code_game_id, game_id
ORDER BY game_title;
    