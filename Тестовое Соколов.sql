-- Код создания таблиц: 

-- Таблица FACT_COMMERCIAL_STATS содержит транзакции пациентов
CREATE TABLE public.fact_commercial_stats (
	dim_patients_id integer NOT NULL,
	BILL_DATE date, -- дата транзакции
    REVENUE float, -- сумма транзакции
    DIM_EMPLOYEE_ID integer, -- ID врача
    DIM_ORG_STRUCTURE_ID integer, -- ID филиала клиники
    DIM_SERV_ID integer -- ID услуги

);
COMMENT ON TABLE public.fact_commercial_stats IS 'Транзакции пациентов';


-- Таблица DIM_EMPLOYEE содержит информацию о врачах
create  table public.DIM_EMPLOYEE (
    DIM_EMPLOYEE_ID integer, -- ыID врача
    FULL_NAME varchar(100) -- ФИО врача	
);
COMMENT ON TABLE public.dim_employee IS 'Информация о врачах';


-- Таблица DIM_ORG_STRUCTURE содержит информацию о филиалах клиники
create  table public.DIM_ORG_STRUCTURE
(
    DIM_ORG_STRUCTURE_ID integer, -- ID филиала клиники
    FILIAL varchar(100) -- название филиала
);
COMMENT ON TABLE public.dim_org_structure IS 'Информация о филиалах клиники';

-- Таблица DIM_SERV содержит информацию об услугах клиники
create  table public.DIM_SERV
(
    DIM_SERV_ID integer, -- ID услуги
    SERVICE_NAME varchar(100) -- название услуги
);
COMMENT ON TABLE public.dim_serv IS 'Информация об услугах клиники';

-- Код решения задания: 

'''Задание 1. 
Найдите топ-5 филиалов по количеству уникальных пациентов в 2023 году. Выведите название филиала и количество пациентов в порядке убывания.'''
SELECT dos.filial as filial_name,  count(distinct fct.dim_patients_id) as count_unique_clients 
FROM public.fact_commercial_stats fct
LEFT JOIN public.dim_org_structure dos ON fct.dim_org_structure_id  = dos.dim_org_structure_id  
WHERE EXTRACT(YEAR FROM BILL_DATE) = 2023 
GROUP BY fct.dim_org_structure_id, dos.filial 
ORDER BY count_unique_clients DESC
limit 5

'''Задание 2. 
Для каждого врача в филиале  Отделение "Южное" выведите сумму выручки и количество приемов с 1 января 2024 по услуге Акция: Первичный прием. 
Знакомство с врачом. Выведите ФИО врача, выручку, количество приемов '''
SELECT de.full_name , SUM(fcs.REVENUE), COUNT(fcs.dim_patients_id)
FROM public.fact_commercial_stats fcs 
LEFT JOIN public.dim_org_structure dos ON dos.DIM_ORG_STRUCTURE_ID = fcs.dim_org_structure_id 
LEFT JOIN public.dim_employee de  ON de.dim_employee_id = fcs.dim_employee_id 
LEFT JOIN public.dim_serv ds ON ds.dim_serv_id  = fcs.dim_serv_id 
WHERE dos.filial = 'Отделение "Южное"' AND ds.service_name = 'Акция: Первичный прием. Знакомство с врачом'
AND fcs.bill_date >= '2024-01-01'
GROUP BY fcs.dim_employee_id, de.full_name 

'''Задание 3. 
Найдите пациентов, которые ни разу не были на приеме у отоларинголога в филиалах Отделение "Московское" и  Отделение "Северное" 
'''
WITH patients_used_otolaringolog AS (
	SELECT distinct fcs.dim_patients_id AS patient_id
	FROM public.fact_commercial_stats fcs 
	LEFT JOIN public.dim_org_structure dos ON dos.DIM_ORG_STRUCTURE_ID = fcs.dim_org_structure_id 
	LEFT JOIN public.dim_employee de  ON de.dim_employee_id = fcs.dim_employee_id 
	LEFT JOIN public.dim_serv ds ON ds.dim_serv_id  = fcs.dim_serv_id 
	WHERE dos.filial IN ('Отделение "Московское"', 'Отделение "Северное"') 
	AND ds.service_name  ILIKE '%отоларинголог%'
) 
select distinct fcs.dim_patients_id
FROM public.fact_commercial_stats fcs 
LEFT JOIN patients_used_otolaringolog puo ON puo.patient_id = fcs.dim_patients_id  
WHERE puo.patient_id IS NULL

'''Задание 4*. 
a)	Филиал Отделение "Обводный Канал". 
•	Найдите пациентов, которые год не были на приеме у гинеколога (вне зависимости, когда они делали УЗИ);
•	Найдите пациентов, которые не делали УЗИ больше года (вне зависимости, когда они были у гинеколога). Интересуют только УЗИ молочных желез, УЗИ щитовидной железы, УЗИ брюшной полости. 
•	Выведите общий список уникальных id пациентов

b)	*** Для пациентов из пункта a) выведите точку входа в клинику. Точка входа в данном случае – это дата первой транзакции, ФИО врача и название филиала в этой транзакции
'''

-- Пункт a. 
-- Формулировка задачи не полная, поэтому пропишу как бы я её решал при условии, что есть возможность уточнить детали.
-- Так как у нас нет информации о должности врачей, то узнал ФИО гинеколога, а в запросе формирования CTE patients_used_gynecologist_uzi указал условие: ФИО гинеколога или услуга входит в перечень (УЗИ молочных желез,
--УЗИ щитовидной железы, УЗИ брюшной полости)
-- Предположим, что ФИО гинеколога 'Гинеколог Гинекологович Гинеколог'
-- От полученных данных я выявил список тех пациентов, которые в эти данные не входят
-- Данные нет необходимости собирать отдельно, я бы обязательно уточнил необходимость в этом. 

                          -- Общий список уникальных Id --          
-- CTE пациентов, которые были на приёме гинеколога в течение года от текущей даты 
WITH patients_used_gynecologist_uzi AS (
	SELECT distinct fcs.dim_patients_id AS patient_id, fcs.bill_date 
	FROM public.fact_commercial_stats fcs 
	LEFT JOIN public.dim_org_structure dos ON dos.DIM_ORG_STRUCTURE_ID = fcs.dim_org_structure_id 
	LEFT JOIN public.dim_employee de  ON de.dim_employee_id = fcs.dim_employee_id 
	LEFT JOIN public.dim_serv ds ON ds.dim_serv_id  = fcs.dim_serv_id 
	WHERE dos.filial = 'Отделение "Обводный Канал"'
	AND (de.full_name = 'Гинеколог Гинекологович Гинеколог' 
	OR ds.service_name IN ('УЗИ молочных желез', 'УЗИ щитовидной железы', 'УЗИ брюшной полости'))
	AND fcs.bill_date >= CURRENT_DATE - INTERVAL '1 year'
) 
-- Пациенты которые НЕ входят в список тех, кто пользовался услугами гинеколога или делал узи.
-- определяем через LEFT JOIN CTE (JOIN работает быстрее чем вложенный запрос)
SELECT distinct fcs.dim_patients_id 
FROM public.fact_commercial_stats fcs 
LEFT JOIN patients_used_gynecologist_uzi pug ON pug.patient_id = fcs.dim_patients_id 
WHERE pug.patient_id IS NULL 

-- Пункт b
-- СTE пациентов, которые делали УЗИ и были на приёме гинеколога за последний год 
WITH patients_used_gynecologist_uzi AS (
	SELECT distinct fcs.dim_patients_id AS patient_id
	FROM public.fact_commercial_stats fcs 
	LEFT JOIN public.dim_org_structure dos ON dos.DIM_ORG_STRUCTURE_ID = fcs.dim_org_structure_id 
	LEFT JOIN public.dim_employee de  ON de.dim_employee_id = fcs.dim_employee_id 
	LEFT JOIN public.dim_serv ds ON ds.dim_serv_id  = fcs.dim_serv_id 
	WHERE dos.filial = 'Отделение "Обводный Канал"'
	AND (de.full_name = 'Гинеколог Гинекологович Гинеколог' 
	OR ds.service_name IN ('УЗИ молочных желез', 'УЗИ щитовидной железы', 'УЗИ брюшной полости'))
	AND fcs.bill_date >= CURRENT_DATE - INTERVAL '1 year'
),
-- CTE для пациентов, которые не делали УЗИ и не были на приёме гинеколога
patients_not_used_gynecologist_uzi AS (  
	SELECT distinct fcs.dim_patients_id AS patient_id, fcs.bill_date AS bill_date
	FROM public.fact_commercial_stats fcs 
	LEFT JOIN patients_used_gynecologist_uzi pug ON pug.patient_id = fcs.dim_patients_id 
	WHERE pug.patient_id IS NULL 
)
-- Вывод информации по первому вхождению, используя запрос из CTE patients_not_used_gynecologist_uzi
SELECT fcs.dim_patients_id AS patient_id, pnug.min_bill_date, de.full_name, dos.filial
FROM public.fact_commercial_stats fcs  
JOIN (
	SELECT patient_id, MIN(bill_date) AS min_bill_date 
	FROM patients_not_used_gynecologist_uzi 
	GROUP BY patient_id
	) AS  pnug 
ON fcs.dim_patients_id = pnug.patient_id AND fcs.bill_date = pnug.min_bill_date
LEFT JOIN public.dim_org_structure dos ON dos.DIM_ORG_STRUCTURE_ID = fcs.dim_org_structure_id 
LEFT JOIN public.dim_employee de  ON de.dim_employee_id = fcs.dim_employee_id 
