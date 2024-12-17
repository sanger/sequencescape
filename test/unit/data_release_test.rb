# frozen_string_literal: true

require 'test_helper'

class DataReleaseTest < ActiveSupport::TestCase
  context 'A study' do
    setup { @study = create(:study) }
    context '#valid_data_release_properties?' do
      context 'and data_release enforced' do
        setup do
          @study.enforce_data_release = true
          @study.save!
        end

        context 'with valid data release properties' do
          context 'which allow release' do
            setup do
              @study.study_metadata.data_release_study_type.name = 'genotyping or cytogenetics'
              @study.study_metadata.data_release_strategy = 'open'
              @study.study_metadata.data_release_timing = 'standard'

              @study.save!
            end

            should 'return true' do
              assert_equal true, @study.valid_data_release_properties?
            end
          end

          context 'which do allow release (for EGA)' do
            setup do
              @study.study_metadata.data_release_study_type.name = 'genotyping or cytogenetics'
              @study.study_metadata.data_release_strategy = 'managed'
              @study.study_metadata.data_access_group = 'dag'
              @study.study_metadata.data_release_timing = 'standard'

              @study.save!
            end
            should 'return true' do
              assert Study.find(@study.id).valid_data_release_properties?
            end
          end
        end
      end
    end

    context '#accession_required?' do
      setup {}
      context 'with accessioning turned off' do
        setup do
          @study.enforce_accessioning = false
          @study.save!
        end

        should 'return false' do
          assert_not @study.accession_required?
        end
      end

      context 'with properties which allow for data release' do
        setup do
          @study.enforce_accessioning = true
          @study.study_metadata.data_release_study_type.name = 'genomic sequencing'
          @study.study_metadata.data_release_strategy = 'open'
          @study.study_metadata.data_release_timing = 'standard'

          @study.save!
        end

        should 'return true when data release timing is standard' do
          @study.study_metadata.data_release_timing = 'standard'
          assert @study.accession_required?
        end

        should 'return true when data release timing is immediate' do
          @study.study_metadata.data_release_timing = 'immediate'
          assert @study.accession_required?
        end
      end

      context 'with properties which do not allow for ENA data release' do
        setup { @study.enforce_accessioning = true }

        data_release_study_types = ['transcriptomics', 'other sequencing-based assay', 'genotyping or cytogenetics']
        data_release_strategies = %w[managed open]

        # rubocop:todo Metrics/BlockLength
        data_release_study_types.each do |data_release_sort_of_study_value|
          context "where sort of study is #{data_release_sort_of_study_value}" do
            setup { @study.study_metadata.data_release_study_type.name = data_release_sort_of_study_value }

            context 'and release timing is never' do
              setup do
                @study.study_metadata.data_release_strategy = 'never'
                @study.study_metadata.data_release_timing = 'never'
                @study.study_metadata.data_release_prevention_reason = 'Protecting IP - DAC approval required'
                @study.study_metadata.data_release_prevention_approval = 'Yes'
                @study.study_metadata.data_release_prevention_reason_comment = 'It just is'
              end

              should 'not required ena accession number' do
                assert_not @study.accession_required?
              end
            end

            context 'and release timing is delayed' do
              setup do
                @study.study_metadata.data_release_timing = 'delayed'
                @study.study_metadata.data_release_delay_reason = 'PhD study'
              end

              data_release_strategies.each do |strategy|
                context "and strategy is #{strategy}" do
                  setup do
                    @study.study_metadata.data_release_strategy = strategy
                    @study.study_metadata.data_release_delay_period = '3 months'
                    @study.study_metadata.data_release_delay_approval = 'No'
                    @study.save!
                  end

                  should 'should require ena accession number' do
                    assert @study.accession_required?
                  end
                end
              end
            end
          end
        end
        # rubocop:enable Metrics/BlockLength
      end
    end
  end
end
