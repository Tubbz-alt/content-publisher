class DocumentTypeSelection::Option
  include InitializeWithHash

  attr_reader :id, :type, :hostname, :path, :pre_release

  def document_type_selection?
    type == "document_type_selection"
  end

  def document_type?
    type == "document_type"
  end

  def managed_elsewhere?
    type == "managed_elsewhere"
  end

  def managed_elsewhere_url
    hostname ? Plek.new.external_url_for(hostname) + path : path
  end

  alias_method :pre_release?, :pre_release
end
