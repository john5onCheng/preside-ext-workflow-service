/**
 * The workflow_state object saves the state and status of a single workflow item
 *
 * @nolabel true
 */

component extends="preside.system.base.SystemPresideObject" displayName="Workflow: State" {

	property name="workflow"      type="string" dbtype="varchar" maxlength=50 required=true uniqueindexes="workflowstate|1";
	property name="reference"     type="string" dbtype="varchar" maxlength=50 required=true uniqueindexes="workflowstate|2";
	property name="owner"         type="string" dbtype="varchar" maxlength=50 required=true uniqueindexes="workflowstate|3";
	property name="state"         type="string" dbtype="text";
	property name="status"        type="string" dbtype="varchar" maxlength=50 required=true;
	property name="expires"       type="date"   dbtype="datetime" required=false;
	property name="locked"        type="string" dbtype="boolean" default=false;
	property name="locked_reason" type="string" dbtype="text";

}