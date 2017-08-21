module Api
  module V1
    module Mobile
      class Base

        def initialize args={}
          args.each do |k, v|
            instance_variable_set("@#{k}", v) unless v.nil?
          end
        end

        #
        # Called by ApplicationHelper.display_carrier_logo via:
        # - PlanResponse::_render_links!
        # - BaseEnrollment::__initialize_enrollment
        #
        def image_tag source, options
          nok = Nokogiri::HTML ActionController::Base.helpers.image_tag source, options
          nok.at_xpath('//img/@src').value
        end

        #
        # Protected
        #
        protected

        def __merge_these (hash, *details)
          details.each {|m| hash.merge! JSON.parse(m)}
        end

        def __summary_of_benefits_url plan
          document = plan.sbc_document
          return unless document
          document_download_path(*get_key_and_bucket(document.identifier).reverse)
            .concat("?content_type=application/pdf&filename=#{plan.name.gsub(/[^0-9a-z]/i, '')}.pdf&disposition=inline")
        end

        def __format_date date
          date.strftime('%m-%d-%Y') if date.respond_to?(:strftime)
        end

        def __ssn_masked person
          "***-**-#{person.ssn[5..9]}" if person.ssn
        end

        def __is_current_or_upcoming? start_on
          TimeKeeper.date_of_record.tap {|now| (now - 1.year..now + 1.year).include? start_on}
        end

      end
    end
  end
end