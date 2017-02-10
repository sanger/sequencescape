# This file is part of SEQUENCESCAPE; it is distributed under the terms of GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and authorship of this file.
# Copyright (C) 2007-2011,2015,2016 Genome Research Ltd.

require 'test_helper'

class DataReleaseTest < ActiveSupport::TestCase
  context 'A study' do
    setup do
      @study = create :study
    end
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
              @study.study_metadata.data_release_strategy        = 'open'
              @study.study_metadata.data_release_timing          = 'standard'

              @study.save!
            end

            should 'return true' do
              assert_equal true, @study.valid_data_release_properties?
            end
          end
          context 'which do allow release (for EGA)' do
            setup do
              @study.study_metadata.data_release_study_type.name           = 'genotyping or cytogenetics'
              @study.study_metadata.data_release_strategy                  = 'managed'
              @study.study_metadata.data_access_group                      = 'dag'
              @study.study_metadata.data_release_timing                    = 'never'
              @study.study_metadata.data_release_prevention_reason         = 'legal'
              @study.study_metadata.data_release_prevention_approval       = 'Yes'
              @study.study_metadata.data_release_prevention_reason_comment = 'It just is'

              @study.save!
            end
            should 'return true' do
              assert Study.find(@study.id).valid_data_release_properties?
            end
          end
        end
      end
    end

    context '#ena_accession_required?' do
      setup do
      end
      context 'with accessioning turned off' do
        setup do
          @study.enforce_accessioning = false
          @study.save!
        end
        should 'return false' do
          assert !@study.ena_accession_required?
        end
      end

      context 'with properties which allow for data release' do
        setup do
          @study.enforce_accessioning                        = true
          @study.study_metadata.data_release_study_type.name = 'genomic sequencing'
          @study.study_metadata.data_release_strategy        = 'open'
          @study.study_metadata.data_release_timing          = 'standard'

          @study.save!
        end

        should 'return true when data release timing is standard' do
          @study.study_metadata.data_release_timing = 'standard'
          assert @study.ena_accession_required?
        end

        should 'return true when data release timing is immediate' do
          @study.study_metadata.data_release_timing = 'immediate'
          assert @study.ena_accession_required?
        end
      end

      context 'with properties which do not allow for ENA data release' do
        setup do
          @study.enforce_accessioning = true
        end

        ['transcriptomics', 'other sequencing-based assay', 'genotyping or cytogenetics'].each do |data_release_sort_of_study_value|
          context "where sort of study is #{data_release_sort_of_study_value}" do
            setup do
              @study.study_metadata.data_release_study_type.name = data_release_sort_of_study_value
            end

            context 'and release timing is never' do
              setup do
                @study.study_metadata.data_release_timing                    = 'never'
                @study.study_metadata.data_release_prevention_reason         = 'legal'
                @study.study_metadata.data_release_prevention_approval       = 'Yes'
                @study.study_metadata.data_release_prevention_reason_comment = 'It just is'
              end

              ['managed', 'open'].each do |strategy|
                context "and strategy is #{strategy}" do
                  setup do
                    @study.study_metadata.data_release_strategy = strategy
                    @study.save!
                  end

                  should 'not required ena accession number' do
                    assert !@study.ena_accession_required?
                  end
                end
              end
            end

            context 'and release timing is delayed' do
              setup do
                @study.study_metadata.data_release_timing       = 'delayed'
                @study.study_metadata.data_release_delay_reason = 'phd study'
              end

              ['managed', 'open'].each do |strategy|
                context "and strategy is #{strategy}" do
                  setup do
                    @study.study_metadata.data_release_strategy       = strategy
                    @study.study_metadata.data_release_delay_period   = '3 months'
                    @study.study_metadata.data_release_delay_approval = 'No'
                    @study.save!
                  end

                  should 'should require ena accession number' do
                    assert @study.ena_accession_required?
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
