# frozen_string_literal: true

module WhitehallImporter
  class MigrateAssets
    attr_reader :whitehall_import

    def self.call(*args)
      new(*args).call
    end

    def initialize(whitehall_import)
      @whitehall_import = whitehall_import
    end

    def call
      whitehall_import.assets.each do |whitehall_asset|
        if whitehall_asset.content_publisher_asset.present?
          GdsApi.asset_manager.update_asset(
            whitehall_asset.whitehall_asset_id,
            redirect_url: whitehall_asset.content_publisher_asset.file_url,
          )
          whitehall_asset.update!(state: "redirected")
        end
      end
    end
  end
end
