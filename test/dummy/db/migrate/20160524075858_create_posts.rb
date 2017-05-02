# frozen_string_literal: true

class CreatePosts < (Rails::VERSION::STRING >= '5' ? ActiveRecord::Migration[5.0] : ActiveRecord::Migration)
  def change
    create_table :posts do |t|
      t.string :title
      t.text :body
      t.string :type
      t.integer :status, default: 0

      t.timestamps null: false
    end
  end
end
