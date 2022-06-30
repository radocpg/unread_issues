class ChangeIndexToUnique < ActiveRecord::Migration
  def up
    IssueRead.where("id in (SELECT t.id FROM (
                                           SELECT u.id
                                           FROM issue_reads u
                                           WHERE EXISTS(SELECT 1 FROM issue_reads t WHERE t.user_id = u.user_id and t.issue_id = u.issue_id group by t.user_id, t.issue_id HAVING count(1) > 1)
                                          ) as t
                            )").delete_all
    remove_index :issue_reads, [:user_id, :issue_id]
    add_index :issue_reads, [:user_id, :issue_id], unique: true
  end
end