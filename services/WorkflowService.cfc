/**
 * @singleton
 * @presideService
 */
component extends="preside.system.services.workflow.WorkflowService"{

	/**
	 * @stateDao.inject      presidecms:object:workflow_state
	 * @cookieService.inject cookieService
	 */
	public any function init(  required any stateDao, required any cookieService ){
		super.init( argumentCollection=arguments );
	}

	public function runTransaction(
		  required string  eventName
		,          numeric maxRetry              = 5
		,          numeric sleepMiliSec          = 4000
		,          struct  args                  = {}
		,          string  customiseErrorMessage = ""
		,          string  workflowId            = ""
	) {

		var retryCounter = 0;

		try {
			transaction {
				return $getColdbox().runEvent(
					  event          =  arguments.eventName
					, private        = true
					, prePostExempt  = true
					, eventArguments = { args=arguments.args }
				);
			}
		} catch( e ) {
			var errorMessage    = !isEmpty( e.detail ) ? e.detail : ( e.message ?: "" );
			var errorType       = e.type   ?: "";
			var isDeadLockError = errorType == "database" && errorMessage contains "Deadlock found";

			retryCounter++;
			if( retryCounter <= arguments.maxRetry && isDeadLockError ){
				sleep( arguments.sleepMiliSec );
				retry
			} else {
				$raiseError(e);
				var statusMessage = !isEmpty( arguments.customiseErrorMessage ?: "" ) ? replace( arguments.customiseErrorMessage, "${errorMessage}", errorMessage, "all" ) : "Transaction error. Message: #errorMessage#";
				if( !isEmpty( arguments.workflowId ?: "" ) && _getStateDao().dataExists( id=arguments.workflowId ) ){
					_getStateDao().updateData(
						  id   = arguments.workflowId
						, data = {
							  locked        = true
							, locked_reason = errorMessage
						}
					);

					var workflowDetail = _getStateDao().selectData(
						  id  = arguments.workflowId
					);

					$createNotification(
						  topic = "workflowTransactionFailed"
						, type  = "info"
						, data  = queryRowData( workflowDetail, 1 )
					);
				}

				return {
					  status        = "Error"
					, statusMessage = statusMessage
				}
			}
		}
	}

	public struct function getState(
		  string workflow         = ""
		, string reference        = ""
		, string owner            = _getCookieBasedOwner()
		, string id               = _getRecordIdByWorkflowNameReferenceAndOwner( arguments.workflow, arguments.reference, arguments.owner )
		, boolean useCache        = false
	) {
		if ( Len( Trim( arguments.id  ) ) ) {

			var record = _getStateDao().selectData(
				  id       = arguments.id
				, useCache = arguments.useCache
			);

			if ( _hasStateExpired( record.expires ) && !( _getBoolean( record.locked ?: "" ) ) ) {
				complete( id=record.id );
				return {};
			}

			for( var r in record ){
				r.state = IsJson( r.state ) ? DeserializeJson( r.state ) : {};
				return r;
			}
		}

		return {};
	}

	public string function appendToState(
		  required struct state
		, required string status
		,          string workflow   = ""
		,          string reference  = ""
		,          string owner      = _getCookieBasedOwner()
		,          string id         = _getRecordIdByWorkflowNameReferenceAndOwner( arguments.workflow, arguments.reference, arguments.owner )
		,          date   expires

	) {
		var existingWf = getState( argumentCollection=arguments, useCache=false );
		var newState   = existingWf.state ?: {};

		newState.append( arguments.state );

		return saveState( argumentCollection=arguments, state=newState, isLocked=_getBoolean( existingWf.locked ?: "" ) );
	}

	public string function saveState(
		  required struct  state
		, required string  status
		,          string  workflow   = ""
		,          string  reference  = ""
		,          string  owner      = _getCookieBasedOwner()
		,          string  id         = _getRecordIdByWorkflowNameReferenceAndOwner( arguments.workflow, arguments.reference, arguments.owner )
		,          date    expires
		,          string  isLocked   = ""

	) {

		var serializedState = SerializeJson( arguments.state );

		if ( Len( Trim( arguments.id ) ) ) {

			if( !isEmpty( arguments.isLocked ?: "" ) ){
				arguments.isLocked = _getStateDao().selectData(
					  id           = arguments.id
					, selectFields = ["locked"]
				).locked;
			}

			if( !( _getBoolean( arguments.isLocked ?: "" ) ) ){
				_getStateDao().updateData(
					  id   = arguments.id
					, data = { state=serializedState, status=arguments.status, expires=arguments.expires ?: "" }
				);
			}

			return arguments.id;
		}


		return _getStateDao().insertData({
			  state     = serializedState
			, status    = arguments.status
			, workflow  = arguments.workflow
			, reference = arguments.reference
			, owner     = arguments.owner
			, expires   = arguments.expires ?: ""
		});
	}

	private boolean function _getBoolean( required booleanField ) {
		return isBoolean( arguments.booleanField ?: "" ) &&  arguments.booleanField;
	}


}