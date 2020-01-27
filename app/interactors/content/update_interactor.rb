# frozen_string_literal: true

class Content::UpdateInteractor < ApplicationInteractor
  delegate :params,
           :user,
           :edition,
           :revision,
           to: :context

  def call
    Edition.transaction do
      find_and_lock_edition
      update_revision
      check_for_issues

      update_edition
      create_timeline_entry
      update_preview
    end
  end

private

  def find_and_lock_edition
    context.edition = Edition.lock.find_current(document: params[:document])
    assert_edition_state(edition, &:editable?)
  end

  def update_revision
    updater = Versioning::RevisionUpdater.new(edition.revision, user)
    updater.assign(update_params(edition))

    context.fail! unless updater.changed?
    context.revision = updater.next_revision
  end

  def check_for_issues
    issues = Requirements::EditPageChecker.new(edition, revision).pre_preview_issues
    context.fail!(issues: issues) if issues.any?
  end

  def update_edition
    EditDraftEditionService.call(edition, user, revision: revision)
    edition.save!
  end

  def create_timeline_entry
    TimelineEntry.create_for_revision(entry_type: :updated_content, edition: edition)
  end

  def update_preview
    FailsafeDraftPreviewService.call(edition)
  end

  def update_params(edition)
    contents_params = edition.document_type.contents.map(&:id)

    params.require(:revision)
      .permit(:update_type, :change_note, :title, :summary, contents: contents_params)
      .tap do |p|
        p[:title] = p[:title]&.strip
        p[:summary] = p[:summary]&.strip
        p[:base_path] = GenerateBasePathService.call(edition.document, p[:title])
      end
  end
end