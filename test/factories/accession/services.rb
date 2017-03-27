FactoryGirl.define do
  factory :ena_service, class: Accession::Service do
    study_type 'open'
    initialize_with { new(study_type) }
    skip_create
  end

  factory :ega_service, class: Accession::Service do
    study_type 'managed'
    initialize_with { new(study_type) }
    skip_create
  end
end
