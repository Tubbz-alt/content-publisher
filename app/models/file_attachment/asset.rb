# A FileAttachment::Asset is used to interface with Asset Manager to represent a
# file uploaded as part of a FileAttachment::Revision. It is used to track the
# state of the media on Asset Manager and its URL.
#
# This is a mutable model that is mutated when state changes on Asset Manager
class FileAttachment::Asset < ApplicationRecord
  belongs_to :blob_revision,
             class_name: "FileAttachment::BlobRevision"

  belongs_to :superseded_by,
             class_name: "FileAttachment::Asset",
             optional: true

  enum state: { absent: "absent",
                draft: "draft",
                live: "live",
                superseded: "superseded" }

  delegate :filename, :content_type, to: :blob_revision

  def asset_manager_id
    url_array = file_url.to_s.split("/")
    # https://github.com/alphagov/asset-manager#create-an-asset
    url_array[url_array.length - 2]
  end

  def bytes
    blob_revision.bytes_for_asset
  end
end
