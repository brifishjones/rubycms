class CreateSubscriptions < ActiveRecord::Migration
  def self.up
    create_table :subscriptions do |t|
      t.column :name,             :string
      t.timestamps
    end
  end

  def self.down
    drop_table :subscriptions
  end
end
