class CreateContacts < ActiveRecord::Migration
  def self.up
    create_table :contacts do |t|
      t.column :list,             :text
      t.column :hide,             :boolean, :default => 0
      t.timestamps
    end
  end

  def self.down
    drop_table :contacts
  end
end
