class MoveStartBatchEventLater < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      each_workflow do |name,before|
        say "Prcessing #{name}"
        workflow = LabInterface::Workflow.find_by_name!(name)
        re_sort = workflow.tasks.detect{|task| task.name==before}.sorted
        workflow.tasks.each do |task|
          orig_sort = task.sorted
          task.update_attributes!(:sorted=>orig_sort+1) if orig_sort >= re_sort
        end
        task = StartBatchTask.create!(:name=>'Start batch', :sorted=>re_sort,:batched=>true,:interactive=>false)
        workflow.tasks << task
      end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      StartBatchTask.find_all_by_name('Start batch').each(&:destroy)
    end
  end

  def self.each_workflow
    [
      # Start batch at start of process
      ['Library preparation','Initial QC'],
      ['MX Library Preparation','Initial QC'],
      ['Manual Quality Control','Manual Quality Control'],
      ['Quality Control','Auto QC'],
      ['Illumina-B MX Library Preparation','Tag Groups'],
      ['DNA QC','QC result'],
      ['Genotyping','Attach Infinium Barcode'],
      ['Cherrypick','Select Plate Template'],
      ['Pulldown library preparation','Shearing'],
      ['Cherrypicking for Pulldown','Cherrypick Group By Submission'],
      ['Pulldown Multiplex Library Preparation','Tag Groups'],
      ['PacBio Sample Prep','DNA Template Prep Kit Box Barcode'],
      ['Illumina-C MX Library Preparation','Tag Groups'],
      ['PacBio Sequencing','Binding Kit Box Barcode'],

      ['Cluster formation','Cluster generation'],
      ['Cluster formation SE','Cluster generation'],
      ['Cluster formation PE','Cluster generation'],
      ['Cluster formation PE HiSeq (no control)','Cluster generation'],
      ['Cluster formation SE HiSeq','Cluster generation'],
      ['Cluster formation SE HiSeq (no controls)','Cluster generation'],
      ['Cluster formation SE (no controls)','Cluster generation'],
      ['Cluster formation SE (spiked in controls)','Cluster generation'],
      ['Cluster formation PE (spiked in controls)','Cluster generation'],
      ['Cluster formation PE HiSeq (no control) (spiked in control)','Cluster generation'],
      ['Cluster formation SE HiSeq (spiked in controls)','Cluster generation'],
      ['MiSeq sequencing','Cluster Generation'],
      ['HiSeq 2500 PE (spiked in controls)','Add flowcell chip barcode'],
      ['HiSeq 2500 SE (spiked in controls)','Add flowcell chip barcode']
    ].each {|wf_before| yield(*wf_before)}
  end
end
