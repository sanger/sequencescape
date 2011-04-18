module UiHelper
  class Summary
    attr_accessor :summary_items
    attr_accessor :current_page

    def initialize(options = {})
      @summary_items = []
      @current_page  = options[:page].to_i || 1
      @item_per_page = options[:per_page].to_i || 10
    end

    def load(study, workflow)
      study.submissions_for_workflow(workflow).each do |submission|
        submission.items.each do |item|
          self.load_item(item)
        end
      end
      self.load_study_item(study)
      self.get_items
    end

    def size
      self.summary_items.size
    end

    def load_item(asset)
      asset.requests.map { |r| r.events }.flatten.each do |event|
        if event.message && event.message.match(/Run/)
          self.add(SummaryItem.new({:message => "#{event.message}",
                                    :object => event.eventful,
                                    :timestamp => event.created_at,
                                    :external_message => "Run #{event.identifier}",
                                    :external_link => "#{configatron.run_information_url}#{event.identifier}"}))
        end
      end
    end

    def load_study_item(study)
      study.events.each do |event|
        self.add(SummaryItem.new({:message => "#{event.message}",
                                  :object => study,
                                  :timestamp => event.created_at,
                                  :external_message => "Study #{study.id}",
                                  :external_link => ""}))
      end
    end

    def get_items
      self.summary_items.sort{ |a,b| b.timestamp <=> a.timestamp }
    end

    def add(item)
      @summary_items << item
    end

    def size
      @summary_items.size
    end

  end
end
