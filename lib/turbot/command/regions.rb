require "turbot/command/base"

# list available regions
#
class Turbot::Command::Regions < Turbot::Command::Base

  # regions
  #
  # List available regions for deployment
  #
  #Example:
  #
  # $ turbot regions
  # === Regions
  # us
  # eu
  def index
    regions = json_decode(turbot.get("/regions"))
    styled_header("Regions")
    styled_array(regions.map { |region| [region["slug"], region["name"]] })
  end
end

