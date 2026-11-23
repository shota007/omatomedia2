class PagesController < ApplicationController
  skip_before_action :require_login, raise: false
  layout "landing"

  def home
  end

  def muraoka_camp
    render layout: "camp"
  end
end
