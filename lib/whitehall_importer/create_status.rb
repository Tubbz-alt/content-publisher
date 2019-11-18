# frozen_string_literal: true

class WhitehallImporter::CreateStatus
  attr_reader :revision, :status, :whitehall_edition, :user_ids

  SUPPORTED_WHITEHALL_STATES = %w(
    draft
    published
    rejected
    submitted
    superseded
    withdrawn
  ).freeze

  def initialize(revision, status, whitehall_edition, user_ids)
    @revision = revision
    @status = status
    @whitehall_edition = whitehall_edition
    @user_ids = user_ids
  end

  def call
    check_supported_state
    event = state_history_event(status)

    Status.new(
      state: state,
      revision_at_creation: revision,
      created_by_id: user_ids[event["whodunnit"]],
      created_at: event["created_at"],
    )
  end

private

  def check_supported_state
    raise WhitehallImporter::AbortImportError, "Edition has an unsupported state" unless valid_state?
  end

  def valid_state?
    SUPPORTED_WHITEHALL_STATES.include?(status)
  end

  def state_history_event(status)
    event = whitehall_edition["revision_history"].select { |h| h["state"] == status }.last

    raise WhitehallImporter::AbortImportError, "Edition is missing a #{state} event" unless event

    event
  end

  def state
    case whitehall_edition["state"]
    when "draft" then "draft"
    when "superseded" then "superseded"
    when "published", "withdrawn"
      whitehall_edition["force_published"] ? "published_but_needs_2i" : "published"
    else
      "submitted_for_review"
    end
  end
end
