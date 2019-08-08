# frozen_string_literal: true

class Backdate::DestroyInteractor < ApplicationInteractor
  delegate :params,
           :edition,
           :user,
           to: :context

  def call
    Edition.transaction do
      find_and_lock_edition
      update_edition
      create_timeline_entry
      update_preview
    end
  end

private

  def find_and_lock_edition
    context.edition = Edition.lock.find_current(document: params[:document])
    assert_edition_state(edition, &:editable?)
    assert_edition_state(edition, &:first?)
  end

  def update_edition
    updater = Versioning::RevisionUpdater.new(edition.revision, user)
    updater.assign(backdated_to: nil)
    context.fail! unless updater.changed?

    edition.assign_revision(updater.next_revision, user).save!
  end

  def create_timeline_entry
    TimelineEntry.create_for_revision(
      entry_type: :backdate_cleared,
      revision: edition.revision,
      edition: edition,
      created_by: user,
    )
  end

  def update_preview
    FailsafePreviewService.call(edition)
  end
end
