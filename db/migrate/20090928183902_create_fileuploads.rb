class CreateFileuploads < ActiveRecord::Migration
  def self.up
    create_table :fileuploads do |t|
      t.column :size, :integer   # file size in bytes
      t.column :content_type, :string   # mime type
      t.column :filename, :string   # sanitized filename
      t.column :pathname, :text   # not associated with attachment_fu
      t.timestamps
    end
  end

  def self.down
    drop_table :fileuploads
  end
end
