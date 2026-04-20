# frozen_string_literal: true

module SamplesHelper
  # Indicate to the user that saving the sample will also accession it
  # This will not happen if the study has not been accessioned
  def save_text(sample)
    if [accessioning_enabled?, sample.should_be_accessioned?, permitted_to_accession?(sample)].all?
      return 'Save and Accession'
    end

    'Save Sample'
  end

  def samples_not_accessioned(samples)
    accession_numbers = fetch_accession_numbers(samples)

    return 'No samples accessioned' if accession_numbers.empty? || accession_numbers.none?(&:present?)

    not_accessioned_count = accession_numbers.count(&:blank?)
    return 'All samples accessioned' if not_accessioned_count.zero?

    "#{pluralize(not_accessioned_count, 'sample')} not accessioned"
  end

  # Generate a warning providing feedback on why the sample cannot be accessioned
  def should_be_accessioned_warning(sample)
    case sample.studies_for_accessioning.size
    when 0
      no_accessionable_studies_warning(sample)
    when 1
      nil # Always accession
    else
      multiple_accessionable_studies_warning(sample)
    end
  end

  private

  def no_accessionable_studies_warning(sample)
    accession_warning(
      'Sample cannot be accessioned:',
      sample.studies.map do |study| # Add list item for each study
        "Study '#{link(study)}' is not accessionable - #{accessioning_checklist_link(study)}"
      end
    )
  end

  def multiple_accessionable_studies_warning(sample)
    # Samples belonging to more than one accessionables study can only be accessioned if all studies are open
    return nil if sample.all_accessionable_studies_open?

    unopen_studies = sample.studies_for_accessioning.reject { |study| study.study_metadata.open? }
    accession_warning(
      'Samples belonging to more than one study can only be accessioned if all accessionable studies are open:',
      unopen_studies.map { |study| "Study '#{link(study)}' is not open" }
    )
  end

  def accession_warning(message, items)
    alert(:warning, class: 'mt-3') do
      concat message
      concat(
        tag.ul do
          items.each { |item| concat tag.li(item.html_safe) } # rubocop:disable Rails/OutputSafety
        end
      )
    end
  end

  def fetch_accession_numbers(samples)
    if samples.loaded?
      samples.map(&:ebi_accession_number)
    else
      samples.left_outer_joins(:sample_metadata).pluck('sample_metadata.sample_ebi_accession_number')
    end
  end

  def link(study)
    link_to(ERB::Util.html_escape(study.name), study_path(study))
  end

  def accessioning_checklist_link(study)
    link_to 'view accessioning checklist', properties_study_path(study, anchor: 'study-accessioning-checklist')
  end
end
