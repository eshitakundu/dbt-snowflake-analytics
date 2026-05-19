{% snapshot students_snapshot %}

{{
    config(
        target_schema='snapshots',
        unique_key='student_id',
        strategy='check',
        check_cols=['subscription_type']
    )
}}

SELECT * FROM {{ ref('stg_elearning__students') }}

{% endsnapshot %}