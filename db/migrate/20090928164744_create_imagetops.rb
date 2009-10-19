class CreateImagetops < ActiveRecord::Migration
  def self.up
    create_table :imagetops do |t|
      t.column :size, :integer   # file size in bytes
      t.column :content_type, :string   # mime type (:image in this case)
      t.column :filename, :string   # sanitized filename
      t.column :width, :integer   # in pixels
      t.column :height, :integer   # in pixels
      t.column :parent_id, :integer   # id of parent image (on the same table, a self-referencing foreign-key).
                                      # Only populated if the current object is a thumbnail.
      t.column :thumbnail, :string   # the 'type' of thumbnail this attachment record describes.
                                     # Only populated if the current object is a thumbnail.
                                     # Usage:
                                     # [ In Model 'Avatar' ]
                                     #   has_attachment :content_type => :image,
                                     #                  :storage => :file_system,
                                     #                  :max_size => 500.kilobytes,
                                     #                  :resize_to => '320x200>',
                                     #                  :thumbnails => { :small => '10x10>',
                                     #                                   :thumb => '100x100>' }
      t.column :pathname, :text   # not associated with attachment_fu
      t.column :caption, :text   # not associated with attachment_fu
      t.column :href, :text   # not associated with attachment_fu
      t.timestamps
    end
  end

  def self.down
    drop_table :imagetops
  end
end
