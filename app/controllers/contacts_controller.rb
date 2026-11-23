class ContactsController < ApplicationController
  skip_before_action :require_login, raise: false

  def create
    name        = params[:name].to_s.strip
    company     = params[:company].to_s.strip
    email       = params[:email].to_s.strip
    description = params[:description].to_s.strip

    if name.blank? || email.blank? || description.blank?
      flash[:alert] = "お名前・メールアドレス・お悩み概要は必須です。"
      redirect_to root_path(anchor: "contact"), status: :see_other
      return
    end

    ContactMailer.inquiry(name: name, company: company, email: email, description: description).deliver_later
    flash[:notice] = "お問い合わせありがとうございます。担当者より折り返しご連絡いたします。"
    redirect_to root_path(anchor: "contact"), status: :see_other
  end
end
