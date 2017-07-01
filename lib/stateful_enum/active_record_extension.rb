# frozen_string_literal: true

require 'stateful_enum/machine'

module StatefulEnum
  module ActiveRecordEnumExtension
    #   enum status: {unassigned: 0, assigned: 1, resolved: 2, closed: 3} do
    #     event :assign do
    #       transition :unassigned => :assigned
    #     end
    #   end
    def enum(definitions, &block)
      prefix, suffix = definitions[:_prefix], definitions[:_suffix] if ActiveRecord::VERSION::STRING >= '5'
      enum = super definitions

      if block
        definitions.each_key do |column|
          states = enum[column]
          StatefulEnum::Machine.new self, column, (states.is_a?(Hash) ? states.keys : states), prefix, suffix, &block
        end
      end
    end
  end
end
