#
# Be sure to run `pod lib lint STMSideMenuController.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# Any lines starting with a # are optional, but encouraged
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "Pax"
  s.version          = "1.0"
  s.summary          = "A Swift customizalbe drawer/side menu for iOS"
  s.homepage         = "https://github.com/synesthesia-it/Pax"
  s.license          = 'MIT'
  s.author           = { "Stefano Mondino" => "stefano.mondino.dev@gmail.com" }
  s.source           = { :git => "https://github.com/synesthesia-it/Pax.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/puntoste'

  s.platform     = :ios, '9.0'
  s.requires_arc = true

  s.source_files = 'Pax/Classes/*.swift'

end
