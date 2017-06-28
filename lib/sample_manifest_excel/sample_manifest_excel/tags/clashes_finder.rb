module SampleManifestExcel
  module Tags

    module ClashesFinder

      def find_tags_clash(tag_oligos, tag2_oligos)
        if tag_oligos.present? && tag2_oligos.present?
          combinations = tag_oligos.zip(tag2_oligos)
          combinations_sorted = {}
          combinations.each_with_index do |combination, index|
            (combinations_sorted[combination] ||= []) << index
          end
          combinations_sorted.select {|key, value| value.length>1}
        end
      end

      def create_tags_clashes_message(duplicated_tags_combinations_with_indexes)
        message = ''
        duplicated_tags_combinations_with_indexes.each do |combination, indexes|
          rows = indexes.map {|i| i + FIRST_ROW + 1}.join(', ')
          message << "Tags #{combination.join(', ')} are used on rows #{rows}. "
        end
        message
      end

    end
  end
end