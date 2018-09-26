# Copyright (c) 2018 SUSE LLC.
#  All Rights Reserved.

#  This program is free software; you can redistribute it and/or
#  modify it under the terms of version 2 or 3 of the GNU General
#  Public License as published by the Free Software Foundation.

#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.   See the
#  GNU General Public License for more details.

#  You should have received a copy of the GNU General Public License
#  along with this program; if not, contact SUSE LLC.

#  To contact SUSE about this file by physical or electronic mail,
#  you may find current contact information at www.suse.com

require 'y2firewall/firewalld'
require 'ui/event_dispatcher'
require 'rmt/utils'
require "cwm/dialog"
require "cwm/custom_widget"

Yast.import 'CWMFirewallInterfaces'

module RMT; end

class RMT::WizardFirewallPage < CWM::Dialog
  include ::UI::EventDispatcher

  def initialize(config)
    textdomain 'rmt'
    @config = config
  end

  def title
    'RMT configuration: Firewall'
  end

  def contents
    HBox(
      HStretch(),
      VBox(
        RemoteFirewall.new
      ),
      HStretch()
    )
  end

  def next_handler
    finish_dialog(:next)
  end

  def abort_handler
    finish_dialog(:abort)
  end

  def back_handler
    finish_dialog(:back)
  end

  def run
    if firewalld.installed?
      firewalld.read

      if Yast::Popup.AnyQuestion(
        'Open firewall ports?',
        "For RMT to work properly, the ports for HTTP (80) and HTTPS (443) need to be opened in the firewall.\nDo you want to open these ports now?",
        'Yes', 'No', :yes
      )
        super
      end
    else
      Yast::Popup.Message(_("Package 'firewalld' not installed. Skipping firewall configuration."))
      return finish_dialog(:next)
    end
  end

  private

  # This is not required but it is more elegant than using the complete call every time
  def firewalld
    Y2Firewall::Firewalld.instance
  end

  # Widget for opening HTTP & HTTPS services in the firewall
  class RemoteFirewall < CWM::CustomWidget
    attr_accessor :cwm_interfaces
    def initialize
      @cwm_interfaces = Yast::CWMFirewallInterfaces.CreateOpenFirewallWidget(
        "services"        => ["http", "https"],
        "display_details" => true
      )
    end

    def init
      Yast::CWMFirewallInterfaces.OpenFirewallInit(@cwm_interfaces, "")
    end

    def contents
      @cwm_interfaces["custom_widget"]
    end

    def help
      @cwm_interfaces["help"] || ""
    end

    def handle(event)
      Yast::CWMFirewallInterfaces.OpenFirewallHandle(@cwm_interfaces, "", event)
    end
  end

end
