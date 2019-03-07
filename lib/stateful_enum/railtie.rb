# frozen_string_literal: true

require 'stateful_enum/active_record_extension'

if defined?(::Rails::Railtie)
  module StatefulEnum
    class Railtie < ::Rails::Railtie
      ActiveSupport.on_load :active_record do
        ::ActiveRecord::Base.extend StatefulEnum::ActiveRecordEnumExtension
      end
    end
  end
elsif defined?(::ActiveRecord::Base)
  ::ActiveRecord::Base.extend StatefulEnum::ActiveRecordEnumExtension
end
