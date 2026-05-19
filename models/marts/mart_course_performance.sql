WITH courses AS (
    SELECT * FROM {{ ref('dim_courses') }}
),

enrollments AS (
    SELECT
        course_id,
        COUNT(*) AS total_enrollments,
        SUM(CASE WHEN is_completed THEN 1 ELSE 0 END) AS total_completions,
        AVG(days_to_complete) AS avg_days_to_complete,
        AVG(rating) AS avg_student_rating
    FROM {{ ref('fct_enrollments') }}
    GROUP BY course_id
),

payments AS (
    SELECT
        course_id,
        SUM(paid_amount) AS total_revenue,
        COUNT(*) AS total_transactions,
        AVG(discount_pct) AS avg_discount_pct
    FROM {{ ref('fct_payments') }}
    GROUP BY course_id
),

reviews AS (
    SELECT
        course_id,
        COUNT(*) AS total_reviews,
        AVG(rating) AS avg_review_rating,
        SUM(CASE WHEN sentiment = 'positive' THEN 1 ELSE 0 END) AS positive_reviews,
        SUM(CASE WHEN sentiment = 'negative' THEN 1 ELSE 0 END) AS negative_reviews
    FROM {{ ref('fct_reviews') }}
    GROUP BY course_id
)

SELECT
    c.course_id,
    c.title,
    c.category,
    c.level,
    c.price_tier,
    c.course_length,
    c.rating AS platform_rating,
    e.total_enrollments,
    e.total_completions,
    {{ calculate_completion_rate('e.total_completions', 'e.total_enrollments') }} AS completion_rate_pct,
    e.avg_days_to_complete,
    e.avg_student_rating,
    p.total_revenue,
    p.total_transactions,
    p.avg_discount_pct,
    r.total_reviews,
    r.avg_review_rating,
    r.positive_reviews,
    r.negative_reviews,
    ROUND((r.positive_reviews / NULLIF(r.total_reviews, 0)) * 100, 2) AS positive_review_pct
FROM courses c
LEFT JOIN enrollments e ON c.course_id = e.course_id
LEFT JOIN payments p ON c.course_id = p.course_id
LEFT JOIN reviews r ON c.course_id = r.course_id