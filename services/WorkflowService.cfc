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
				if( !isEmpty( arguments.workflowId ?: "" ) ){
					_getStateDao().updateData(
						  id   = arguments.workflowId
						, data = {
							  locked        = true
							, locked_reason = statusMessage
						}
					);
					$createNotification(
						  topic = "workflowTransactionFailed"
						, type  = "info"
						, data  = { workflowId=workflowId }
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

			if ( _hasStateExpired( record.expires ) && !( isBoolean( record.locked ?: "" ) && record.locked ) ) {
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

	public string function saveState(
		  required struct state
		, required string status
		,          string workflow   = ""
		,          string reference  = ""
		,          string owner      = _getCookieBasedOwner()
		,          string id         = _getRecordIdByWorkflowNameReferenceAndOwner( arguments.workflow, arguments.reference, arguments.owner )
		,          date   expires

	) {
		var isStateLocked   = isBoolean( arguments.state.locked ?: "" ) && arguments.state.locked;
		var serializedState = SerializeJson( arguments.state );

		if ( Len( Trim( arguments.id ) ) && !isStateLocked) {
			_getStateDao().updateData(
				  id   = arguments.id
				, data = { state=serializedState, status=arguments.status, expires=arguments.expires ?: "" }
			);

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

}