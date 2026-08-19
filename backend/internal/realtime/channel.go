package realtime

import "strings"

// Channel kinds.
const (
	ChannelOrder  = "order"
ChannelRider  = "rider"
	ChannelVendor = "vendor"
	// ChannelRiderBroadcast is the unscoped channel for ready_for_pickup
	// notifications fanned to all online riders.
	ChannelRiderBroadcast = "riders.available"
	// ChannelAdmin is the unscoped channel receiving every order lifecycle
	// event for the admin console.
	ChannelAdmin = "admin"
)

// ParseChannel splits "order:ORD-123" into (ChannelOrder, "ORD-123").
// Returns ok=false for malformed or unscoped channel names.
func ParseChannel(channel string) (kind string, id string, ok bool) {
	kind, id, found := strings.Cut(channel, ":")
	if !found || id == "" {
		return "", "", false
	}
	return kind, id, true
}
