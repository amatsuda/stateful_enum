module StatefulEnum::Errors
  class InvalidTransition < RuntimeError
    attr_reader :state
    attr_reader :event

    def initialize(state, event)
      @state, @event = state, event
      super("Invalid transition from state #{@state.inspect} via event #{@event.inspect}")
    end
  end
end
