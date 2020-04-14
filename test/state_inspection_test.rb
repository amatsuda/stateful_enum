# frozen_string_literal: true

require 'test_helper'

class StateInspectionTest < ActiveSupport::TestCase
  def test_possible_events
    unassigned_bug = Bug.new assigned_to: User.create!(name: 'matz')
    unassigned_bug.send(:write_attribute, :status, Bug.statuses[:assigned])
    assert_equal %i[resolve close], unassigned_bug.stateful_enum.possible_events.map(&:value_method_name)
  end

  def test_possible_event_names
    unassigned_bug = Bug.new assigned_to: User.create!(name: 'matz')
    unassigned_bug.send(:write_attribute, :status, Bug.statuses[:assigned])
    assert_equal %i[resolve close], unassigned_bug.stateful_enum.possible_event_names
  end

  def test_possible_states
    unassigned_bug = Bug.new assigned_to: User.create!(name: 'matz')
    unassigned_bug.send(:write_attribute, :status, Bug.statuses[:assigned])
    assert_equal %i[resolved closed], unassigned_bug.stateful_enum.possible_states
  end

  def test_possible_events_on_models_that_have_multiple_enums
    user = User.new account_status: :active, player_status: :normal
    assert_equal %i[withdraw die], user.stateful_enum.possible_events.map(&:value_method_name)
  end

  def test_possible_event_names_on_models_that_have_multiple_enums
    user = User.new account_status: :active, player_status: :normal
    assert_equal %i[withdraw die], user.stateful_enum.possible_event_names
  end

  def test_possible_states_on_models_that_have_multiple_enums
    user = User.new account_status: :active, player_status: :normal
    assert_equal %i[withdrawn dead], user.stateful_enum.possible_states
  end
end
