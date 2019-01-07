<cfscript>
	id        = args.id ?: "";
	reference = args.reference ?: "";
	workflow  = args.workflow ?: "";
</cfscript>

<cfoutput>
	<i class="fa fa-fw fa-exclamation-triangle"></i>#id# (#workflow#) transaction failed
</cfoutput>