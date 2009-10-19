class CreateAdministrators < ActiveRecord::Migration
  def self.up
    create_table :administrators do |t|
      t.column :name,             :string
      t.column :regex,            :string   # for future use
      t.timestamps
    end

    # special "admin" user always should be an administrator
    Administrator.create(
      [ {:name  => "admin"} ])

  end

  def self.down
    drop_table :administrators
  end
end
