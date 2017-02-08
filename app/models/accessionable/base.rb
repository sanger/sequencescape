# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2013,2015 Genome Research Ltd.

class Accessionable::Base
  InvalidData = Class.new(AccessionService::AccessionServiceError)
  attr_reader :accession_number, :name, :date, :date_short
  def initialize(accession_number)
    @accession_number = accession_number

    time_now = Time.now
    @date       = time_now.strftime('%Y-%m-%dT%H:%M:%SZ')
    @date_short = time_now.strftime('%Y-%m-%d')
  end

  def errors
    []
  end

  def xml
    raise NotImplementedError, 'abstract method'
  end

  def center_name
    AccessionService::CenterName
  end

  def schema_type
    # raise NotImplementedError, "abstract method"
    self.class.name.split('::').last.downcase
  end

  def alias
    "#{name.gsub(/[^a-z\d]/i, '_')}-sc-#{accessionable_id}"
  end

  def file_name
    "#{self.alias}-#{date}.#{schema_type}.xml"
  end

  def extract_accession_number(xmldoc)
          element = xmldoc.root.elements["/RECEIPT/#{schema_type.upcase}"]
          accession_number = element && element.attributes['accession']
  end

  def extract_array_express_accession_number(xmldoc)
          element = xmldoc.root.elements["/RECEIPT/#{schema_type.upcase}/EXT_ID[@type='ArrayExpress']"]
          accession_number = element && element.attributes['accession']
  end

  def update_accession_number!(_user, _accession_number)
    raise NotImplementedError, 'abstract method'
  end

  def update_array_express_accession_number!(accession_number)
  end

  def accessionable_id
    raise NotImplementError, 'abstract method'
  end

  def released?
    # Return false by default. Overidden by sample.
    false
  end

  def add_updated_event(user, classname, eventable)
        eventable.events.create(
          created_by: user.login,
          message: "#{classname} #{eventable.id} accession data has been updated by user #{user.login}",
          content: 'accession number regenerated',
          of_interest_to: 'administrators'
        )
  end

  def label_scope
      @label_scope ||= "metadata.#{self.class.name.split("::").last.downcase}.metadata"
  end

  class Tag
    attr_reader :value
    def initialize(label_scope, name, value, downcase = false)
      @name = name
      @value = downcase && value ? value.downcase : value
      @scope = label_scope
    end

    def label
      I18n.t("#{@scope}.#{@name}.label").tr(' ', '_').downcase
    end

    def build(xml)
      xml.TAG   label
      xml.VALUE value
    end
  end
end
