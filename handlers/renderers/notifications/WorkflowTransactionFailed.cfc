component {

	property name="workflowService" inject="workflowService";

	private string function datatable( event, rc, prc, args={} ) {
		args.workflowId     = args.workflowId ?: "";
		args.invoiceDetail = workflowService.getState( id=args.workflowId, getLockedRecord=true );

		return renderView( view="/renderers/notifications/payNow/datatable", args=args );
	}

	private string function full( event, rc, prc, args={} ) {
		args.workflowId     = args.workflowId ?: "";
		args.invoiceDetail = workflowService.getState( id=args.workflowId, getLockedRecord=true );

		return renderView( view="/renderers/notifications/payNow/full", args=args );
	}

}