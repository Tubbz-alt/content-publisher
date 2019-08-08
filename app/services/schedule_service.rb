# frozen_string_literal: true

class ScheduleService < ApplicationService
  def initialize(edition, user, scheduling)
    @edition = edition
    @user = user
    @scheduling = scheduling
  end

  def call
    update_edition(scheduling, user)
    create_or_update_publish_intent
    schedule_to_publish(scheduling)
  end

private

  attr_reader :edition, :user, :scheduling

  def update_edition(scheduling, user)
    updater = Versioning::RevisionUpdater.new(edition.revision, user)
    updater.assign(proposed_publish_time: nil)

    edition.assign_revision(updater.next_revision, user)
           .assign_status(:scheduled, user, status_details: scheduling)
           .save!
  end

  def create_or_update_publish_intent
    payload = Payload.new(edition).intent_payload
    GdsApi.publishing_api.put_intent(edition.base_path, payload)
  end

  def schedule_to_publish(scheduling)
    ScheduledPublishingJob.set(wait_until: scheduling.publish_time)
                          .perform_later(edition.id)
  end
end
