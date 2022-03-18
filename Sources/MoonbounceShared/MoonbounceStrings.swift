//
//  MoonbounceStrings.swift
//  Moonbounce
//
//  Created by Adelita Schule on 1/8/19.
//  Copyright © 2019 operatorfoundation.org. All rights reserved.
//

import Foundation

//MARK: Alerts
public let alertTunnelNameEmptyTitle = "Tunnel Name Missing"
public let alertTunnelNameEmptyMessage = "Please enter a name for this tunnel."

public let alertTunnelAlreadyExistsWithThatNameTitle = "Tunnel Name Unavailable"
public let alertTunnelAlreadyExistsWithThatNameMessage = "There is already a tunnel with this name. Please choose a different name."

public let alertSystemErrorOnListingTunnelsTitle = "Unable to List Tunnels"
public let alertErrorOnListingTunnelsMessage = "Unable to list tunnels, no tunnel information was found."
public let alertSystemErrorOnAddTunnelTitle = "Unable to Add Tunnel"
public let alertSystemErrorOnModifyTunnelTitle = "Unable to Modify Tunnel"
public let alertSystemErrorOnRemoveTunnelTitle = "Unable to Remove Tunnel"

public let alertTunnelActivationErrorTunnelIsNotInactiveTitle = "Tunnel Already Active"
public let alertTunnelActivationErrorTunnelIsNotInactiveMessage = "Unable to activate this tunnel as it is already active."

public let alertTunnelActivationSystemErrorTitle = "Unable to Activate Tunnel: System Error"
public let alertTunnelActivationSystemErrorMessage = "Received an error while attempting to activate a tunnel: (%@)" //systemError.localizedUIString

public let alertTunnelActivationFailureTitle = "Failed to Activate Tunnel"
public let alertTunnelActivationFailureMessage = "Tunnel activation failed."
public let alertTunnelActivationFailureOnDemandAddendum = "On Demand was enabled"
public let alertTunnelActivationSavedConfigFailureMessage = "There is something wrong with the saved configuration."
public let alertTunnelDNSFailureTitle = "Tunnel DNS Failure"
public let alertTunnelDNSFailureMessage = "There was an error resolving the DNS"
public let alertTunnelActivationBackendFailureMessage = "Could not start the back end."
public let alertTunnelActivationFileDescriptorFailureMessage = "There was an issue determining the file descriptor."
public let alertTunnelActivationSetNetworkSettingsMessage = "We were unable to set the network settings."

public let alertSystemErrorMessageTunnelConfigurationInvalid = "The tunnel configuration is invalid."
public let alertSystemErrorMessageTunnelConfigurationDisabled = "The tunnel configuration has been disabled."
public let alertSystemErrorMessageTunnelConnectionFailed = "The tunnel connection failed."
public let alertSystemErrorMessageTunnelConfigurationStale = "The tunnel configuration is stale."
public let alertSystemErrorMessageTunnelConfigurationReadWriteFailed = "Unable to read/write the tunnel configuration."
public let alertSystemErrorMessageTunnelConfigurationUnknown = "The tunnel configuration is unknown."
