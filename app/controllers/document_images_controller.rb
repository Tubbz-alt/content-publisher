# frozen_string_literal: true

class DocumentImagesController < ApplicationController
  rescue_from GdsApi::BaseError do |e|
    Rails.logger.error(e)
    redirect_to document_images_path, alert_with_description: t("document_images.index.flashes.api_error")
  end

  def index
    @document = Document.find_by_param(params[:document_id])
  end

  def create
    document = Document.find_by_param(params[:document_id])

    unless params[:image]
      redirect_to document_images_path, alert: t("document_images.index.no_file_selected")
      return
    end

    image_uploader = ImageUploader.new(params.require(:image))

    unless image_uploader.valid?
      redirect_to document_images_path, alert: {
        "alerts" => image_uploader.errors,
        "title" => t("document_images.index.error_summary_title"),
      }
      return
    end

    image = image_uploader.upload(document)
    image.asset_manager_file_url = upload_image_to_asset_manager(image)

    image.save!
    redirect_to crop_document_image_path(params[:document_id], image.id, wizard: params[:wizard])
  end

  def crop
    @document = Document.find_by_param(params[:document_id])
    @image = @document.images.find(params[:image_id])
  end

  def update_crop
    document = Document.find_by_param(params[:document_id])
    image = Image.find(params[:image_id])

    Image.transaction do
      image.update!(update_crop_params)
      asset_manager_file_url = upload_image_to_asset_manager(image)
      delete_image_from_asset_manager(image)
      image.asset_manager_file_url = asset_manager_file_url
      image.save!
    end

    DocumentUpdateService.update!(
      document: document,
      user: current_user,
      type: "image_updated",
      attributes_to_update: {},
    )

    if params[:wizard].present?
      redirect_to edit_document_image_path(document, image, params.permit(:wizard))
      return
    end

    redirect_to document_images_path(document)
  end

  def edit
    @document = Document.find_by_param(params[:document_id])
    @image = Image.find_by(id: params[:image_id])
  end

  def update
    document = Document.find_by_param(params[:document_id])
    image = document.images.find(params[:image_id])
    image.update!(update_params)

    DocumentUpdateService.update!(
      document: document,
      user: current_user,
      type: "image_updated",
      attributes_to_update: {},
    )

    redirect_to document_images_path(document)
  end

  def destroy
    document = Document.find_by_param(params[:document_id])
    image = document.images.find(params[:image_id])
    raise "Trying to delete image for a live document" if document.has_live_version_on_govuk

    DocumentUpdateService.update!(
      document: document,
      user: current_user,
      type: "image_removed",
      attributes_to_update: {},
    )

    AssetManagerService.new.delete(image)
    image.destroy!
    redirect_to document_images_path(document), notice: t("document_images.index.flashes.image_deleted")
  end

private

  def update_params
    params.permit(:caption, :alt_text, :credit)
  end

  def upload_image_to_asset_manager(image)
    AssetManagerService.new.upload_bytes(image, image.cropped_bytes)
  end

  def delete_image_from_asset_manager(image)
    AssetManagerService.new.delete(image)
  end

  def update_crop_params
    params.permit(:crop_x, :crop_y, :crop_width, :crop_height)
  end
end