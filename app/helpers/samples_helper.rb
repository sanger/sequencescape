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
    return 'No samples accessioned' if samples.empty? || samples.none?(&:accession_number?)
    return 'All samples accessioned' if samples.all?(&:accession_number?)

    count = samples.count { |sample| !sample.accession_number? }
    "#{pluralize(count, 'sample')} not accessioned"
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
      sample.studies.map { |study| "Study '#{link(study)}' is missing an accession number" }
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

  def link(study)
    link_to(ERB::Util.html_escape(study.name), study_path(study))
  end
end
