# frozen_string_literal: true

class DocumentAssociationsController < ApplicationController
  def edit
    @document = Document.find(params[:id])
  end

  def update
    document = Document.find(params[:id])
    document.update(associations: update_params)
    DocumentPublishingService.new.publish_draft(document)
    redirect_to document, notice: "Preview creation successful"
  rescue GdsApi::HTTPErrorResponse, SocketError => e
    Rails.logger.error(e)
    redirect_to document, alert: "Error creating preview"
  end

private

  def update_params
    params.require(:associations).permit(topical_events: [])
  end
end
