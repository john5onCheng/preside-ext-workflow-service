component {

	public void function configure( required struct config ) {
		var settings = arguments.config.settings ?: {};

		settings.notificationTopics.append( "workflowTransactionFailed" );
	}

}
