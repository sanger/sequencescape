#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2014 Genome Research Ltd.
class UpdateX10Fields < ActiveRecord::Migration
  def self.up
    switch_to(:new)
  end

  def self.down
    switch_to(:old,false)
  end

  def self.switch_to(option,required=true)
    ActiveRecord::Base.transaction do
      each_workflow do |workflow|

        workflow.tasks.each do |task|
          next unless changes(task.name).present?
          task.descriptors.clear
          new_descriptors = changes(task.name)[option].map do |name,kind,sort,spiked_only|
            next if spiked_only && workflow.name != "HiSeq X PE (spiked in controls)"
            {
              :name => name,
              :selection => {"1"=>""},
              :task_id => task.id,
              :kind => kind,
              :required => required,
              :sorter => sort
            }
          end.compact

          Descriptor.create!(new_descriptors)
        end
      end

    end
  end

  def self.changes(step)
    {
      # "Specify Dilution Volume"=>{
      #   :new=>[
      #     ["DNA Volume", "Text", 1],
      #     ["RSB Volume", "Text", 2]
      #   ],
      #   :old=>[
      #     ["Concentration", "Text", 1]
      #   ]
      # },
      # "Add Spiked in control"=>{
      #   :new=>[],
      #   :old=>[]
      # },
      "Cluster generation"=>{
        :new=>[
          ["Chip Barcode", "Text", 1],
          ["Operator", "Text", 2],
          ["CBOT", "Text", 3],
          ["-20 Temp. Read 1 Cluster Kit Lot #", "Text", 4],
          ["-20 Temp. Cluster Kit RGT #", "Text", 5],
          ["Pipette Carousel", "Text", 6],
          ["PhiX lot #","Text", 7, true],
          ["Comment", "Text", 8]
        ],
        :old=>[
          ["Chip Barcode", "Text", 1],
          ["Operator", "Text", 2],
          ["Cluster Station", "Text", 3],
          ["Room Temp. Read 1 Cluster Kit Lot #", "Text", 4],
          ["-20 Temp. Read 1 Cluster Kit Lot #", "Text", 5],
          ["Pipette Carousel", "Text", 6],
          ["Comment", "Text", 7],
          ["Waste Weight", "Text", 8]
        ]
      },
      "Read 1 Lin/block/hyb/load"=>{
        :new=>[
          ["Chip Barcode", "Text", 1],
          ["Operator", "Text", 2],
          ["Pipette Carousel", "Text", 3],
          ["-20 Seq kit lot #", "Text", 4],
          ["-20 Seq kit RGT #", "Text", 5],
          ["+4 Seq kit lot #", "Text", 6],
          ["+4 Seq kit RGT #", "Text", 7],
          ['Patterned incorporation mix (PIM)', 'Text',8],
          ['Patterned SBS buffer 1 (PB1)','Text',9],
          ['Patterned scan mix (PSM)','Text',10],
          ['Patterned SBS buffer 2 (PB2)','Text',11],
          ['Patterned cleavage mix (PCM)','Text',12],
          ['iPCR batch #','Text',13],
          ["Comments", "Text", 14]
        ],
        :old=>[
          ["Chip Barcode", "Text", 1],
          ["Operator", "Text", 2],
          ["Cluster Station", "Text", 3],
          ["Pipette Carousel", "Text", 4],
          ["Scan Mix", "Text", 5],
          ["Long Read FFN Mix", "Text", 6],
          ["RDP 36", "Text", 7],
          ["Incorporation Mix", "Text", 8],
          ["Cleavage Mix", "Text", 9],
          ["High Salt Buffer", "Text", 10],
          ["Incorporation Buffer", "Text", 11],
          ["Cleavage Buffer", "Text", 12],
          ["Comments", "Text", 13]
        ]
      },
      "Read 2 Cluster/Lin/block/hyb/load"=>{
        :new=>[
          ["Operator", "Text", 1],
          ["Sequencing Machine", "Text", 2],
          ["-20 Temp. Read 2 Cluster Kit Lot  #", "Text", 3],
          ["-20 Temp. Read 2 kit RGT #", "Text", 4],
          ['Patterned resynthesis mix (PRM)','Text',5],
          ['Patterned linearization mix (PLM2)','Text',6],
          ['Patterned amplification mix (PAM)','Text',7],
          ['Patterned amp premix (PPM)','Text',8],
          ['Patterned denaturation mix (PDR)','Text',9],
          ['Primer mix (HP11)','Text',10],
          ['Primer mix (HP12)','Text',11],
          ["Comments", "Text", 12]
        ],
        :old=>[
          ["Operator", "Text", 1],
          ["Sequencing Machine", "Text", 2],
          ["Pipette Carousel", "Text", 3],
          ["-20 Temp. Read 2 Cluster Kit Lot  #", "Text", 4],
          ["Scan Mix", "Text", 5],
          ["Long Read FFN Mix", "Text", 6],
          ["RDP 36", "Text", 7],
          ["Incorporation Mix", "Text", 8],
          ["Cleavage Mix", "Text", 9],
          ["High Salt Buffer", "Text", 10],
          ["Incorporation Buffer", "Text", 11],
          ["Cleavage Buffer", "Text", 12],
          ["Comments", "Text", 13]
        ]
      }
    }[step]
  end

  def self.each_workflow
    ["HiSeq X PE (spiked in controls)","HiSeq X PE (no controls)"].each do |name|
      yield LabInterface::Workflow.find_by_name!(name)
    end
  end
end
