class AddIndexesToJobs < ActiveRecord::Migration[7.1]
  def change
    add_index :jobs, [:client_id, :status]
    add_index :jobs, [:status, :priority]
  end
end
