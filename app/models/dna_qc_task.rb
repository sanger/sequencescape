# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2014,2015 Genome Research Ltd.

class DnaQcTask < Task
  class QcData < Task::RenderElement
    attr_reader :gel_value, :pico_value, :sequenom_value, :initial_concentration, :gender_value, :gender_markers_value, :genotyping_done, :sample_empty, :volume
    alias_attribute :well, :asset

    def initialize(request)
      super(request)

      primary_sample = well.primary_aliquot.try(:sample)
      if primary_sample.present?
        @genotyping_done = primary_sample.get_external_value('genotyping_done')
        @genotyping_done = primary_sample.genotyping_done
        @sample_empty    = primary_sample.empty_supplier_sample_name
      end

      @pico_value            = well.get_pico_pass
      @gel_value             = well.get_gel_pass
      @sequenom_count        = well.get_sequenom_count
      @initial_concentration = well.get_concentration
      @gender_value          = primary_sample.try(:sample_metadata).try(:gender)
      @gender_markers_value  = well.get_gender_markers
      @sequenom_value        = "#{@sequenom_count}/30 #{@gender_markers_value}"
      @volume                = well.well_attribute.measured_volume
    end

    def qc_status
      status = [gel_status, pico_status, sequenom_status, concentration_status, gender_status, sample_name_empty]

      return 'fail' if genotyping_done_status == 'fail'
      case
      when status.map { |s| s == 'pass' or s == '*' }.all? then 'pass'
      when status.map { |s| s == 'fail' or s == '*' or s.nil? }.all? then 'fail'
      when status.map { |s| s == 'fail' }.select { |b| b == true }.size >= 3 then 'fail'
      else ''
      end
    end

    def sample_name_empty
      case
      when sample_empty then 'fail'
      else 'pass'
      end
    end

    def pico_status
      case
      when pico_value == 'Pass' || pico_value == 'passed' then 'pass'
      when pico_value == 'ungraded' || pico_value == 'repeat' then '*'
      when pico_value == 'failed' then 'fail'
      when ['Too Low To Normalise'].include?(pico_value) then 'fail'
      else ''
      end
    end

    def gel_status
      case
      when ['Fail', 'Weak', 'Band Not Visible', 'Degraded'].include?(gel_value) then 'fail'
      when gel_value == 'OK' then '*'
      when gel_value.blank? then 'fail'
      else ''
      end
    end

    def sequenom_status
      return '*' unless @sequenom_count
      count = @sequenom_count.to_i
      case
      when count < 19 then 'fail'
      when count > 19 then 'pass'
      end
    end

    def concentration_status
      case
      when initial_concentration.nil? then 'fail'
      when initial_concentration.to_i < 35 then 'fail'
      when initial_concentration.to_i > 50 then 'pass'
      end
    end

    def gender_status
      return '*' if @gender_value == 'Unknown' || @gender_value.nil?
      if @gender_value =~ /^f/i
        @gender_value = 'F'
      elsif @gender_value =~ /^m/i
        @gender_value = 'M'
      end

      case
      when @gender_markers_value.blank? then '*'
      when @gender_markers_value.last != @gender_value then 'fail'
      when @gender_value.map { |g| g == @gender_value }.all? then 'pass'
      end
    end

    def genotyping_done_status
      @genotyping_done && @genotyping_done != '0' ? 'fail' : 'pass'
    end
  end # class QcData

  def create_render_element(request)
    request.asset && QcData.new(request)
  end

  def partial
    'dna_qc_batches'
  end

  def render_task(workflow, params)
    super
    workflow.render_dna_qc_task(self, params)
  end

  def do_task(workflow, params)
    workflow.do_dna_qc_task(self, params)
  end

  def pass_request(request, batch, state)
    return if state.blank?

    case state
    when 'pass'
      if request.pass
        logger.debug "SENDING PASS FOR REQUEST #{request.id}, BATCH #{batch.id}"
        EventSender.send_pass_event(request.id, '', 'Passed DNQ QC', batch.id)

        # activate the next requets
        request.next_requests(batch.pipeline).each do |next_request|
          if next_request.blocked? and next_request.unblock
            next_request.save
          end
        end
      end
    when 'fail'
      if request.fail
        logger.debug "SENDING FAIL FOR REQUEST #{request.id}, BATCH #{batch.id}"
        EventSender.send_fail_event(request.id, '', 'failed DNQ QC', batch.id)

        # cancel next request
        request.next_requests(batch.pipeline).each do |next_request|
          next_request.cancel_before_started!
        end
      end
    end

    event = LabEvent.new
    event.description = name
    event.eventful = request
    event.add_new_descriptor('Passed', request.state == 'passed')

    request.save!
    event.save!
  end
end
