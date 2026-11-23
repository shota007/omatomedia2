class ContactMailer < ApplicationMailer
  default to: "contact@merock.co"

  def inquiry(name:, company:, email:, description:)
    @name        = name
    @company     = company
    @email       = email
    @description = description

    mail(
      reply_to: email,
      subject:  "[MeRock] お問い合わせ：#{name}様（#{company.presence || "未入力"}）"
    )
  end
end
