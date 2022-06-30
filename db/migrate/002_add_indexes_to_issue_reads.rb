class AddIndexesToIssueReads < ActiveRecord::Migration
  def change
    add_index :issue_reads, [:user_id], unique: false
    add_index :issue_reads, [:issue_id], unique: false
    add_index :issue_reads, [:user_id, :issue_id], unique: false
  end
end