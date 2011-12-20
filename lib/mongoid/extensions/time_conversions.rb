module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module TimeConversions #:nodoc:
      def set(value)
        return nil if value.blank?
        time = nil
        if value_demands_to_use_utc?(value)
          time = convert_to_utc_time_ignoring(value)
        else
          time = convert_to_time(value)
        end
        strip_milliseconds(time).utc
      end

      def get(value)
        return nil if value.blank?
        if value_demands_to_use_utc?(value)
          value = value.utc
        else
          value = value.getlocal unless Mongoid::Config.instance.use_utc?
          if Mongoid::Config.instance.use_activesupport_time_zone?
            time_zone = Mongoid::Config.instance.use_utc? ? 'UTC' : Time.zone
            value = value.in_time_zone(time_zone)
          end
        end
        value
      end

      def self.tag_with_skip_time_zone_conversion(value)
        def value.skip_time_zone_conversion; true; end
        value
      end

      def self.copy_time_without_offset(tz_time)
        ::Time.utc(tz_time.year, tz_time.month, tz_time.day,
          tz_time.hour, tz_time.min,  tz_time.sec)
      end

      protected

      def strip_milliseconds(time)
        ::Time.at(time.to_i)
      end

      def convert_to_time(value)
        time = Mongoid::Config.instance.use_activesupport_time_zone? ? ::Time.zone : ::Time
        case value
          when ::String then time.parse(value)
          when ::DateTime then time.local(value.year, value.month, value.day, value.hour, value.min, value.sec)
          when ::Date then time.local(value.year, value.month, value.day)
          when ::Array then time.local(*value)
          else value
        end
      end

      def convert_to_utc_time_ignoring(value)
        #require 'ruby-debug' ; debugger

        case value
          when ::String
            Mongoid::Extensions::TimeConversions.
              copy_time_without_offset(::Time.parse(value))
          when ::DateTime
            Mongoid::Extensions::TimeConversions.
              copy_time_without_offset(value)
          when ::Date
            ::Time.utc(value.year, value.month, value.day)
          when ::Array
            ::Time.utc(*value)
          else value
        end
      end

      def value_demands_to_use_utc?(value)
         value.respond_to? :skip_time_zone_conversion and
             value.skip_time_zone_conversion
      end
    end
  end
end
