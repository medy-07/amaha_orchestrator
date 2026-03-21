# frozen_string_literal: true

class CreateClients < ActiveRecord::Migration[7.1]
  def change
    create_table :clients do |t|
      t.integer :concurrency_limit, default: 5, null: false

      t.timestamps
    end
  end
end
