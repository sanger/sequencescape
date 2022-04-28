# frozen_string_literal: true
namespace :primer_panel_templates do
  desc 'Converts existing templates into those with primer-panels'
  task create: :environment do
    # 384 only
    templates_to_clone = %w[TSsc384]

    # 96 and 384 (See https://github.com/sanger/limber/issues/546)
    # Modifications to limber will be required to support the use of these templates, this work is
    # lower priority than the 384 well version that works without modification.
    # templates_to_clone = %w[TSsc384 TS_pWGSA_UDI96v2 TS_pWGSB_UDI96 TS_pWGSC_UDI96 TS_pWGSD_UDI96]
    primer_panel_suffix = 'nCoV-2019/V3/B'
    varieties = %w[PCR1 PCR2]

    templates_to_clone.each do |existing_template_name|
      existing_template = TagLayoutTemplate.find_by(name: existing_template_name)

      if existing_template.nil?
        warn "Template #{existing_template_name} does not exist"
        next
      end
      varieties.each do |variety|
        existing_template.dup.tap do |new_template|
          new_template.name = "#{existing_template_name}-#{variety}-#{primer_panel_suffix}"
          next if TagLayoutTemplate.find_by(name: new_template.name)

          new_template.save!
        end
      end
    end
  end
end
