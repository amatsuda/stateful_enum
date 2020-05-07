# frozen_string_literal: true

require 'test_helper'

class StatefulEnumTest < ActiveSupport::TestCase
  def test_transition
    bug = Bug.new
    assert_equal 'unassigned', bug.status
    bug.assigned_to = User.create!(name: 'user 1')
    bug.assign
    assert_equal 'assigned', bug.status
  end

  def test_transition!
    bug = Bug.new
    bug.assigned_to = User.create!(name: 'user 1')
    bug.assign!
    assert_equal 'assigned', bug.status
  end

  def test_transition_from_all
    bug = Bug.new
    bug.close
    assert_equal 'closed', bug.status

    bug = Bug.new
    bug.assigned_to = User.create!(name: 'user 1')
    bug.assign!
    bug.close
    assert_equal 'closed', bug.status

    bug = Bug.new
    bug.resolve!
    bug.close
    assert_equal 'closed', bug.status
  end

  def test_invalid_transition
    bug = Bug.new
    bug.resolve!
    assert_equal false, bug.assign
    assert_equal 'resolved', bug.status
  end

  def test_invalid_transition!
    bug = Bug.new
    bug.resolve!
    assert_raises do
      bug.assign!
    end
    assert_equal 'resolved', bug.status
  end

  def test_can_xxxx?
    bug = Bug.new
    assert bug.can_resolve?
    bug.resolve!
    refute bug.can_resolve?
  end

  def test_if_condition_can_xxxx?
    bug = Bug.new
    refute bug.can_assign?
    bug.assigned_to = User.new
    assert bug.can_assign?
    bug.resolve!
    refute bug.can_assign?
  end

  def test_unless_condition_can_xxxx?
    bug = Bug.new
    refute bug.can_assign_with_unless?
    bug.assigned_to = User.new
    assert bug.can_assign_with_unless?
    bug.resolve!
    refute bug.can_assign_with_unless?
  end

  def test_xxxx_transition
    bug = Bug.new
    assert_equal :assigned, bug.assign_transition
  end

  def test_non_verb_methods_are_undefined
    bug = Bug.new
    refute bug.respond_to? :assigned!
  end

  def test_before_transition_hook
    bug = Bug.new
    assert_nil bug.resolved_at
    bug.resolve
    refute_nil bug.resolved_at
  end

  def test_after_transition_hook
    bug = Bug.new
    assert_difference 'Bug::Notifier.messages.count' do
      bug.close
    end
  end

  def test_if_condition
    bug = Bug.new
    assert_raises do
      bug.assign!
    end
    bug.assigned_to = User.create!(name: 'user 1')
    assert_nothing_raised do
      bug.assign!
    end
  end

  def test_unless_condition
    bug = Bug.new
    assert_raises do
      bug.assign_with_unless!
    end
    bug.assigned_to = User.create!(name: 'user 1')
    assert_nothing_raised do
      bug.assign_with_unless!
    end
  end

  def test_enum_definition_with_array
    ActiveRecord::Migration.create_table(:array_enum_test) {|t| t.integer :col }
    tes = Class.new(ActiveRecord::Base) do
      self.table_name = 'array_enum_test'
      enum(col: [:foo, :bar]) { event(:e) { transition(foo: :bar) } }
    end.new col: 'foo'
    tes.e
    assert_equal 'bar', tes.col
  end

  def test_duplicate_from_in_one_event
    assert_raises do
      Class.new(ActiveRecord::Base) do
        enum status: {unassigned: 0, assigned: 1, resolved: 2, closed: 3} do
          event :assign do
            transition :unassigned => :assigned
            transition :unassigned => :resolved
          end
        end
      end
    end
  end

  def test_not_duplicate_from_in_one_event
    assert_nothing_raised do
      Class.new(ActiveRecord::Base) do
        enum status: {unassigned: 0, assigned: 1, resolved: 2, closed: 3} do
          event :toggle_assignment do
            transition :unassigned => :assigned
            transition :assigned => :unassigned
          end
        end
      end
    end
  end

  def test_error_raised_when_states_are_duplicated_with_another_enum_states
    assert_raises ArgumentError do
      Class.new(ActiveRecord::Base) do
        enum status: {unassigned: 0, assigned: 1, resolved: 2, closed: 3} do
          event :toggle_assignment do
            transition :unassigned => :assigned
            transition :assigned => :unassigned
          end
        end

        enum another_status: {unassigned: 0, assigned: 1, resolved: 2, closed: 3} do
          event :toggle_assignment do
            transition :unassigned => :assigned
            transition :assigned => :unassigned
          end
        end
      end
    end
  end

  def test_error_raised_when_states_are_duplicated_with_normal_enum_entry
    assert_raises ArgumentError do
      Class.new(ActiveRecord::Base) do
        enum status: {unassigned: 0, assigned: 1, resolved: 2, closed: 3} do
          event :toggle_assignment do
            transition :unassigned => :assigned
            transition :assigned => :unassigned
          end
        end

        enum another_status: {unassigned: 0, assigned: 1, resolved: 2, closed: 3}
      end
    end
  end

  if Rails::VERSION::STRING >= '5'
    def test_enum_definition_with_prefix
      ActiveRecord::Migration.create_table(:enum_prefix_test) do |t|
        t.integer :status
        t.integer :comments_status
      end
      tes = Class.new(ActiveRecord::Base) do
        self.table_name = 'enum_prefix_test'
        enum(status: [:active, :archived], _prefix: true) { event(:archive) { transition(active: :archived) } }
        enum(comments_status: [:active, :inactive], _prefix: :comments) { event(:close) { transition(active: :inactive) } }
      end.new status: :active, comments_status: :active

      assert_equal :archived, tes.status_archive_transition
      assert tes.can_status_archive?
      tes.status_archive
      assert_equal 'archived', tes.status
      refute tes.can_status_archive?

      assert_equal :inactive, tes.comments_close_transition
      assert tes.can_comments_close?
      tes.comments_close!
      assert_equal 'inactive', tes.comments_status
      refute tes.can_comments_close?
    end

    def test_enum_definition_with_suffix
      ActiveRecord::Migration.create_table(:enum_suffix_test) do |t|
        t.integer :status
        t.integer :comments_status
      end
      tes = Class.new(ActiveRecord::Base) do
        self.table_name = 'enum_suffix_test'
        enum(status: [:active, :archived], _suffix: true) { event(:archive) { transition(active: :archived) } }
        enum(comments_status: [:active, :inactive], _suffix: :comments) { event(:close) { transition(active: :inactive) } }
      end.new status: :active, comments_status: :active

      assert_equal :archived, tes.archive_status_transition
      assert tes.can_archive_status?
      tes.archive_status
      assert_equal 'archived', tes.status
      refute tes.can_archive_status?

      assert_equal :inactive, tes.close_comments_transition
      assert tes.can_close_comments?
      tes.close_comments!
      assert_equal 'inactive', tes.comments_status
      refute tes.can_close_comments?
    end

    def test_enum_definition_with_prefix_and_suffix
      ActiveRecord::Migration.create_table(:enum_prefix_and_suffix_test) { |t| t.integer :status }
      tes = Class.new(ActiveRecord::Base) do
        self.table_name = 'enum_prefix_and_suffix_test'
        enum(status: [:active, :archived], _prefix: :prefix, _suffix: :suffix) { event(:archive) { transition(active: :archived) } }
      end.new status: :active
      tes.prefix_archive_suffix
      assert_equal 'archived', tes.status
    end
  end
end
