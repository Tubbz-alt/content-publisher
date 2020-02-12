class Tags::UpdateInteractor < ApplicationInteractor
  delegate :params,
           :user,
           :edition,
           :revision,
           :issues,
           to: :context

  def call
    Edition.transaction do
      find_and_lock_edition
      check_for_issues
      update_revision

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
    updater.assign(tags: update_params)
    context.fail! unless updater.changed?
    context.revision = updater.next_revision
  end

  def check_for_issues
    issues = Requirements::TagChecker.new(edition).pre_update_issues(update_params)
    context.fail!(issues: issues) if issues.any?
  end

  def update_edition
    EditDraftEditionService.call(edition, user, revision: revision)
    edition.save!
  end

  def create_timeline_entry
    TimelineEntry.create_for_revision(entry_type: :updated_tags, edition: edition)
  end

  def update_preview
    FailsafeDraftPreviewService.call(edition)
  end

  def update_params
    permits = edition.document_type.tags.map do |tag_field|
      [tag_field.id, []]
    end

    params.fetch(:tags, {}).permit(Hash[permits]).each { |_, v| v.reject!(&:empty?) }
  end
end
