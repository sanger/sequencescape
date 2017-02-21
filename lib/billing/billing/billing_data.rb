module Billing
  class BillingData
    include ActiveModel::Model

    attr_accessor :request, :total_aliquots

    def batch_number
      'STD'
    end

    def interface_code
      'BI'
    end

    def voucher_type
      'LM'
    end

    def trans_type
      'GL'
    end

    def client
      'GR'
    end

    def account
      '3730'
    end

    def dim_1
      ''
    end

    def dim_2(project_cost_code)
      project_cost_code
    end

    def dim_3
      #'Illumina-*' or 'Bespoke' removed from request type name
      request.request_type.name.sub(/Illumina-[ABC]|Bespoke/, '') + request.request_metadata.read_length.to_s
    end

    def dim_6
      'ILL'
    end

    def tax_code
      'XX'
    end

    def currency
      'GBP'
    end

    def amount_input_currency
      '0'
    end

    def amount_in_GBP
      '0'
    end

    def value_1(units)
      units.to_s
    end

    def descriptions
      request.request_type.name
    end

    def transaction_date
      request.request_events.where(to_state: 'passed').last.current_from.strftime("%Y%m%d")
    end

    def voucher_date
      request.request_events.where(to_state: 'passed').last.current_from.strftime("%Y%m%d")
    end

    def total_aliquots
      @total_aliquots ||= request.asset.aliquots.count
    end

    def project_cost_code_and_units_hash
      request.asset.aliquots.group_by{|a| a.project}.inject({}) do |result, (project, aliquots)|
        cost_code = project.present? ? project.project_metadata.project_cost_code : 'no_project'
        result[cost_code] = (aliquots.size.to_f/total_aliquots*100).round
        result
      end
    end

    def line(project_cost_code, units)
      ('%-25.25s' % batch_number) +
      ('%-25.25s' % interface_code) +
      ('%-2.2s' % voucher_type) +
      ('%-2.2s' % trans_type) +
      ('%-25.25s' % client) +
      ('%-25.25s' % account) +
      ('%-25.25s' % dim_1) +
      ('%-25.25s' % dim_2(project_cost_code)) +
      ('%-25.25s' % dim_3) +
      ('%-25.25s' % dim_6) +
      ('%-25.25s' % tax_code) +
      ('%-25.25s' % currency) +
      ('%20.20s' % amount_input_currency) +
      ('%20.20s' % amount_in_GBP) +
      ('%-20.20s' % value_1(units)) +
      ('%-255.255s' % descriptions) +
      ('%-8.8s' % transaction_date) +
      ('%-8.8s' % voucher_date) +
      "\n"
    end

    def lines
      [].tap do |text|
        project_cost_code_and_units_hash.each do |project_cost_code, units|
          text << line(project_cost_code, units)
        end
      end.join('')
    end

  end
end