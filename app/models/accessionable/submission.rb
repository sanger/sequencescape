# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2013,2015,2016 Genome Research Ltd.

class Accessionable::Submission < Accessionable::Base
  attr_reader :broker, :alias, :date, :accessionables, :contact

  def initialize(service, user, *accessionables)
    @service = service
    @contact = Contact.new(user)
    @broker = service.broker
    @accessionables = accessionables

    super(accession_number)
  end

  def alias
    @accessionables.map(&:alias).join(' - ') << DateTime.now.strftime('%Y%m%dT%H%M')
  end

  def <<(_accessionable)
    @accessionables << accesionable
  end

  def xml
    xml = Builder::XmlMarkup.new
    xml.instruct!
    xml.SUBMISSION(
      'xmlns:xsi'      => 'http://www.w3.org/2001/XMLSchema-instance',
      :center_name     => center_name,
      :broker_name     => broker,
      :alias           => self.alias,
      :submission_date => date
    ) {
      xml.CONTACTS { contact.build(xml) }
      xml.ACTIONS {
        # You can only perform additions with protect or hold, or you can do a modification.  So separate the
        # accessionable instances into additions and modifications.
        additions, modifications = accessionables.partition { |accessionable| accessionable.accession_number.blank? }

        additions.each do |accessionable|
          xml.ACTION {
            xml.ADD(source: accessionable.file_name,  schema: accessionable.schema_type)
          }

          xml.ACTION {
            xml.tag!(accessionable.protect?(@service) ? 'PROTECT' : 'HOLD')
          }
        end

        modifications.each do |accessionable|
          xml.ACTION {
            xml.MODIFY(
              source: accessionable.file_name,
              schema: accessionable.schema_type
            )
          }

          state_action(accessionable) do |action|
            xml.ACTION {
              xml.tag!(action)
            }
          end
        end
      }
    }
    xml.target!
  end

  def state_action(accessionable)
    if accessionable.protect?(@service)
      yield 'PROTECT'
    elsif !accessionable.released?
      yield 'HOLD'
    end
  end

  def name
    if @accessionables.size >= 1
      @accessionables.first.name
    else
      'empty'
    end
  end

  def all_accessionables
    @accessionables + [self]
  end

  def update_accession_number!(_user, accession_number)
    @accession_number = accession_number
  end

private

  class Contact
    attr_reader :inform_on_error, :inform_on_status, :name
    def initialize(user)
      @inform_on_error = "#{user.login}@#{configatron.default_email_domain}"
      @inform_on_status = inform_on_error
      @name = user.first_name + ' ' + user.last_name
    end

    def build(markup)
      markup.CONTACT(
        inform_on_error: inform_on_error,
        inform_on_status: inform_on_status,
        name: name
      )
    end
  end
end
