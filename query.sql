COPY (
  with source as (
    select
      id,
      base_path,
      publishing_app,
      document_type,
      schema_name,
      first_published_at,
      title,
      details
    from content_items
    where schema_name in ('call_for_evidence', 'consultation', 'detailed_guide', 'publication')
    and first_published_at >= '2024-01-01'
  ),
  content_items_all_nations as (
    select
      id,
      base_path,
      publishing_app,
      document_type,
      schema_name,
      first_published_at,
      title,
      details->'body' as body,
      true as applies_to_england,
      true as applies_to_northern_ireland,
      true as applies_to_scotland,
      true as applies_to_wales
    from source
    where not details ? 'national_applicability'
  ),
  content_items_excluded_nations as (
    select
      id,
      base_path,
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
    from source
    where details ? 'national_applicability'
  ),
  combined as (
    select * from content_items_excluded_nations
    union
    select * from content_items_all_nations
  )
  select * from combined limit 500
) to STDOUT WITH CSV HEADER;

