# frozen_string_literal: true

class CreateJobs < ActiveRecord::Migration[7.1]
  def change
    create_table :jobs do |t|
      t.references :client, null: false, foreign_key: true
      t.string :priority, null: false
      t.string :workload
      t.string :status, default: :queued, null: false
      t.datetime :last_heartbeat_at
      t.integer :retry_count, default: 0, null: false

      t.timestamps
    end
  end
end
