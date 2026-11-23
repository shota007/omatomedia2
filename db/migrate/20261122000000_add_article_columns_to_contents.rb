class AddArticleColumnsToContents < ActiveRecord::Migration[7.0]
  def change
    add_column :contents, :article_body, :text
    add_column :contents, :source_channel, :string
  end
end
