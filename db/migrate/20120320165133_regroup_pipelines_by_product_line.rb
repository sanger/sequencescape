class RegroupPipelinesByProductLine < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      say 'Regrouping Illumin-A Inboxes'
      ActiveRecord::Base.connection.execute(
        <<-EO_SQL
        UPDATE pipelines
        SET group_name = 'Illumina-A Library creation'
        WHERE NAME LIKE 'Pulldown%';
        EO_SQL
      )

      say 'Regrouping Illumin-B Inboxes'

      ActiveRecord::Base.connection.execute(
        <<-EO_SQL
        UPDATE pipelines 
        SET group_name = 'Illumina-B Library creation'
        WHERE NAME IN('MX Library creation', 'Illumina-B MX Library Preparation' );
        EO_SQL
      )

      say 'Regrouping Illumin-C Inboxes'
      ActiveRecord::Base.connection.execute(
        <<-EO_SQL
        UPDATE pipelines 
        SET group_name = 'Illumina-C Library creation'
        WHERE NAME IN('Library preparation', 'Illumina-C MX Library Preparation');
        EO_SQL
      )
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      say 'Reverting Product Line groupings to Library Creation'

      ActiveRecord::Base.connection.execute(
        <<-EO_SQL
        UPDATE pipelines 
        SET group_name = 'Library creation'
        WHERE group_name IN('Illumina-A Library creation', 'Illumina-B Library creation', 'Illumina-C Library creation');
        EO_SQL
      )
    end
  end
end
