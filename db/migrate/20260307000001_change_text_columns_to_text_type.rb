class ChangeTextColumnsToTextType < ActiveRecord::Migration[7.0]
  def change
    change_column :contents, :transcribed_text, :text
    change_column :contents, :summarized_text, :text
  end
end
