-- =====================================================================
-- WONmate 시연용 데이터 (가상 인물 · 가상 상품)
--   로그인: fc01 ~ fc05 / Wonmate2026!  (비밀번호 모두 동일)
--   FC마다 담당 고객 5명 + 보유 계약
--
-- - DB를 처음 만들 때 자동으로 한 번 실행돼요 (docker-entrypoint-initdb.d)
-- - 이미 있는 DB에서 다시 실행해도 안전해요 (있는 FC · 상품은 건너뜀)
--   → 운영 중인 서버에 FC를 추가할 때도 이 파일을 그대로 실행하면 돼요
-- - 10-mock-contracts.sql 이 만든 테이블·타입을 그대로 사용해요
-- - 상담 일정 · 고객 위키는 화면에서 만들면 돼요
-- - 비밀번호 해시는 BCrypt($2a$, Spring BCryptPasswordEncoder 호환)
-- =====================================================================

BEGIN;

DO $$
DECLARE
    v_password CONSTANT text := '$2a$10$qalda4aA6j4CQ1gH7xuLQe69yfCQYmBUmFEBrYsIUjpI4S6.7ZR8m';  -- Wonmate2026!
    v_fc   record;
    v_c    record;
    v_k    record;
    v_fc_id bigint;
    v_cust  bigint;
    v_fcc   bigint;
    v_prod  bigint;
BEGIN
    -- ---------------------------------------------------------------
    -- 가상 상품 (없을 때만)
    -- ---------------------------------------------------------------
    INSERT INTO insurance_products (product_name, insurance_type, payment_term_months, base_premium,
                                    eligible_age_description, payment_frequency, created_at, updated_at)
    SELECT p.name, p.kind, p.term, p.premium, p.age, 'monthly'::payment_frequency, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
    FROM (VALUES
        ('든든 암보험 (가상)',     '암',   240, 60000.00,  '15~65세'),
        ('실손의료보험 (가상)',    '실손', 12,  20000.00,  '0~70세'),
        ('평생 종신보험 (가상)',   '종신', 240, 150000.00, '15~60세'),
        ('행복 연금보험 (가상)',   '연금', 120, 300000.00, '20~60세'),
        ('튼튼 어린이보험 (가상)', '어린이', 240, 35000.00, '0~15세')
    ) AS p(name, kind, term, premium, age)
    WHERE NOT EXISTS (SELECT 1 FROM insurance_products ip WHERE ip.product_name = p.name);

    -- ---------------------------------------------------------------
    -- FC 계정 → 담당 고객 → 보유 계약
    -- ---------------------------------------------------------------
    FOR v_fc IN
        SELECT * FROM (VALUES
            ('fc01', 'fc01@wonmate.example', '한우리', '강남지점 3팀'),
            ('fc02', 'fc02@wonmate.example', '김다온', '강남지점 3팀'),
            ('fc03', 'fc03@wonmate.example', '이서준', '종로지점 1팀'),
            ('fc04', 'fc04@wonmate.example', '박지아', '판교지점 2팀'),
            ('fc05', 'fc05@wonmate.example', '최도현', '부산지점 1팀')
        ) AS f(login_id, email, name, branch)
    LOOP
        -- 이미 있는 FC는 건너뜀 (고객 · 계약 중복 방지)
        IF EXISTS (SELECT 1 FROM financial_consultants WHERE login_id = v_fc.login_id) THEN
            RAISE NOTICE '% 계정이 이미 있어서 건너뜀', v_fc.login_id;
            CONTINUE;
        END IF;

        INSERT INTO financial_consultants (
            login_id, password, email, full_name, joined_year, branch_name, created_at, updated_at
        ) VALUES (
            v_fc.login_id, v_password, v_fc.email, v_fc.name, 2026, v_fc.branch,
            CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
        ) RETURNING fc_id INTO v_fc_id;

        -- 담당 고객
        FOR v_c IN
            SELECT * FROM (VALUES
                -- fc01
                ('fc01', '박준호', DATE '1984-03-02', 'male',   'IT 회사 팀장',     true,  true,  false, '010-****-5678', '경기 성남시'),
                ('fc01', '김서연', DATE '1992-06-10', 'female', '초등학교 교사',    true,  true,  false, '010-****-1234', '서울 강남구'),
                ('fc01', '이민지', DATE '1998-01-20', 'female', '간호사',           NULL,  NULL,  NULL,  '010-****-9012', '서울 송파구'),
                ('fc01', '최영수', DATE '1968-09-05', 'male',   '자영업(음식점)',   true,  false, true,  '010-****-3456', '서울 관악구'),
                ('fc01', '정하늘', DATE '1995-04-11', 'male',   NULL,               NULL,  NULL,  NULL,  '010-****-7890', '서울 마포구'),
                -- fc02
                ('fc02', '윤지호', DATE '1988-07-14', 'male',   '은행원',           true,  true,  false, '010-****-2101', '서울 서초구'),
                ('fc02', '한예린', DATE '1996-11-03', 'female', '디자이너',         false, false, false, '010-****-2102', '서울 성동구'),
                ('fc02', '오성민', DATE '1975-02-18', 'male',   '중소기업 대표',    true,  true,  false, '010-****-2103', '경기 용인시'),
                ('fc02', '서유나', DATE '2001-05-27', 'female', '대학원생',         NULL,  NULL,  NULL,  '010-****-2104', '서울 동작구'),
                ('fc02', '장민혁', DATE '1990-09-09', 'male',   '소방관',           true,  false, false, '010-****-2105', '경기 수원시'),
                -- fc03
                ('fc03', '강하은', DATE '1985-12-01', 'female', '약사',             true,  true,  false, '010-****-3101', '서울 종로구'),
                ('fc03', '조태윤', DATE '1979-04-22', 'male',   '택시 기사',        true,  true,  false, '010-****-3102', '서울 은평구'),
                ('fc03', '임소율', DATE '1999-08-15', 'female', '사회초년생(회사원)', false, false, false, '010-****-3103', '서울 중구'),
                ('fc03', '신동욱', DATE '1962-03-30', 'male',   '퇴직 공무원',      true,  true,  true,  '010-****-3104', '경기 고양시'),
                ('fc03', '배수아', DATE '1993-06-06', 'female', NULL,               true,  NULL,  NULL,  '010-****-3105', '서울 서대문구'),
                -- fc04
                ('fc04', '홍준서', DATE '1987-10-10', 'male',   '개발자',           true,  true,  false, '010-****-4101', '경기 성남시'),
                ('fc04', '문채원', DATE '1994-01-25', 'female', '마케터',           true,  false, false, '010-****-4102', '경기 성남시'),
                ('fc04', '권도윤', DATE '1971-05-13', 'male',   '건설 현장 소장',   true,  true,  false, '010-****-4103', '경기 광주시'),
                ('fc04', '남궁지유', DATE '2000-02-02', 'female', '프리랜서',       false, false, false, '010-****-4104', '서울 강동구'),
                ('fc04', '유시우', DATE '1983-07-07', 'male',   '치과의사',         true,  true,  false, '010-****-4105', '경기 분당구'),
                -- fc05
                ('fc05', '송지민', DATE '1991-03-17', 'female', '항만 물류 사무직', true,  true,  false, '010-****-5101', '부산 해운대구'),
                ('fc05', '백승현', DATE '1966-11-28', 'male',   '어선 선장',        true,  true,  false, '010-****-5102', '부산 영도구'),
                ('fc05', '노하린', DATE '1997-09-19', 'female', '간호조무사',       false, false, false, '010-****-5103', '부산 부산진구'),
                ('fc05', '하준영', DATE '1982-12-24', 'male',   '자영업(카페)',     true,  true,  false, '010-****-5104', '부산 수영구'),
                ('fc05', '김보람', DATE '1989-04-04', 'female', NULL,               NULL,  NULL,  NULL,  '010-****-5105', '경남 김해시')
            ) AS t(fc, name, birth, gender, job, married, children, disability, phone, area)
            WHERE t.fc = v_fc.login_id
        LOOP
            INSERT INTO customers (full_name, birth_date, gender, occupation, is_married, has_children,
                                   has_disability, phone_number, residential_area, created_at, updated_at)
            VALUES (v_c.name, v_c.birth, v_c.gender::gender_code, v_c.job, v_c.married, v_c.children,
                    v_c.disability, v_c.phone, v_c.area, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
            RETURNING customer_id INTO v_cust;

            INSERT INTO fc_customers (fc_id, customer_id, assignment_status, created_at, updated_at)
            VALUES (v_fc_id, v_cust, 'active', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);
        END LOOP;

        -- 보유 계약
        FOR v_k IN
            SELECT * FROM (VALUES
                -- fc01
                ('fc01', '김서연', '든든 암보험 (가상)',     68000.00,  DATE '2023-03-14', 'active'),
                ('fc01', '김서연', '실손의료보험 (가상)',    23000.00,  DATE '2021-07-02', 'active'),
                ('fc01', '박준호', '평생 종신보험 (가상)',   152000.00, DATE '2019-11-20', 'active'),
                ('fc01', '박준호', '든든 암보험 (가상)',     54000.00,  DATE '2022-05-09', 'active'),
                ('fc01', '최영수', '든든 암보험 (가상)',     98000.00,  DATE '2016-12-01', 'active'),
                ('fc01', '최영수', '행복 연금보험 (가상)',   300000.00, DATE '2012-04-15', 'active'),
                ('fc01', '정하늘', '실손의료보험 (가상)',    19000.00,  DATE '2024-02-28', 'active'),
                -- fc02
                ('fc02', '윤지호', '평생 종신보험 (가상)',   140000.00, DATE '2018-06-01', 'active'),
                ('fc02', '윤지호', '튼튼 어린이보험 (가상)', 38000.00,  DATE '2021-03-10', 'active'),
                ('fc02', '한예린', '실손의료보험 (가상)',    18000.00,  DATE '2022-09-15', 'active'),
                ('fc02', '오성민', '행복 연금보험 (가상)',   300000.00, DATE '2010-01-20', 'active'),
                ('fc02', '오성민', '든든 암보험 (가상)',     87000.00,  DATE '2015-05-05', 'lapsed'),
                ('fc02', '장민혁', '든든 암보험 (가상)',     52000.00,  DATE '2020-11-11', 'active'),
                -- fc03
                ('fc03', '강하은', '든든 암보험 (가상)',     61000.00,  DATE '2019-02-14', 'active'),
                ('fc03', '강하은', '튼튼 어린이보험 (가상)', 33000.00,  DATE '2020-07-01', 'active'),
                ('fc03', '조태윤', '실손의료보험 (가상)',    27000.00,  DATE '2017-04-03', 'active'),
                ('fc03', '조태윤', '평생 종신보험 (가상)',   120000.00, DATE '2014-08-21', 'terminated'),
                ('fc03', '신동욱', '행복 연금보험 (가상)',   300000.00, DATE '2005-10-10', 'matured'),
                ('fc03', '신동욱', '실손의료보험 (가상)',    45000.00,  DATE '2012-03-03', 'active'),
                -- fc04
                ('fc04', '홍준서', '평생 종신보험 (가상)',   160000.00, DATE '2021-01-15', 'active'),
                ('fc04', '홍준서', '실손의료보험 (가상)',    21000.00,  DATE '2021-01-15', 'active'),
                ('fc04', '문채원', '든든 암보험 (가상)',     47000.00,  DATE '2023-06-30', 'active'),
                ('fc04', '권도윤', '든든 암보험 (가상)',     95000.00,  DATE '2013-09-09', 'active'),
                ('fc04', '유시우', '튼튼 어린이보험 (가상)', 36000.00,  DATE '2022-12-12', 'active'),
                ('fc04', '유시우', '행복 연금보험 (가상)',   300000.00, DATE '2016-02-29', 'active'),
                -- fc05
                ('fc05', '송지민', '튼튼 어린이보험 (가상)', 34000.00,  DATE '2023-04-04', 'active'),
                ('fc05', '송지민', '실손의료보험 (가상)',    20000.00,  DATE '2019-08-08', 'active'),
                ('fc05', '백승현', '평생 종신보험 (가상)',   180000.00, DATE '2008-05-15', 'active'),
                ('fc05', '백승현', '든든 암보험 (가상)',     110000.00, DATE '2011-11-01', 'lapsed'),
                ('fc05', '하준영', '실손의료보험 (가상)',    24000.00,  DATE '2020-10-20', 'active'),
                ('fc05', '김보람', '든든 암보험 (가상)',     58000.00,  DATE '2024-01-05', 'active')
            ) AS t(fc, customer, product, premium, start_date, status)
            WHERE t.fc = v_fc.login_id
        LOOP
            SELECT fc.fc_customer_id INTO STRICT v_fcc
            FROM fc_customers fc JOIN customers c ON c.customer_id = fc.customer_id
            WHERE fc.fc_id = v_fc_id AND c.full_name = v_k.customer;

            SELECT product_id INTO STRICT v_prod FROM insurance_products WHERE product_name = v_k.product;

            INSERT INTO contracts (fc_customer_id, product_id, actual_premium, start_date, maturity_date,
                                   status, created_at, updated_at)
            VALUES (v_fcc, v_prod, v_k.premium, v_k.start_date, NULL, v_k.status::contract_status,
                    CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);
        END LOOP;
    END LOOP;
END;
$$;

COMMIT;