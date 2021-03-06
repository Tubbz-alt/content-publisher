# A File Attachment revision represents an edit of a particular file attachment
#
# This is an immutable model
class FileAttachment::Revision < ApplicationRecord
  belongs_to :created_by, class_name: "User", optional: true
  belongs_to :file_attachment, class_name: "FileAttachment"
  belongs_to :metadata_revision, class_name: "FileAttachment::MetadataRevision"
  belongs_to :blob_revision, class_name: "FileAttachment::BlobRevision"

  has_and_belongs_to_many :revisions,
                          class_name: "::Revision",
                          foreign_key: "file_attachment_revision_id",
                          join_table: "revisions_file_attachment_revisions"

  delegate :title,
           :isbn,
           :unique_reference,
           :paper_number,
           :unofficial?,
           :command_paper?,
           :act_paper?,
           :official_document_type,
           :parliamentary_session,
           to: :metadata_revision

  delegate :filename,
           :asset,
           :asset_url,
           :content_type,
           :byte_size,
           :blob,
           :number_of_pages,
           to: :blob_revision

  def readonly?
    !new_record?
  end

  def featured_attachment_id
    "FileAttachment#{file_attachment.id}"
  end
end
