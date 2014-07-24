#perl -I/software/solexa/lib/perl5 ./report_qc_to_sequencescape_mq --usedb --id_run 3999 -l 1 -l 2
#  -mqserver mq-dev -mqqueue /queue/staging.qc_evaluations
# NOTE: Rails.logger.level may be overridden (Logger::DEBUG ?) in poller launch script
class QcEvaluationsProcessor < ApplicationProcessor
  subscribes_to :qc_evaluations, {:ack => 'client'}#, 'activemq.prefetchSize' => 1}

  def on_message(message)
    Rails.logger.info("Received: #{message}")
    begin
      process_evaluations(message)
    rescue ActiveRecord::StatementInvalid
      Rails.logger.warn("#{$!.inspect} -- trying once more...")
      sleep 10 # to allow the DBMS to come back (might just be restarting or whatever)
      begin
        ActiveRecord::Base.verify_active_connections!
        Rails.logger.warn("Reconnected to DBMS.")
        retry # so we won't loose the current req just because of a single stale db connection
      rescue
        Rails.logger.error("#{$!.inspect} -- failed to reconnect DB, sorry.")
        raise ActiveMessaging::AbortMessageException
      end
    rescue ::NoMethodError
      Rails.logger.warn("Failed to parse message, skipping: #{$!.inspect}")
      raise
    rescue
      Rails.logger.error("Unknown error: #{$!.inspect}")
      Rails.logger.debug("Backtrace: #{$!.backtrace}")
      raise ActiveMessaging::AbortMessageException
    end
    Rails.logger.info("Done.")
  end

  def process_evaluations(msg)
    doc = Hash.from_xml msg
    Batch.qc_evaluations_update(doc["evaluations"])
  end

  # Expected xml from Queue ### CURRENT STATUS
  # <?xml version="1.0" encoding="UTF-8"?>
  # <evaluations>
  #   <evaluation>
  #     <check>q20_yield</check>
  #     <location>lane number</location>
  #     <identifier>batch id</identifier>
  #     <optional>
  #       <end/>
  #       <comment>All good</comment>
  #       <data_source>/somewhere.fastq</data_source>
  #       <links>
  #         <link>
  #           <label>display text for hyperlink</label>
  #           <href>http://example.com/some_interesting_image_or_table</href>
  #         </link>
  #       </links>
  #       <pass>true</pass>
  #       <results>Some free form data (no html please)</results>
  #       <criteria>
  #         <criterion>
  #           <key>yield</key>
  #           <value>Greater than 80mb</value>
  #         </criterion>
  #         <criterion>
  #           <key>count</key>
  #           <value>Greater than Q20</value>
  #         </criterion>
  #       </criteria>
  #     </optional>
  #   </evaluation>
  # </evaluations>


  # Expected xml from Queue ### NEW STATUS
  # <?xml version="1.0" encoding="UTF-8"?>
  # <evaluations>
  #   <evaluation>
  #     <check>Auto QC</check>
  #     <location>lane number</location>
  #     <identifier>batch id</identifier>
  #     <result></result>
  #     <checks>
  #       <check>
  #         <comment>All good</comment>
  #         <data_source>/somewhere.fastq</data_source>
  #         <links>
  #           <link>
  #             <label>display text for hyperlink</label>
  #             <href>http://example.com/some_interesting_image_or_table</href>
  #           </link>
  #         </links>
  #         <pass>true</pass>
  #         <results>Some free form data (no html please)</results>
  #         <criteria>
  #           <criterion>
  #             <key>yield</key>
  #             <value>Greater than 80mb</value>
  #           </criterion>
  #           <criterion>
  #             <key>count</key>
  #             <value>Greater than Q20</value>
  #           </criterion>
  #         </criteria>
  #       </check>
  #     </checks>
  #   </evaluation>
  # </evaluations>
end
