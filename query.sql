COPY (
  with content_items_with_national_applicability as (
    select
      id,
      publishing_app,
      document_type,
      schema_name,
      first_published_at,
      title,
      details->'body' as body,
      (details->'national_applicability'->'england'->>'applicable')::boolean as applies_to_england,
      (details->'national_applicability'->'northern_ireland'->>'applicable')::boolean as applies_to_northern_ireland,
      (details->'national_applicability'->'scotland'->>'applicable')::boolean as applies_to_scotland,
      (details->'national_applicability'->'wales'->>'applicable')::boolean as applies_to_wales
    from content_items
  )
  select *
  from content_items_with_national_applicability
  where first_published_at >= '2024-01-01'
    and applies_to_england is not null
  order by id asc
  limit 500
) to STDOUT WITH CSV HEADER;
