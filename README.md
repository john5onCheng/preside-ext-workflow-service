Preside workflow service enhancement extension
========================================

This extension allow you to capture failed workflow transaction. Mark the workflow record to locked status and raise notification for developer to recommit this transaction.

## Example of how to change your existng code
```
var result = workflowService.finalizeBooking( eventId=eventId );
```

replace to 
```
var result = workflowService.runTransaction(
					  args                  = { eventId=eventId }
					, eventName             = "page-types.event_booking_page._finalizeBooking"
					, workflowID            = bookingProgress.id
					, customiseErrorMessage = "Unable to book this event. Please contact web administrator. Transaction ID: #bookingProgress.id#"
				);
```				
       
Create new method in handle name _finalizeBooking. example
```
private function _finalizeBooking( event, rc, prc, args={} ) {
	return eventBookingService.finalizeBooking( argumentCollection=arguments.args ?: {} );
}
```
