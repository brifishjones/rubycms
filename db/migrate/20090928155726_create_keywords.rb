class CreateKeywords < ActiveRecord::Migration
  def self.up
    create_table :keywords do |t|
      t.column :list,    :text
      t.timestamps
    end
  end

  def self.down
    drop_table :keywords
  end
end