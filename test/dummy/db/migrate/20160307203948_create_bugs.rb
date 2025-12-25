# frozen_string_literal: true

class CreateBugs < (Rails::VERSION::MAJOR >= 5 ? ActiveRecord::Migration[5.0] : ActiveRecord::Migration)
  def change
    create_table :bugs do |t|
      t.string :title
      t.string :description
      t.integer :status, default: 0
      t.integer :assigned_to_id
      t.datetime :resolved_at
      t.string :reopen_reason

      t.timestamps null: false
    end
  end
end
