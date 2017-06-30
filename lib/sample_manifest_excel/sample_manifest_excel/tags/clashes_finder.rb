module SampleManifestExcel
  module Tags

    module ClashesFinder

      def find_tags_clash(tag_and_tag2_oligos_combinations)
        combinations_sorted = {}
        tag_and_tag2_oligos_combinations.each_with_index do |combination, index|
          (combinations_sorted[combination] ||= []) << index
        end
        combinations_sorted.select {|key, value| value.length>1}
      end

      def create_tags_clashes_message(duplicated_tags_combinations_with_indexes, first_row=0)
        message = []
        duplicated_tags_combinations_with_indexes.each do |combination, indexes|
          rows = indexes.map {|i| i + first_row + 1}.join(', ')
          message << "Same tags #{combination.join(', ')} are used on rows #{rows}."
        end
        message.join("<br>").html_safe
      end

    end
  end
end