# The following module is included where we have deprecated behaviours that rely on sample or request.
module Aliquot::DeprecatedBehaviours
  module Request
    def self.included(base)
      base.class_eval do
        #Shouldn't be used . Here for compatibility with the previous code
        #having request having one sample
        has_many :samples, :finder_sql => %q{
          SELECT DISTINCT samples.*
          FROM samples
          JOIN aliquots ON aliquots.sample_id=samples.id
          JOIN requests ON requests.asset_id=aliquots.receptacle_id
          WHERE requests.id=#{id}
        }
        deprecate :samples,  :sample_ids
      end
    end

    def tag_number
      tag.try(:map_id) || ''
    end
    deprecate :tag_number

    # tags and tag have been moved to the appropriate assets.
    # I don't think that they are used anywhere else apart 
    # from the batch xml and can therefore probably be removed.
    # ---
    def tag
      self.target_asset.primary_aliquot.try(:tag)
    end
    deprecate :tag

    def tags
      self.asset.tags
    end
    deprecate :tags
    # ---
    
    def sample_name?
      samples.present?
    end
    deprecate :sample_name?

    def sample_name(default=nil, &block)
      #return the name of the underlying samples
      # used mainly for compatibility with the old codebase
      # # default is used if no smaple
      # # block is used to aggregate the samples
      case
      when samples.size == 0 then default
      when samples.size == 1 then samples.first.name
      when block_given?      then yield(samples)
      else                        samples.map(&:name).join(" | ")
      end
    end
    deprecate :sample_name
  end
end
