# frozen_string_literal: true

module FetchTable
  def fetch_table(selector)
    find(selector).all('tr').map do |row|
      row.all('th,td').map do |cell|
        if cell.all('option').present?
          cell.all('option').collect(&:text).join(' ')
        else
          cell.text.squish
        end
      end
    end
  end
end
