# frozen_string_literal: true

module StatefulEnum
  class Machine
    def initialize(model, column, states, prefix, suffix, &block)
      @model, @column, @states, @event_names = model, column, states, []
      @prefix = if prefix == true
                  "#{column}_"
                elsif prefix
                  "#{prefix}_"
                end
      @suffix = if suffix == true
                  "_#{column}"
                elsif suffix
                  "_#{suffix}"
                end

      # undef non-verb methods e.g. Model#active!
      states.each do |state|
        @model.send :undef_method, "#{@prefix}#{state}#{@suffix}!"
      end

      instance_eval(&block) if block
    end

    def event(name, &block)
      raise ArgumentError, "event: :#{name} has already been defined." if @event_names.include? name
      Event.new @model, @column, @states, @prefix, @suffix, name, &block
      @event_names << name
    end

    class Event
      def initialize(model, column, states, prefix, suffix, name, &block)
        @states, @name, @transitions, @before, @after = states, name, {}, nil, nil

        instance_eval(&block) if block

        transitions, before, after = @transitions, @before, @after
        new_method_name = "#{prefix}#{name}#{suffix}"

        # defining event methods
        model.class_eval do
          # def assign()
          detect_enum_conflict! column, new_method_name
          define_method new_method_name do
            to, condition = transitions[send(column).to_sym]
            #TODO better error
            if to && (!condition || instance_exec(&condition))
              #TODO transaction?
              instance_eval(&before) if before
              original_method = self.class.base_class.send(:_enum_methods_module).instance_method "#{prefix}#{to}#{suffix}!"
              ret = original_method.bind(self).call
              instance_eval(&after) if after
              ret
            else
              false
            end
          end

          # def assign!()
          detect_enum_conflict! column, "#{new_method_name}!"
          define_method "#{new_method_name}!" do
            send(new_method_name) || raise('Invalid transition')
          end

          # def can_assign?()
          detect_enum_conflict! column, "can_#{new_method_name}?"
          define_method "can_#{new_method_name}?" do
            transitions.key? send(column).to_sym
          end

          # def assign_transition()
          detect_enum_conflict! column, "#{new_method_name}_transition"
          define_method "#{new_method_name}_transition" do
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
        @before = block
      end

      def after(&block)
        @after = block
      end
    end
  end
end
