Preside workflow service enhancement extension
========================================

This extension allow you to capture failed workflow transaction. Mark the workflow record to locked status and raise notification for developer to recommit this transaction.

## Availble parameter for runTransaction method
```
eventName     : name of your private handler 
maxRetry      : number of retry if dead lock error is happen
sleepMiliSec  : amount of time to put this transaction into sleep in milisecond before it perform second attempt. This would reduce the chance to hit dead lock error when more than 1 transaction hit on same time.
args          : arugment to pass in to your private handler 
customiseErrorMessage : customise error message when transaction failed 
workflowId    : Workflow record ID. To capture the workflow data when transaction failed.
```

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
       
Create new private method in handle name _finalizeBooking. example
```
private function _finalizeBooking( event, rc, prc, args={} ) {
	return eventBookingService.finalizeBooking( argumentCollection=arguments.args ?: {} );
}
```

## Locked record

Modify your code to notify user if they have transaction locked, stop them from further changes on your form. You can get the `locked` status from workflow record new field.

## Notification
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
public function commitFinalizeBooking( event, rc, prc, args={} ) {
	if( !event.isAdminUser() ){
		event.notFound();
	}

	return eventBookingService.finalizeBooking( argumentCollection=rc ?: {} );
}
</cfscript>
```

## Modification on preisde workfow service 
1.) Locked record will not get deleted even it has expired when running getState() method
2.) Locked record will not be saved when running saveState() method.
