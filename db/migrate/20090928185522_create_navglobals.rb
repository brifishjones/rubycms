class CreateNavglobals < ActiveRecord::Migration
  def self.up
    create_table :navglobals do |t|
      # primary global navigation used by top level directories
      # .ng classes can be individually styled -- first entry is ng1, second entry is ng2, ... */
      t.column :nameglobal,             :string
      t.column :linkglobal,             :string
      # secondary global navigation
      t.column :namemain,               :string
      t.column :linkmain,               :string
      t.timestamps
    end
  end

  def self.down
    drop_table :navglobals
  end
end
