# frozen_string_literal: true

module SampleManifestExcel
  module Tags
    ##
    # ClashesFinder
    module ClashesFinder
      # This method takes an array of tags combinations, i.e.
      # [['AA', 'TT'], ['CC', 'GG'], ['ACG', 'CGT'], ['AA', 'TT'], ['A', 'TCG'], ['CC', 'GG']]
      # and returns a hash, indicating the indexes of tags clahses, in this example
      # {['AA', 'TT'] => [0, 3], ['CC', 'GG'] => [1, 5]}

      def find_tags_clash(tag_and_tag2_oligos_combinations)
        combinations_with_indexes = {}
        tag_and_tag2_oligos_combinations.each_with_index do |combination, index|
          (combinations_with_indexes[combination] ||= []) << index
        end
        combinations_with_indexes.select { |_key, value| value.length > 1 }
      end

      # This method takes a hash of not unique tags combinations with indexes, i.e
      # {['AA', 'TT'] => [0, 3], ['CC', 'GG'] => [1, 5]}
      # and returns a message, in this example:
      # 'Same tags 'AA', 'TT' are used on rows 1, 4. <br> Same tags 'CC', 'GG' are used on rows 2, 6.''
      # It is also possible to pass in the first row number (if tags combinations do not start on row 1)

      def create_tags_clashes_message(duplicated_tags_combinations_with_indexes, first_row = 0)
        message = []
        duplicated_tags_combinations_with_indexes.each do |combination, indexes|
          rows = indexes.map { |i| i + first_row + 1 }.join(', ')
          tags_oligos = combination.join(', ') unless combination.compact.empty?
          message << "Same tags #{tags_oligos} are used on rows #{rows}."
        end
        message.join('<br>').html_safe unless message.empty? #rubocop:disable all
      end
    end
  end
end
