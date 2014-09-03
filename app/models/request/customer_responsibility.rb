module Request::CustomerResponsibility
  def self.included(base)
    base::Metadata.class_eval do
      attribute(:customer_accepts_responsibility, :boolean => true)

      def customer_accepts_responsibility=(value)
        return write_attribute(:customer_accepts_responsibility,value) unless request.try(:failed?)
        self.errors.add(:customer_accepts_responsibility, 'can not be changed once a request is failed.')
        raise ActiveRecord::RecordInvalid, self
      end
    end
  end
end
