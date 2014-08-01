class UpdateV4Fields < ActiveRecord::Migration
  def self.up
    switch_to(:new,false)
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
          new_descriptors = changes(task.name)[option].map do |name,kind,sort|
            {
              :name => name,
              :selection => {"1"=>""},
              :task_id => task.id,
              :kind => kind,
              :required => required,
              :sorter => sort
            }
          end

          Descriptor.create!(new_descriptors)
        end
      end

    end
  end

  def self.changes(step)
    {
      "Specify Dilution Volume"=>{
        :new=>[
          ["Concentration", "Text", 1]
        ],
        :old=>[
          ["Concentration", "Text", 1]
        ]
      },
      "Cluster generation"=>{
        :new=>[
          ["Chip Barcode", "Text", 1],
          ["Operator", "Text", 2],
          ["Cluster Station", "Text", 3],
          ["HiSeq PE Cluster Kit V4 – cBot Box 1 of 2", "Text", 4],
          ["Pipette Carousel", "Text", 5],
          ["Comment", "Text", 6],
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
          ["Universal Scan Mix", "Text", 3],
          ["Incorporation Reagent Master Mix", "Text", 4],
          ["Cleavage Reagent Mix", "Text", 5],
          ["High Salt Buffer", "Text", 6],
          ["Incorporation Wash Buffer", "Text", 7],
          ["Cleavage Buffer", "Text", 8],
          ["Comments", "Text", 9]
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
          ["Pipette Carousel", "Text", 3],
          ["HiSeq PE Cluster Kit V4 – cBot Box 2 of 2", "Text", 4],
          ["Comments", "Text", 5]
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
    ["HiSeq v4 PE (spiked in controls)","HiSeq v4 PE (no controls)"].each do |name|
      yield LabInterface::Workflow.find_by_name!(name)
    end
  end
end
