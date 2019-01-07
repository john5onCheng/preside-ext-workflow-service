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

##Locked record
Modify your code to notify user if they have transaction locked, stop them from further changes on your form. You can get the `locked` status from workflow record new field.

##Notification
Override the nofification by adding conditional statement to create re-commit link. You can determine the workflow type from the captured data.

e.g.
```
<cfscript>
	switch( workflow ){
		case "event_booking":
			writeOutput('<a href="#event.buildlink( linkTo='page-types.event_booking_page.recommitEventBooking', queryString='workflowID=#id#')#"></a>')
		break;

		case "product_purchase":
			writeOutput('<a href="#event.buildlink( linkTo='page-types.event_booking_page.recommitProductPurchase', queryString='workflowID=#id#')#"></a>')
		break;
		...
	}
	
</cfscript>
```

Make sure you only allow admin to run the re-commit handler method. You can add more condition checking if you want to have higher secure.

```
<cfscript>
if( !event.isAdminUser() ){
	event.notFound();
}
</cfscript>
```
