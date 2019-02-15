# frozen_string_literal: true

class GovspeakDocument::InAppOptions < GovspeakDocument::Options
  include Rails.application.routes.url_helpers

  def to_h
    super.merge(images: in_app_images)
  end

private

  def in_app_images
    edition.revision.image_revisions.map { |image_revision| image_attributes(image_revision) }
  end

  def image_attributes(image_revision)
    # This is the same as url_for(image_revision.crop_variant) in the view, or the
    # image_revision.crop_variant.service_url recommended by the docs. Unfortunately,
    # neither of these work outside a request context, which normally includes the request host.
    url = rails_representation_path(image_revision.crop_variant, only_path: true)

    {
      url: url,
      alt_text: image_revision.alt_text,
      caption: image_revision.caption,
      credit: image_revision.credit,
      id: image_revision.filename,
    }
  end
end