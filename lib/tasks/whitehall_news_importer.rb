# frozen_string_literal: true

module Tasks
  class WhitehallNewsImporter
    SUPPORTED_WHITEHALL_STATES = %w(draft published rejected submitted).freeze

    def import(document)
      edition = most_recent_edition(document)

      edition["translations"].each do |translation|
        next unless SUPPORTED_WHITEHALL_STATES.include?(edition["state"])

        create_or_update_document(translation, edition, document)
      end
    end

  private

    def most_recent_edition(document)
      document["editions"].max_by { |e| e["created_at"] }
    end

    def create_or_update_document(translation, edition, document)
      doc = Document.find_or_initialize_by(content_id: document["content_id"],
                                           locale: translation["locale"])

      doc.assign_attributes(
        base_path: translation["base_path"],
        contents: {
          body: embed_contacts(translation["body"], document.fetch("contacts", {})),
        },
        document_type_id: edition["news_article_type"]["key"],
        title: translation["title"],
        publication_state: publication_state(edition),
        review_state: review_state(edition),
        summary: translation["summary"],
        tags: tags(edition),
        current_edition_number: document["editions"].count,
        has_live_version_on_govuk: has_live_version?(edition, document),
        update_type: edition["minor_change"] ? "minor" : "major",
      )

      doc.save!
    end

    def tags(edition)
      tags = {}
      tags["primary_publishing_organisation"] = primary_publishing_organisation(edition)
      tags["organisations"] = organisations(edition)
      tags["worldwide_organisations"] = edition["worldwide_organisations"]
      tags["topical_events"] = edition["topical_events"]
      tags["world_locations"] = edition["world_locations"]
      tags
    end

    def primary_publishing_organisation(edition)
      [lead_organisations(edition).shift]
    end

    def organisations(edition)
      organisations = edition["supporting_organisations"]
      organisations += lead_organisations(edition) if lead_organisations(edition).any?
      organisations
    end

    def lead_organisations(edition)
      edition["lead_organisations"]
    end

    def publication_state(edition)
      return "sent_to_live" if edition["state"] == "published"

      "sent_to_draft"
    end

    def review_state(edition)
      return "published_without_review" if edition["force_published"]
      return "reviewed" if edition["state"] == "published"
      return "unreviewed" if edition["state"] == "draft"

      "submitted_for_review"
    end

    def has_live_version?(edition, document)
      document["editions"].count > 1 || edition["state"] == "published"
    end

    def embed_contacts(body, contacts)
      body&.gsub(/\[Contact:\s*(\d*)\s*\]/) do
        id = Regexp.last_match[1]
        embed = contacts[id] || id
        "[Contact:#{embed}]"
      end
    end
  end
end
