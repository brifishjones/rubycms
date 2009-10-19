class CreateNavigations < ActiveRecord::Migration
  def self.up
    create_table :navigations do |t|
      t.column :list,             :text
      t.column :href_list,        :text
      t.timestamps
    end
  end

  def self.down
    drop_table :navigations
  end
end
