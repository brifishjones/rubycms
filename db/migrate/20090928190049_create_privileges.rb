class CreatePrivileges < ActiveRecord::Migration
  def self.up
    create_table :privileges do |t|
      t.column :regex, :string   # regular expression for filename
      t.column :group_read_list, :text   # list of group members with read access to regex
      t.column :user_read_list, :text   # list of users with read access to regex
      t.column :group_write_list, :text   # list of group members with write access to regex
      t.column :user_write_list, :text   # list of users with write access to regex
      t.column :group_publish_list, :text   # list of group members with publish access to regex
      t.column :user_publish_list, :text   # list of users with publish access to regex
      t.timestamps
    end
  end

  def self.down
    drop_table :privileges
  end
end
