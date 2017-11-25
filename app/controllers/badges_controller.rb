class BadgesController < ApplicationController
  SHIELD_PDF = Prawn::Document.new
  SHIELD_PDF.font("Helvetica-Bold")
  SHIELD_PDF.font_size = 10.858
  private_constant :SHIELD_PDF

  def show
    repo = Repo.where(full_name: permitted[:full_name]).first
    raise ActionController::RoutingError.new('Not Found') if repo.blank?

    case permitted[:badge_type]
    when "users"
      count = repo.users.count
      svg = make_shield(name: "code helpers", count: count, color_b: repo.color)
    else
      raise ActionController::RoutingError.new('Not Found')
    end

    # Doesn't matter because rails sets an etag :(
    # https://stackoverflow.com/questions/18557251/why-does-browser-still-sends-request-for-cache-control-public-with-max-age
    expires_in 1.hour, :public => true

    respond_to do |format|
      format.svg { render plain: svg }
    end
  end

  private

  def escapeXml(var)
    var
  end

  def make_shield(name:, count:, color_a: "555", color_b: "4c1", logo_width: 0, logo_padding: 0)
    name_width  = (SHIELD_PDF.width_of(name.to_s) + 10).to_f
    count_width = (SHIELD_PDF.width_of(count.to_s) + 10).to_f
    total_width = name_width + count_width
    svg = <<~EOS
      <svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="#{total_width}" height="20">
        <linearGradient id="smooth" x2="0" y2="100%">
          <stop offset="0" stop-color="#bbb" stop-opacity=".1"/>
          <stop offset="1" stop-opacity=".1"/>
        </linearGradient>

        <clipPath id="round">
          <rect width="#{total_width}" height="20" rx="3" fill="#fff"/>
        </clipPath>

        <g clip-path="url(#round)">
          <rect width="#{name_width}" height="20" fill="##{escapeXml(color_a)}"/>
          <rect x="#{name_width}" width="#{count_width}" height="20" fill="##{escapeXml(color_b)}"/>
          <rect width="#{total_width}" height="20" fill="url(#smooth)"/>
        </g>

        <g fill="#fff" text-anchor="middle" font-family="DejaVu Sans,Verdana,Geneva,sans-serif" font-size="110">
          <text x="#{(((name_width + logo_width + logo_padding) / 2) + 1) * 10}" y2="150" fill="#010101" fill-opacity=".3" transform="scale(0.1)" textLength="#{(name_width - (10 + logo_width + logo_padding)) * 10}" lengthAdjust="spacing">#{escapeXml(name)}</text>
          <text x="#{(((name_width + logo_width + logo_padding) / 2) + 1) * 10}" y="140" transform="scale(0.1)" textLength="#{(name_width - (10 + logo_width + logo_padding)) * 10}" lengthAdjust="spacing">#{escapeXml(name)}</text>
          <text x="#{(name_width + count_width / 2 - 1) * 10}" y="150" fill="#010101" fill-opacity=".3" transform="scale(0.1)" textLength="#{(count_width - 10) * 10}" lengthAdjust="spacing">#{escapeXml(count)}</text>
          <text x="#{(name_width + count_width / 2 - 1) * 10}" y="140" transform="scale(0.1)" textLength="#{(count_width - 10) * 10}" lengthAdjust="spacing">#{escapeXml(count)}</text>
        </g>
      </svg>
    EOS
    return svg
  end

  def permitted
    params.permit(:full_name, :badge_type)
  end

  def render_503
    head :service_unavailable
  end
end
