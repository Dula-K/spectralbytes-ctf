SpectralBytes — S04: Heartbeat in the Wire
=============================================

A gateway sensor produced suspicious traffic shortly before isolation.
capture.pcap is everything the response team captured. Somewhere in here
is a periodic beacon and a file transfer that matters.

Task:
  1. Use Protocol Hierarchy / Endpoints / Conversations to cut down the noise.
  2. Find the host and query pattern that repeats at a suspiciously regular
     interval.
  3. Follow the related stream and export the transferred object.
  4. Open it (you'll need the phrase recovered in the previous stage) and
     read the note inside.

Flag format: SB{S04_pcap_XXXXXXXX}
