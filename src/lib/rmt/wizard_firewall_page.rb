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

module RMT; end

class RMT::WizardFirewallPage < Yast::Client
  include ::UI::EventDispatcher

  Yast.import 'CWMFirewallInterfaces'

  def initialize(config)
    textdomain 'rmt'
    @config = config
  end

  def render_content
    Wizard.SetNextButton(:next, Label.NextButton)

    settings = {
      'services' => ['service:http', 'service:https'],
      'display_details' => true,
    }
    firewall_widget = CWMFirewallInterfaces.CreateOpenFirewallWidget(settings)
    firewall_layout = Ops.get_term(firewall_widget, 'custom_widget', VBox())

    contents = HVSquash(firewall_layout)

    Wizard.SetContents(
      _('RMT configuration: Firewall'),
      contents,
      _('INSERT HELPFUL HELP HERE'), # TODO
      true,
      true
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

      render_content

      if Yast::Popup.AnyQuestion(
        'Open firewall ports?',
        "For RMT to work properly, the ports for HTTP (80) and HTTPS (443) need to be opened in the firewall.\nDo you want to open these ports now?",
        'Yes', 'No', :no
      )
        event_loop
      end
      # firewalld.write
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
end
