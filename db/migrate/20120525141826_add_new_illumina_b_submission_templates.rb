class AddNewIlluminaBSubmissionTemplates < ActiveRecord::Migration

  @product_line_id = ProductLine.find_by_name('Illumina-B').id

  def self.up
    ActiveRecord::Base.transaction do
      illumina_b_templates.each do |old_template|
        make_new_template!(old_template)
      end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      new_illumina_b_templates.each do |new_template|
        new_template.destroy
      end
    end
  end

  def self.illumina_b_templates
    SubmissionTemplate.find(:all,:conditions=>["name LIKE ?",'Illumina-B - Multiplexed Library Creation%'])
  end

  def self.new_illumina_b_templates
    SubmissionTemplate.find(:all,:conditions=>["name LIKE ?",'%Multiplexed WGS%'])
  end

  def self.new_template_name(old_template)
    old_template.name.gsub(/Multiplexed Library Creation/,'Multiplexed WGS')
  end

  def self.make_new_template!(old_template)
    submission_parameters = old_template.submission_parameters.dup

    submission_parameters[:request_type_ids_list] = substitute_request_type(
      submission_parameters[:request_type_ids_list],
      RequestType.find_by_key('illumina_b_multiplexed_library_creation').id,
      RequestType.find_by_key('illumina_b_std').id
      )
      say "Creating #{new_template_name(old_template)}"
    SubmissionTemplate.create!(
      {
        :name                  => "#{new_template_name(old_template)}",
        :submission_parameters => submission_parameters,
        :product_line_id       => @product_line_id,
        :visible               => true
      }.reverse_merge(old_template.attributes).except!('created_at','updated_at')
    )
  end

  def self.substitute_request_type(list,old_id,new_id)
    list.map {|id| id = new_id if id == old_id}
  end

end
