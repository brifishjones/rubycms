class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table :users do |t|
      t.column :name,             :string
      t.timestamps
    end
    
    # create a default account called admin
    User.create(
      [{:name  => "admin"}])    
    
  end

  def self.down
    drop_table :users
  end
end
