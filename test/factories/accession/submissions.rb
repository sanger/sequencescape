FactoryGirl.define do
  factory :accession_submission, class: Accession::Submission do
    user    { create(:user) }
    sample  { build(:accession_sample) }

    initialize_with { new(user, sample) }
    skip_create
  end
end
