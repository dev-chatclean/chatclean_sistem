class AddArchivedAtToContacts < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    add_column :contacts, :archived_at, :datetime
    add_index :contacts, :account_id, where: 'archived_at IS NOT NULL', name: 'index_contacts_on_account_id_archived', algorithm: :concurrently
  end
end
