# frozen_string_literal: true

# Caution! This file is a little strange, as it extends the already defined
# Study::Metadata class. This is defined by a bit of metaprograming in study.rb
# In the long term we should look at removing a lot of this metaprograming
# In the meantime, we try and force a correct load order

# Ensure study is loaded before the metadata
require_dependency 'study'

# Study itself will also ensure that this file gets loaded, to make sure the metadata class contains these methods

class Study
  class Metadata
    delegate :enforce_data_release, to: :study

    def remove_x_and_autosomes?
      remove_x_and_autosomes == YES
    end

    def managed?
      data_release_strategy == DATA_RELEASE_STRATEGY_MANAGED
    end

    def strategy_not_applicable?
      data_release_strategy == DATA_RELEASE_STRATEGY_NOT_APPLICABLE
    end

    def delayed_release?
      data_release_timing == DATA_RELEASE_TIMING_DELAYED
    end

    def never_release?
      data_release_timing == DATA_RELEASE_TIMING_NEVER
    end

    def delayed_for_other_reasons?
      data_release_delay_reason == DATA_RELEASE_DELAY_FOR_OTHER
    end

    def delayed_for_long_time?
      DATA_RELEASE_DELAY_PERIODS.include?(data_release_delay_period)
    end

    validates :number_of_gigabases_per_sample, numericality: { greater_than_or_equal_to: 0.15, allow_blank: true }

    has_one :data_release_non_standard_agreement, class_name: 'Document', as: :documentable
    accepts_nested_attributes_for :data_release_non_standard_agreement
    validates :data_release_non_standard_agreement, presence: true, if: :non_standard_agreement?
    validates_associated :data_release_non_standard_agreement, if: :non_standard_agreement?

    # Please adjust comment above if this behaviour ever changes
    validates :data_access_group, presence: { if: :managed? }

    validate :valid_policy_url?

    validate :sanity_check_y_separation, if: :separate_y_chromosome_data?

    validates :data_release_timing, inclusion: { in: DATA_RELEASE_TIMINGS }, unless: :strategy_not_applicable?
    validates :data_release_timing, inclusion: { in: [DATA_RELEASE_TIMING_NEVER] }, if: :strategy_not_applicable?

    def sanity_check_y_separation
      if remove_x_and_autosomes?
        errors.add(:separate_y_chromosome_data, 'cannot be selected with remove x and autosomes.')
      end
      !remove_x_and_autosomes?
    end

    before_validation do |record|
      if !record.non_standard_agreement? && !record.data_release_non_standard_agreement.nil?
        record.data_release_non_standard_agreement.delete
        record.data_release_non_standard_agreement = nil
      end
    end

    def non_standard_agreement?
      data_release_standard_agreement == NO
    end

    def study_type_valid?
      errors.add(:study_type, 'is not specified') if study_type.name == 'Not specified'
    end

    # rubocop:todo Metrics/MethodLength
    def valid_policy_url? # rubocop:todo Metrics/AbcSize
      # Rails 2.3 has no inbuilt URL validation, but rather than rolling our own, we'll
      # use the inbuilt ruby URI parser, a bit like here:
      # http://www.simonecarletti.com/blog/2009/04/validating-the-format-of-an-url-with-rails/
      return true if dac_policy.blank?

      dac_policy.insert(0, 'http://') unless dac_policy.include?('://') # Add an http protocol if no protocol is defined
      begin
        uri = URI.parse(dac_policy)
        if configatron.invalid_policy_url_domains.include?(uri.host)
          errors.add(
            :dac_policy,
            ": #{dac_policy} is not an acceptable URL. Please ensure you haven't provided an internal URL."
          )
        end
      rescue URI::InvalidURIError
        errors.add(:dac_policy, ": #{dac_policy} is not a valid URL")
      end
    end

    # rubocop:enable Metrics/MethodLength

    with_options(on: :accession, if: :enforce_data_release) do
      validates :data_release_strategy, presence: true
      validates :data_release_timing, presence: true
      validates :study_description, presence: true
      validates :study_abstract, presence: true
      validates :study_study_title, presence: true
      validate :study_type_valid?
    end

    def snp_parent_study
      return nil if snp_parent_study_id.nil?

      self.class.where(snp_study_id: snp_parent_study_id).includes(:study).try(:study)
    end

    def snp_child_studies
      return nil if snp_study_id.nil?

      self.class.where(snp_parent_study_id: snp_study_id).includes(:study).map(&:study)
    end
  end
end
