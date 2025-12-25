# frozen_string_literal: true

module StatefulEnum
  class Machine
    attr_reader :events

    def initialize(model, column, states, prefix, suffix, &block)
      @model, @column, @states, @events = model, column, states.map(&:to_sym), []
      @prefix = if prefix
        prefix == true ? "#{column}_" : "#{prefix}_"
      end
      @suffix = if suffix
        suffix == true ? "_#{column}" : "_#{suffix}"
      end

      # undef non-verb methods e.g. Model#active!
      states.each do |state|
        @model.send :undef_method, "#{@prefix}#{state}#{@suffix}!"
      end

      instance_eval(&block) if block
    end

    def event(name, &block)
      raise ArgumentError, "event: :#{name} has already been defined." if @events.map(&:name).include? name
      @events << Event.new(@model, @column, @states, @prefix, @suffix, name, &block)
    end

    class Event
      attr_reader :name, :value_method_name, :transitions

      def initialize(model, column, states, prefix, suffix, name, &block)
        @states, @name, @transitions, @before, @after = states, name, {}, [], []

        instance_eval(&block) if block

        transitions, before, after = @transitions, @before, @after
        @value_method_name = value_method_name = :"#{prefix}#{name}#{suffix}"

        # defining event methods
        model.class_eval do
          # def assign()
          detect_enum_conflict! column, value_method_name

          define_method value_method_name do |*args, **kwargs|
            to, condition = transitions[send(column).to_sym]
            #TODO better error
            if to && (condition.nil? || instance_exec(&condition))
              transaction do
                before.each do |before_callback|
                  instance_exec(*args, **kwargs, &before_callback)
                end

                original_method = self.class.send(:_enum_methods_module).instance_method "#{prefix}#{to}#{suffix}!"
                ret = original_method.bind(self).call

                after.each do |after_callback|
                  instance_exec(*args, **kwargs, &after_callback)
                end

                ret
              end
            else
              false
            end
          end

          # def assign!()
          detect_enum_conflict! column, "#{value_method_name}!"
          define_method "#{value_method_name}!" do |*args, **kwargs|
            send(value_method_name, *args, **kwargs) || raise('Invalid transition')
          end

          # def can_assign?()
          detect_enum_conflict! column, "can_#{value_method_name}?"
          define_method "can_#{value_method_name}?" do
            state = send(column).to_sym
            return false unless transitions.key? state
            _to, condition = transitions[state]
            condition.nil? || instance_exec(&condition)
          end

          # def assign_transition()
          detect_enum_conflict! column, "#{value_method_name}_transition"
          define_method "#{value_method_name}_transition" do
            transitions[send(column).to_sym].try! :first
          end
        end
      end

      def transition(transitions, options = {})
        if options.blank?
          options[:if] = transitions.delete :if
          #TODO should err if if & unless were specified together?
          if (unless_condition = transitions.delete :unless)
            options[:if] = -> { !instance_exec(&unless_condition) }
          end
        end
        transitions.each_pair do |from, to|
          raise "Undefined state #{to}" unless @states.include? to
          Array(from).each do |f|
            raise "Undefined state #{f}" unless @states.include? f
            raise "Duplicate entry: Transition from #{f} to #{@transitions[f].first} has already been defined." if @transitions[f]
            @transitions[f] = [to, options[:if]]
          end
        end
      end

      def all
        @states
      end

      def before(&block)
        @before << block
      end

      def after(&block)
        @after << block
      end
    end
  end
end
