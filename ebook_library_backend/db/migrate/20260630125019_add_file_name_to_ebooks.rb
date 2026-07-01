class AddFileNameToEbooks < ActiveRecord::Migration[8.1]
  def change
    add_column :ebooks, :file_name, :string
    add_index :ebooks, :title
    add_index :ebooks, :author
  end
end