// Copyright (c) 2018 Token Browser, Inc
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

import Foundation

/**

Central place for all event tracking and event logging.
Currently using Amplitude for analytics but may be integrating other tracking services in the future.

*/
struct Analytics {
	public enum TrackingString: String {
		case signInTapped = "sign_in_tapped"
	}
	
	/** Track event
	- parameters:
	- event: The event described by the TrackingString
	- properties: A dictionary of custom attributes to associate with this event. Properties will allow you to segment your events in your reports.
	*/
	public static func trackEvent(_ event: TrackingString, properties: [String: Any]? = nil) {
		Amplitude.instance().logEvent(event.rawValue, withEventProperties: properties)
	}
}
