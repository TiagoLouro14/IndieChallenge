class ApplicationController < ActionController::API
  include Pagy::Backend

  rescue_from StandardError, with: :handle_error

  private

  def handle_error(err)
    Rails.logger.error err.message
    render json: { error: 'Internal server error' }, status: :internal_server_error
  end

  def pagy_metadata(pagy)
    {
      current_page: pagy.page,
      total_pages: pagy.pages,
      total_count: pagy.count,
      per_page: pagy.limit
    }
  end
end
