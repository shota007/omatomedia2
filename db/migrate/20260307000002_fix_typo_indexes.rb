class FixTypoIndexes < ActiveRecord::Migration[7.0]
  def up
    # comments: contet_id (タイポ) インデックスを削除し、正しいものを追加
    if index_exists?(:comments, name: "index_comments_on_user_id_and_contet_id")
      remove_index :comments, name: "index_comments_on_user_id_and_contet_id"
    end
    unless index_exists?(:comments, [:user_id, :content_id])
      add_index :comments, [:user_id, :content_id], name: "index_comments_on_user_id_and_content_id"
    end

    # favorites: contet_id (タイポ) インデックスを削除
    if index_exists?(:favorites, name: "index_favorites_on_user_id_and_contet_id")
      remove_index :favorites, name: "index_favorites_on_user_id_and_contet_id"
    end
  end

  def down
    remove_index :comments, name: "index_comments_on_user_id_and_content_id" if index_exists?(:comments, name: "index_comments_on_user_id_and_content_id")
  end
end
