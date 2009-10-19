class CreateLocalusers < ActiveRecord::Migration
  def self.up
    create_table :localusers do |t|
      t.column :name,             :string
      t.column :email,            :string
      t.column :password,         :string
      t.timestamps
    end

    # create a default account called admin
    Localuser.create(
      [ {:name  => "admin",
         :password  => "changeme"} ])

  end

  def self.down
    drop_table :localusers
  end
end
