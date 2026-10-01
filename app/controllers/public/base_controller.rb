class Public::BaseController < ApplicationController
  allow_unauthenticated_access

  before_action :set_board, :set_card, :set_public_cache_expiration
  before_action :ensure_board_accessible

  layout "public"

  # Public boards are embedded on the personal site; allow only that origin
  # to frame them. Authenticated pages keep the default same-origin policy.
  content_security_policy do |policy|
    policy.frame_ancestors :self, "https://vmattoo.dev"
  end

  after_action { response.headers.delete("X-Frame-Options") }

  private
    def set_board
      @board = Board.find_by_published_key(params[:board_id] || params[:id])
    end

    def set_card
      @card = @board.cards.published.find_by!(number: params[:id]) if params[:board_id] && params[:id]
    end

    def set_public_cache_expiration
      expires_in 30.seconds, public: true
    end

    def ensure_board_accessible
      raise ActionController::RoutingError, "Not Found" if @board&.account&.cancelled?
    end
end
