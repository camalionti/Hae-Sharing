trigger CL_CaseCommentTrigger on CaseComment (before insert) {
    CL_CaseCommentTriggerHandler.beforeInsert(trigger.new);
}