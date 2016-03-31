# frozen_string_literal: true

class Bug < ActiveRecord::Base
  belongs_to :assigned_to, class_name: 'User'

  enum status: {unassigned: 0, assigned: 1, resolved: 2, closed: 3} do
    event :assign do
      transition :unassigned => :assigned, if: -> { !!assigned_to }
    end
    # for testing the :unless option
    event :assign_with_unless do
      transition :unassigned => :assigned, unless: -> { !assigned_to }
    end

    event :assign_with_if_unless do
      transition :unassigned => :assigned, if: -> { true }, unless: -> { false }
    end

    event :assign_with_mutual_explicit_if_unless do
      transition :unassigned => :assigned, if: -> { true }, unless: -> { true }
    end

    event :resolve do
      before do
        self.resolved_at = Time.zone.now
      end

      transition [:unassigned, :assigned] => :resolved
    end

    event :close do
      after do
        Notifier.notify "Bug##{id} has been closed."
      end

      transition all - [:closed] => :closed
    end
  end

  class Notifier
    cattr_accessor(:messages) { [] }
    class << self
      def notify(msg)
        self.messages << msg
      end
    end
  end
end
