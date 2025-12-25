# frozen_string_literal: true

class Bug < ActiveRecord::Base
  belongs_to :assigned_to, class_name: 'User'

  block = ->(_) {
    event :assign do
      transition :unassigned => :assigned, if: -> { !!assigned_to }
    end
    # for testing the :unless option
    event :assign_with_unless do
      transition :unassigned => :assigned, unless: -> { !assigned_to }
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

    # for testing callback args
    event :reopen do
      before do |reason:|
        self.reopen_reason = reason
      end

      after do |reason:|
        Notifier.notify "Bug##{id} has been reopened: #{reason}"
      end

      transition [:resolved, :closed] => :unassigned
    end
  }

  if Rails::VERSION::MAJOR >= 7
    enum :status, {unassigned: 0, assigned: 1, resolved: 2, closed: 3}, &block
  else
    enum status: {unassigned: 0, assigned: 1, resolved: 2, closed: 3}, &block
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
