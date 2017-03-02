module Billing
  class BillingData
    include ActiveModel::Model

    attr_accessor :request, :total_aliquots

# data fields

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
      # 'Illumina-*' or 'Bespoke' removed from request type name
      (request.request_type.name.gsub(/Illumina-[ABC]|Bespoke|\s+/, '').gsub('sequencing', 'seq') + request.request_metadata.read_length.to_s).upcase
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

    def amount_in_gbp
      '0'
    end

    def value_1(units)
      units.to_s
    end

    def descriptions
      request.request_type.name
    end

    def transaction_date
      request.request_events.where(to_state: 'passed').last.current_from.strftime('%Y%m%d')
    end

    def voucher_date
      request.request_events.where(to_state: 'passed').last.current_from.strftime('%Y%m%d')
    end

# end of data fields

    def total_aliquots
      @total_aliquots ||= request.asset.aliquots.size
    end

    def units_by_project_cost_code
      aliquots_by_project.each_with_object({}) do |(project, aliquots), result|
        cost_code = cost_code(project)
        result[cost_code] = result[cost_code].to_i + units(aliquots)
      end
    end

    def aliquots_by_project
      request.asset.aliquots.group_by { |a| a.project }
    end

    def cost_code(project)
      project.present? ? project.project_metadata.project_cost_code : 'no_project'
    end

    def units(aliquots)
      (aliquots.size.to_f / total_aliquots * 100).round
    end

    def line(project_cost_code, units)
      format('%-25.25s', batch_number) <<
      format('%-25.25s', interface_code) <<
      format('%-2.2s', voucher_type) <<
      format('%-23.23s', '') <<
      format('%-2.2s', trans_type) <<
      format('%-25.25s', client) <<
      format('%-25.25s', account) <<
      format('%-25.25s', dim_1) <<
      format('%-25.25s', dim_2(project_cost_code)) <<
      format('%-25.25s', dim_3) <<
      format('%-50.50s', '') <<
      format('%-25.25s', dim_6) <<
      format('%-25.25s', '') <<
      format('%-25.25s', tax_code) <<
      format('%-25.25s', '') <<
      format('%-25.25s', currency) <<
      format('%-2.2s', '') <<
      format('%20.20s', amount_input_currency) <<
      format('%20.20s', amount_in_gbp) <<
      format('%-11.11s', '') <<
      format('%-20.20s', value_1(units)) <<
      format('%-40.40s', '') <<
      format('%-255.255s', descriptions) <<
      format('%-8.8s', transaction_date) <<
      format('%-8.8s', voucher_date) <<
      "\n"
    end

    def lines
      units_by_project_cost_code.each_with_object(String.new) do |(project_cost_code, units), result|
        result << line(project_cost_code, units)
      end
    end
  end
end
