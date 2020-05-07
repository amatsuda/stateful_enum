# frozen_string_literal: true

require 'stateful_enum/machine'

module StatefulEnum
  module StateInspection
    extend ActiveSupport::Concern

    module ClassMethods
      def stateful_enum
        @_defined_stateful_enums
      end
    end

    def stateful_enum
      self.class.stateful_enum.map do |column, defined_stateful_enum|
        StateInspector.new(defined_stateful_enum, self)
      end
    end

    def stateful_enum_for(column)
      StateInspector.new(self.class.stateful_enum[column.to_sym], self)
    end
  end

  class StateInspector
    def initialize(defined_stateful_enum, model_instance)
      @defined_stateful_enum = defined_stateful_enum
      @model_instance        = model_instance
      @column                = defined_stateful_enum.instance_variable_get(:@column)
    end

    # List of possible events from the current state
    def possible_events
      @defined_stateful_enum.events.select do |e|
        @model_instance.send("can_#{e.value_method_name}?")
      end
    end

    # List of possible event names from the current state
    def possible_event_names
      possible_events.map(&:value_method_name)
    end

    # List of transitionable states from the current state
    def possible_states
      pe = @defined_stateful_enum.events.select {|e| @model_instance.send("can_#{e.value_method_name}?") }
      pe.flat_map {|e| e.transitions[@model_instance.send(@column).to_sym].first }
    end
  end
end
