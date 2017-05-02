# frozen_string_literal: true

class Post < ActiveRecord::Base
  enum status: {drafted: 0, published: 1} do
    event :draft do
      transition :published => :drafted
    end

    event :publish do
      transition :drafted => :published
    end
  end
end
